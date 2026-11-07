<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\Device;
use App\Models\Shift;
use App\Models\ShiftDevice;
use App\Models\SyncEvent;
use App\Models\User;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

/**
 * Coordinates the shared outlet shift: participant devices, per-device sync
 * checkpoints and the final, server-authoritative closing snapshot.
 *
 * A close request moves the shift to `closing` and increments `close_epoch`.
 * Every participant that was seen during the shift (or that owns a
 * transaction) must acknowledge that epoch after its outbox is drained and
 * its events are no longer unresolved on the server. Only then is the
 * immutable snapshot written.
 */
class ShiftSyncCoordinator
{
    public const UNRESOLVED_STATUSES = [
        'pending',
        'blocked_dependency',
        'conflict',
        'rejected',
        'upgrade_required',
    ];

    public function __construct(
        private readonly ShiftSummaryService $summary,
        private readonly AuditLogger $audit,
        private readonly SyncRecorder $sync,
    ) {}

    public function registerParticipant(
        Shift $shift,
        Device $device,
        ?User $user = null,
        bool $requiresCheckpoint = true,
    ): ShiftDevice {
        $participant = ShiftDevice::query()
            ->where('shift_id', $shift->id)
            ->where('device_id', $device->id)
            ->lockForUpdate()
            ->first();

        if (! $participant) {
            $participant = new ShiftDevice([
                'uuid' => (string) Str::uuid(),
                'shift_id' => $shift->id,
                'business_id' => $shift->business_id,
                'outlet_id' => $shift->outlet_id,
                'device_id' => $device->id,
                'first_seen_at' => now(),
                'last_ack_epoch' => 0,
            ]);
        }

        $participant->user_id = $user?->id ?? $participant->user_id;
        $participant->requires_checkpoint = $participant->requires_checkpoint || $requiresCheckpoint;
        $participant->last_seen_at = now();
        $participant->last_sequence = max(
            (int) ($participant->last_sequence ?? 0),
            (int) $device->last_sequence,
        );
        $participant->save();

        return $participant;
    }

    public function markTransactionParticipant(Shift $shift, Device $device, ?User $user = null): ShiftDevice
    {
        return $this->registerParticipant($shift, $device, $user, true);
    }

    /**
     * Loads the relations and attaches the server-authoritative summary and
     * per-device sync status used by API resources.
     */
    public function decorate(Shift $shift): Shift
    {
        $shift->loadMissing([
            'cashier',
            'device',
            'outlet',
            'closedBy',
            'closedDevice',
            'closingRequestedBy',
            'closingRequestedDevice',
            'closingSnapshot',
            'closingSnapshot.closedBy',
            'closingSnapshot.closedDevice',
            'cashMovements.createdBy',
            'cashMovements.device',
        ]);

        $shift->setAttribute('server_summary', $this->summary->calculate($shift));
        $shift->setAttribute('shift_sync', $this->syncStatus($shift));

        return $shift;
    }

    /**
     * @return Collection<int, ShiftDevice>
     */
    public function participants(Shift $shift): Collection
    {
        $this->registerTransactionDevices($shift);

        return ShiftDevice::query()
            ->where('shift_id', $shift->id)
            ->with(['device', 'user'])
            ->orderBy('first_seen_at')
            ->orderBy('id')
            ->get();
    }

    public function syncStatus(Shift $shift): array
    {
        $participants = $this->participants($shift);
        $epoch = (int) $shift->close_epoch;
        $rows = [];
        $pending = [];

        foreach ($participants as $participant) {
            $unresolved = $this->unresolvedEvents($shift, (int) $participant->device_id);
            $acked = (int) $participant->last_ack_epoch >= $epoch;
            $isPending = $unresolved['count'] > 0
                || ((bool) $participant->requires_checkpoint && ! $acked);

            $row = [
                'device_uuid' => $participant->device?->uuid,
                'device_name' => $participant->device?->name,
                'terminal_code' => $participant->device?->terminal_code,
                'user_name' => $participant->user?->name,
                'requires_checkpoint' => (bool) $participant->requires_checkpoint,
                'acked' => $acked,
                'last_ack_epoch' => (int) $participant->last_ack_epoch,
                'last_sequence' => $participant->last_sequence !== null ? (int) $participant->last_sequence : null,
                'unresolved_events' => $unresolved['count'],
                'unresolved_event_samples' => $unresolved['samples'],
                'last_seen_at' => $participant->last_seen_at?->toIso8601String(),
                'acknowledged_at' => $participant->acknowledged_at?->toIso8601String(),
            ];

            $rows[] = $row;

            if ($isPending) {
                $pending[] = $row;
            }
        }

        return [
            'close_epoch' => $epoch,
            'closing_started_at' => $shift->closing_started_at?->toIso8601String(),
            'is_closing' => $shift->status === Shift::STATUS_CLOSING,
            'participant_count' => count($rows),
            'pending_device_count' => count($pending),
            'can_finalize' => $shift->status === Shift::STATUS_CLOSING && $pending === [],
            'participants' => $rows,
            'pending_devices' => $pending,
        ];
    }

