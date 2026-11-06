<?php

namespace App\Actions\Shifts;

use App\Exceptions\ApiException;
use App\Models\Device;
use App\Models\Order;
use App\Models\Shift;
use App\Models\User;
use App\Services\AuditLogger;
use App\Services\ShiftSummaryService;
use App\Services\SyncRecorder;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

class CloseShift
{
    public function __construct(
        private readonly ShiftSummaryService $summary,
        private readonly AuditLogger $audit,
        private readonly SyncRecorder $sync,
    ) {}

    public function handle(Shift $shift, array $data, User $actor, Device $device): Shift
    {
        return DB::transaction(function () use ($shift, $data, $actor, $device) {
            $shift = Shift::query()->lockForUpdate()->findOrFail($shift->id);

            if ((int) $shift->business_id !== (int) $actor->business_id
                || (int) $shift->outlet_id !== (int) $device->outlet_id) {
                throw ApiException::notFound('Shift tidak ditemukan.');
            }

            if ($shift->status !== Shift::STATUS_OPEN) {
                throw ApiException::conflict('SHIFT_NOT_OPEN', 'Shift sudah ditutup dan tidak dapat dibuka kembali.');
            }

            if ((int) $shift->device_id !== (int) $device->id) {
                throw ApiException::forbidden('Shift bukan milik perangkat ini.');
            }

            if (! $actor->hasPermission('shifts.manage')) {
                throw ApiException::forbidden('Anda tidak memiliki hak menutup shift.');
            }

            $heldAhead = Order::query()
                ->where('shift_id', $shift->id)
                ->where('status', Order::STATUS_HELD)
                ->lockForUpdate()
                ->exists();

            if ($heldAhead) {
                throw ApiException::conflict(
                    'SHIFT_HAS_HELD_ORDERS',
                    'Shift masih memiliki held order. Selesaikan, batalkan, atau pindahkan order tersebut sebelum menutup shift.',
                );
            }

            if ($shift->closingSnapshot()->exists()) {
                throw ApiException::conflict('SHIFT_SNAPSHOT_EXISTS', 'Closing snapshot shift sudah dibuat dan tidak dapat diubah.');
            }

            $totals = $this->summary->calculate($shift);
            $actualCash = (int) $data['actual_cash'];
            $variance = $actualCash - $totals['expected_cash'];
            $pendingSyncCount = (int) ($data['pending_sync_count'] ?? 0);
            $closedAt = isset($data['closed_at']) ? Carbon::parse($data['closed_at']) : now();

            if ($closedAt->lt($shift->opened_at)) {
                throw new ApiException('SHIFT_CLOSED_AT_INVALID', 'Waktu tutup shift tidak boleh sebelum waktu buka.', 422);
            }

            $status = $pendingSyncCount > 0
                ? Shift::STATUS_CLOSED_PENDING_SYNC
                : Shift::STATUS_CLOSED_CONFIRMED;

            $snapshot = $shift->closingSnapshot()->create([
                'business_id' => $shift->business_id,
                'outlet_id' => $shift->outlet_id,
                'user_id' => $shift->user_id,
                'device_id' => $shift->device_id,
                'opening_cash' => $totals['opening_cash'],
                'cash_tendered' => $totals['cash_tendered'],
                'cash_change' => $totals['cash_change'],
                'cash_in' => $totals['cash_in'],
                'cash_out' => $totals['cash_out'],
                'cash_refund' => $totals['cash_refund'],
                'expected_cash' => $totals['expected_cash'],
                'actual_cash' => $actualCash,
                'variance' => $variance,
                'confirmed_noncash' => $totals['confirmed_noncash'],
                'awaiting_verification_amount' => $totals['awaiting_verification_amount'],
                'local_transaction_count' => $totals['local_transaction_count'],
                'pending_sync_count' => $pendingSyncCount,
                'local_event_sequence' => $data['local_event_sequence'] ?? null,
                'closing_notes' => $data['closing_notes'] ?? null,
                'snapshot' => [
                    'shift' => [
                        'uuid' => $shift->uuid,
                        'status' => $status,
                        'opening_cash' => (int) $shift->opening_cash,
                        'opened_at' => $shift->opened_at?->toIso8601String(),
                        'closed_at' => $closedAt->toIso8601String(),
                    ],
                    'totals' => $totals,
                    'cash_movements' => $shift->cashMovements()->get()->map(fn ($movement) => [
                        'uuid' => $movement->uuid,
                        'type' => $movement->type,
                        'amount' => (int) $movement->amount,
                        'reason' => $movement->reason,
                        'occurred_at' => $movement->occurred_at?->toIso8601String(),
                    ])->all(),
                    'sale_uuids' => $shift->sales()->pluck('uuid')->all(),
                ],
                'closed_at' => $closedAt,
            ]);

            $shift->forceFill([
                'status' => $status,
                'cash_tendered' => $totals['cash_tendered'],
                'cash_change' => $totals['cash_change'],
                'cash_in' => $totals['cash_in'],
                'cash_out' => $totals['cash_out'],
                'cash_refund' => $totals['cash_refund'],
                'expected_cash' => $totals['expected_cash'],
                'actual_cash' => $actualCash,
                'variance' => $variance,
                'confirmed_noncash' => $totals['confirmed_noncash'],
                'awaiting_verification_amount' => $totals['awaiting_verification_amount'],
                'local_transaction_count' => $totals['local_transaction_count'],
                'pending_sync_count' => $pendingSyncCount,
                'local_event_sequence' => $data['local_event_sequence'] ?? null,
                'closing_notes' => $data['closing_notes'] ?? null,
                'closed_at' => $closedAt,
            ])->save();

            $this->audit->record(
                'shift.closed',
                'shifts',
                'Menutup shift '.$shift->uuid,
                $shift,
                ['status' => Shift::STATUS_OPEN],
                [
                    'status' => $status,
                    'expected_cash' => $totals['expected_cash'],
                    'actual_cash' => $actualCash,
                    'variance' => $variance,
                    'pending_sync_count' => $pendingSyncCount,
                ],
                $actor,
                $shift->business_id,
            );

            $this->sync->record(
                'shift.closed',
                'shift',
                $shift->uuid,
                $snapshot->snapshot + ['snapshot_uuid' => $snapshot->uuid, 'pending_sync_count' => $pendingSyncCount],
                $shift->business_id,
                $shift->outlet_id,
                $shift->device_id,
                aggregateVersion: 2,
            );

            return $shift->refresh()->load(['closingSnapshot', 'cashMovements', 'cashier', 'device', 'outlet']);
        });
    }
}
