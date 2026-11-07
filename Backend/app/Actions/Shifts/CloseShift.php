<?php

namespace App\Actions\Shifts;

use App\Exceptions\ApiException;
use App\Models\Device;
use App\Models\Order;
use App\Models\Shift;
use App\Models\User;
use App\Services\AuditLogger;
use App\Services\ShiftSyncCoordinator;
use App\Services\SyncRecorder;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

class CloseShift
{
    public function __construct(
        private readonly ShiftSyncCoordinator $coordinator,
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

            if (! $actor->hasPermission('shifts.manage')) {
                throw ApiException::forbidden('Anda tidak memiliki hak menutup shift.');
            }

            if (! in_array($shift->status, [Shift::STATUS_OPEN, Shift::STATUS_CLOSING], true)) {
                throw ApiException::conflict('SHIFT_NOT_OPEN', 'Shift sudah ditutup dan tidak dapat dibuka kembali.');
            }

            if ($shift->closingSnapshot()->exists()) {
                throw ApiException::conflict('SHIFT_SNAPSHOT_EXISTS', 'Closing snapshot shift sudah dibuat dan tidak dapat diubah.');
            }

            $openedAt = $shift->opened_at;
            $closedAt = isset($data['closed_at']) ? Carbon::parse($data['closed_at']) : now();
            if ($openedAt && $closedAt->lt($openedAt)) {
                throw new ApiException('SHIFT_CLOSED_AT_INVALID', 'Waktu tutup shift tidak boleh sebelum waktu buka.', 422);
            }

            if ($shift->status === Shift::STATUS_OPEN) {
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

                $shift->forceFill([
                    'status' => Shift::STATUS_CLOSING,
                    'close_epoch' => (int) $shift->close_epoch + 1,
                    'closing_started_at' => now(),
                    'closing_requested_by' => $actor->id,
                    'closing_requested_device_id' => $device->id,
                    'close_actual_cash' => (int) $data['actual_cash'],
                    'closing_notes' => $data['closing_notes'] ?? $shift->closing_notes,
                ])->save();

                $this->audit->record(
                    'shift.close_requested',
                    'shifts',
                    'Meminta penutupan shift '.$shift->uuid,
                    $shift,
                    ['status' => Shift::STATUS_OPEN],
                    [
                        'status' => Shift::STATUS_CLOSING,
                        'close_epoch' => (int) $shift->close_epoch,
                        'actual_cash' => (int) $data['actual_cash'],
                        'requested_by_user_id' => $actor->id,
                        'requested_device_id' => $device->id,
                    ],
                    $actor,
                    $shift->business_id,
                );

                $this->sync->record(
                    'shift.close_requested',
                    'shift',
                    $shift->uuid,
                    [
                        'shift_uuid' => $shift->uuid,
                        'status' => Shift::STATUS_CLOSING,
                        'close_epoch' => (int) $shift->close_epoch,
                        'requested_by_user_uuid' => $actor->uuid,
                        'requested_by_device_uuid' => $device->uuid,
                        'requested_at' => $shift->closing_started_at?->toIso8601String(),
                    ],
                    $shift->business_id,
                    $shift->outlet_id,
                    $device->id,
                    aggregateVersion: 2,
                );
            } else {
                $updates = ['closing_notes' => $data['closing_notes'] ?? $shift->closing_notes];
                if (isset($data['actual_cash'])) {
                    $updates['close_actual_cash'] = (int) $data['actual_cash'];
                }
                $shift->forceFill($updates)->save();
            }

            $this->coordinator->registerParticipant($shift, $device, $actor, true);

            $this->coordinator->autoAcknowledgeIfClean(
                $shift,
                $device,
                $actor,
                (int) ($data['pending_sync_count'] ?? 0),
                isset($data['local_event_sequence']) ? (int) $data['local_event_sequence'] : null,
            );

            $this->coordinator->finalizeIfReady($shift);

            return $shift->refresh()->load([
                'cashier',
                'device',
                'outlet',
                'closedBy',
                'closedDevice',
                'closingRequestedBy',
                'closingRequestedDevice',
                'closingSnapshot',
                'cashMovements.createdBy',
                'participants.device',
                'participants.user',
            ]);
        });
    }
}