    public function acknowledge(Shift $shift, Device $device, User $actor, array $data): Shift
    {
        return DB::transaction(function () use ($shift, $device, $actor, $data) {
            $shift = Shift::query()->lockForUpdate()->findOrFail($shift->id);

            $this->assertCheckpointable($shift, $device);

            if (isset($data['close_epoch'])
                && (int) $data['close_epoch'] !== (int) $shift->close_epoch) {
                throw ApiException::conflict(
                    'SHIFT_CLOSE_EPOCH_CHANGED',
                    'Permintaan penutupan shift telah berubah. Muat ulang status shift sebelum mengonfirmasi perangkat.',
                    [
                        'client_close_epoch' => (int) $data['close_epoch'],
                        'current_close_epoch' => (int) $shift->close_epoch,
                    ],
                );
            }

            $participant = $this->registerParticipant($shift, $device, $actor, true);

            $pendingOutbox = (int) ($data['pending_outbox_count'] ?? 0);
            if ($pendingOutbox > 0) {
                throw ApiException::blocked(
                    'SHIFT_DEVICE_OUTBOX_NOT_DRAINED',
                    'Perangkat masih memiliki event di outbox. Sinkronkan seluruh event sebelum konfirmasi tutup shift.',
                    ['pending_outbox_count' => $pendingOutbox],
                );
            }

            $unresolved = $this->unresolvedEvents($shift, (int) $device->id);
            if ($unresolved['count'] > 0) {
                throw ApiException::blocked(
                    'SHIFT_DEVICE_SYNC_PENDING',
                    'Perangkat masih memiliki event yang belum diterima server. Selesaikan sinkronisasi terlebih dahulu.',
                    [
                        'device_uuid' => $device->uuid,
                        'unresolved_events' => $unresolved['count'],
                        'events' => $unresolved['samples'],
                    ],
                );
            }

            $participant->forceFill([
                'last_ack_epoch' => (int) $shift->close_epoch,
                'last_sequence' => $data['last_sequence'] ?? $device->last_sequence,
                'checkpoint_outbox_pending' => 0,
                'acknowledged_at' => now(),
                'last_seen_at' => now(),
            ])->save();

            $this->audit->record(
                'shift.checkpoint',
                'shifts',
                'Konfirmasi sinkronisasi perangkat untuk shift '.$shift->uuid,
                $shift,
                [],
                [
                    'device_uuid' => $device->uuid,
                    'close_epoch' => (int) $shift->close_epoch,
                    'last_sequence' => $participant->last_sequence,
                ],
                $actor,
                $shift->business_id,
            );

            return $shift->refresh();
        });
    }

    /**
     * Used by the closing device: it may acknowledge its own checkpoint when
     * it reports no pending outbox and the server sees no unresolved event.
     */
    public function autoAcknowledgeIfClean(
        Shift $shift,
        Device $device,
        User $actor,
        int $pendingOutbox,
        ?int $lastSequence = null,
    ): bool {
        if ($pendingOutbox > 0) {
            return false;
        }

        if ($this->unresolvedEvents($shift, (int) $device->id)['count'] > 0) {
            return false;
        }

        $participant = $this->registerParticipant($shift, $device, $actor, true);
        $participant->forceFill([
            'last_ack_epoch' => (int) $shift->close_epoch,
            'last_sequence' => $lastSequence ?? $device->last_sequence,
            'checkpoint_outbox_pending' => 0,
            'acknowledged_at' => now(),
            'last_seen_at' => now(),
        ])->save();

        return true;
    }

    /**
     * @return array{finalized: bool, sync: array}
     */
    public function finalizeIfReady(Shift $shift): array
    {
        return DB::transaction(function () use ($shift) {
            $shift = Shift::query()->lockForUpdate()->findOrFail($shift->id);

            if ($shift->status === Shift::STATUS_CLOSED_CONFIRMED) {
                return ['finalized' => true, 'sync' => $this->syncStatus($shift)];
            }

            if ($shift->status !== Shift::STATUS_CLOSING) {
                return ['finalized' => false, 'sync' => $this->syncStatus($shift)];
            }

            $sync = $this->syncStatus($shift);
            if (! $sync['can_finalize']) {
                return ['finalized' => false, 'sync' => $sync];
            }

            if ($shift->closingSnapshot()->exists()) {
                return ['finalized' => true, 'sync' => $sync];
            }

            $this->finalize($shift, $sync);

            return ['finalized' => true, 'sync' => $this->syncStatus($shift->refresh())];
        });
    }

    private function finalize(Shift $shift, array $sync): void
    {
        $actualCash = $shift->close_actual_cash;
        if ($actualCash === null) {
            throw ApiException::conflict(
                'SHIFT_CLOSE_ACTUAL_CASH_REQUIRED',
                'Nominal kas aktual wajib diisi untuk menutup shift.',
            );
        }

        $totals = $this->summary->calculate($shift);
        $closedAt = now();
        $variance = (int) $actualCash - $totals['expected_cash'];
        $acknowledged = collect($sync['participants'])->where('acked', true)->count();
        $lastSequence = collect($sync['participants'])->pluck('last_sequence')->filter()->max();

        $snapshot = $shift->closingSnapshot()->create([
            'business_id' => $shift->business_id,
            'outlet_id' => $shift->outlet_id,
            'user_id' => $shift->user_id,
            'device_id' => $shift->device_id,
            'closed_by_user_id' => $shift->closing_requested_by,
            'closed_device_id' => $shift->closing_requested_device_id,
            'opening_cash' => $totals['opening_cash'],
            'cash_tendered' => $totals['cash_tendered'],
            'cash_change' => $totals['cash_change'],
            'cash_in' => $totals['cash_in'],
            'cash_out' => $totals['cash_out'],
            'cash_refund' => $totals['cash_refund'],
            'expected_cash' => $totals['expected_cash'],
            'actual_cash' => (int) $actualCash,
            'variance' => $variance,
            'confirmed_noncash' => $totals['confirmed_noncash'],
            'awaiting_verification_amount' => $totals['awaiting_verification_amount'],
            'local_transaction_count' => $totals['local_transaction_count'],
            'pending_sync_count' => 0,
            'local_event_sequence' => $lastSequence,
            'device_count' => $sync['participant_count'],
            'synced_device_count' => $acknowledged,
            'checkpoint_epoch' => $sync['close_epoch'],
            'closing_notes' => $shift->closing_notes,
            'snapshot' => [
                'shift' => [
                    'uuid' => $shift->uuid,
                    'status' => Shift::STATUS_CLOSED_CONFIRMED,
                    'opening_cash' => (int) $shift->opening_cash,
                    'opened_at' => $shift->opened_at?->toIso8601String(),
                    'opened_by' => $shift->cashier?->only(['uuid', 'name']),
                    'opening_device' => $shift->device?->only(['uuid', 'name', 'terminal_code']),
                    'closed_by' => $shift->closingRequestedBy?->only(['uuid', 'name']),
                    'closed_device' => $shift->closingRequestedDevice?->only(['uuid', 'name', 'terminal_code']),
                    'closed_at' => $closedAt->toIso8601String(),
                    'close_epoch' => $sync['close_epoch'],
                ],
                'totals' => $totals,
                'participants' => $sync['participants'],
                'cash_movements' => $shift->cashMovements()->with('device')->get()->map(fn ($movement) => [
                    'uuid' => $movement->uuid,
                    'type' => $movement->type,
                    'amount' => (int) $movement->amount,
                    'reason' => $movement->reason,
                    'created_by' => $movement->created_by,
                    'device_uuid' => $movement->device?->uuid,
                    'occurred_at' => $movement->occurred_at?->toIso8601String(),
                ])->all(),
                'sale_uuids' => $shift->sales()->pluck('uuid')->all(),
            ],
            'closed_at' => $closedAt,
            'finalized_at' => $closedAt,
        ]);

        $shift->forceFill([
            'status' => Shift::STATUS_CLOSED_CONFIRMED,
            'open_slot' => null,
            'cash_tendered' => $totals['cash_tendered'],
            'cash_change' => $totals['cash_change'],
            'cash_in' => $totals['cash_in'],
            'cash_out' => $totals['cash_out'],
            'cash_refund' => $totals['cash_refund'],
            'expected_cash' => $totals['expected_cash'],
            'actual_cash' => (int) $actualCash,
            'variance' => $variance,
            'confirmed_noncash' => $totals['confirmed_noncash'],
            'awaiting_verification_amount' => $totals['awaiting_verification_amount'],
            'local_transaction_count' => $totals['local_transaction_count'],
            'pending_sync_count' => 0,
            'local_event_sequence' => $lastSequence,
            'closed_at' => $closedAt,
            'closed_by_user_id' => $shift->closing_requested_by,
            'closed_device_id' => $shift->closing_requested_device_id,
        ])->save();

        $this->audit->record(
            'shift.closed',
            'shifts',
            'Menutup shift '.$shift->uuid,
            $shift,
            ['status' => Shift::STATUS_CLOSING],
            [
                'status' => Shift::STATUS_CLOSED_CONFIRMED,
                'expected_cash' => $totals['expected_cash'],
                'actual_cash' => (int) $actualCash,
                'variance' => $variance,
                'close_epoch' => $sync['close_epoch'],
                'device_count' => $sync['participant_count'],
                'synced_device_count' => $acknowledged,
                'closed_by_user_id' => $shift->closing_requested_by,
                'closed_device_id' => $shift->closing_requested_device_id,
            ],
            $shift->closingRequestedBy,
            $shift->business_id,
        );

        $this->sync->record(
            'shift.closed',
            'shift',
            $shift->uuid,
            $snapshot->snapshot + [
                'snapshot_uuid' => $snapshot->uuid,
                'device_count' => $sync['participant_count'],
                'synced_device_count' => $acknowledged,
                'close_epoch' => $sync['close_epoch'],
            ],
            $shift->business_id,
            $shift->outlet_id,
            $shift->closing_requested_device_id ?? $shift->device_id,
            aggregateVersion: 2,
        );
    }

    private function assertCheckpointable(Shift $shift, Device $device): void
    {
        if ((int) $shift->business_id !== (int) $device->business_id
            || (int) $shift->outlet_id !== (int) $device->outlet_id) {
            throw ApiException::notFound('Shift tidak ditemukan.');
        }

        if ($shift->status === Shift::STATUS_OPEN) {
            throw ApiException::conflict(
                'SHIFT_NOT_CLOSING',
                'Shift belum memasuki proses penutupan. Konfirmasi perangkat hanya diperlukan saat shift berstatus closing.',
            );
        }

        if ($shift->status !== Shift::STATUS_CLOSING) {
            throw ApiException::conflict(
                'SHIFT_ALREADY_CLOSED',
                'Shift sudah ditutup. Konfirmasi perangkat tidak lagi diperlukan.',
            );
        }
    }

    /**
     * @return array{count: int, samples: array}
     */
    public function unresolvedEvents(Shift $shift, int $deviceId): array
    {
        $query = SyncEvent::query()
            ->where('device_id', $deviceId)
            ->where('outlet_id', $shift->outlet_id)
            ->whereIn('status', self::UNRESOLVED_STATUSES)
            ->where(function ($inner) use ($shift) {
                $inner->whereNull('occurred_at')
                    ->orWhere('occurred_at', '>=', $shift->opened_at);
            });

        if ($shift->closed_at) {
            $query->where(function ($inner) use ($shift) {
                $inner->whereNull('occurred_at')
                    ->orWhere('occurred_at', '<=', $shift->closed_at);
            });
        }

        $count = (clone $query)->count();

        $samples = $count === 0 ? [] : $query
            ->orderBy('occurred_at')
            ->limit(20)
            ->get(['event_id', 'event_type', 'status', 'error_code', 'occurred_at'])
            ->map(fn (SyncEvent $event) => [
                'event_id' => $event->event_id,
                'event_type' => $event->event_type,
                'status' => $event->status,
                'error_code' => $event->error_code,
                'occurred_at' => $event->occurred_at?->toIso8601String(),
            ])->all();

        return ['count' => $count, 'samples' => $samples];
    }

    public function unresolvedAcrossParticipants(Shift $shift): array
    {
        $deviceIds = $this->participants($shift)->pluck('device_id')->filter()->unique()->all();
        $events = collect();

        foreach ($deviceIds as $deviceId) {
            $events = $events->merge($this->unresolvedEvents($shift, (int) $deviceId)['samples']);
        }

        return [
            'count' => $events->count(),
            'events' => $events->take(50)->values()->all(),
            'device_ids' => $deviceIds,
        ];
    }

    private function registerTransactionDevices(Shift $shift): void
    {
        $known = ShiftDevice::query()
            ->where('shift_id', $shift->id)
            ->pluck('device_id')
            ->map(fn ($id) => (int) $id)
            ->all();

        $deviceIds = collect()
            ->merge(DB::table('orders')->where('shift_id', $shift->id)->whereNotNull('device_id')->pluck('device_id'))
            ->merge(DB::table('sales')->where('shift_id', $shift->id)->whereNotNull('device_id')->pluck('device_id'))
            ->merge(DB::table('shift_cash_movements')->where('shift_id', $shift->id)->whereNotNull('device_id')->pluck('device_id'))
            ->map(fn ($id) => (int) $id)
            ->unique()
            ->diff($known)
            ->values();

        if ($deviceIds->isEmpty()) {
            return;
        }

        Device::query()
            ->whereIn('id', $deviceIds->all())
            ->get()
            ->each(fn (Device $device) => $this->registerParticipant($shift, $device, null, true));
    }
}
