<?php

namespace App\Actions\Shifts;

use App\Exceptions\ApiException;
use App\Models\Device;
use App\Models\Outlet;
use App\Models\Shift;
use App\Models\User;
use App\Services\AuditLogger;
use App\Services\ShiftSyncCoordinator;
use App\Services\SyncRecorder;
use Illuminate\Database\QueryException;
use Illuminate\Support\Facades\DB;

class OpenShift
{
    public function __construct(
        private readonly AuditLogger $audit,
        private readonly SyncRecorder $sync,
        private readonly ShiftSyncCoordinator $coordinator,
    ) {}

    public function handle(array $data, User $actor, Device $device): Shift
    {
        try {
            return $this->open($data, $actor, $device);
        } catch (QueryException $exception) {
            if (in_array((string) $exception->getCode(), ['23000', '23505'], true)) {
                throw ApiException::conflict(
                    'SHIFT_ALREADY_OPEN',
                    'Outlet ini baru saja membuka shift lain. Satu outlet hanya boleh memiliki satu shift aktif.',
                );
            }

            throw $exception;
        }
    }

    private function open(array $data, User $actor, Device $device): Shift
    {
        return DB::transaction(function () use ($data, $actor, $device) {
            // Serialise shift creation per outlet. The unique outlet/open_slot
            // index is the final safety net if this lock is not available.
            Outlet::query()->whereKey($device->outlet_id)->lockForUpdate()->first();

            $active = Shift::query()
                ->where('business_id', $actor->business_id)
                ->where('outlet_id', $device->outlet_id)
                ->whereIn('status', [Shift::STATUS_OPEN, Shift::STATUS_CLOSING])
                ->lockForUpdate()
                ->first();

            if ($active) {
                throw ApiException::conflict(
                    'SHIFT_ALREADY_OPEN',
                    'Outlet ini masih memiliki shift aktif. Satu outlet hanya boleh memiliki satu shift aktif.',
                    ['shift_uuid' => $active->uuid, 'status' => $active->status],
                );
            }

            $openingCash = (int) $data['opening_cash'];

            $shift = Shift::create([
                'business_id' => $actor->business_id,
                'outlet_id' => $device->outlet_id,
                'user_id' => $actor->id,
                'device_id' => $device->id,
                'status' => Shift::STATUS_OPEN,
                'open_slot' => 1,
                'close_epoch' => 0,
                'opening_cash' => $openingCash,
                'expected_cash' => $openingCash,
                'opening_notes' => $data['opening_notes'] ?? null,
                'opened_at' => now(),
            ]);

            $this->coordinator->registerParticipant($shift, $device, $actor, true);

            $this->audit->record(
                'shift.opened',
                'shifts',
                'Membuka shift '.$shift->uuid,
                $shift,
                [],
                [
                    'opening_cash' => $openingCash,
                    'outlet_uuid' => $device->outlet?->uuid,
                    'device_uuid' => $device->uuid,
                    'opened_by_user_id' => $actor->id,
                ],
                $actor,
                $actor->business_id,
            );

            $this->sync->record(
                'shift.opened',
                'shift',
                $shift->uuid,
                $this->payload($shift, $actor, $device),
                $actor->business_id,
                $device->outlet_id,
                $device->id,
                aggregateVersion: 1,
            );

            return $shift->refresh()->load(['cashier', 'device', 'outlet']);
        });
    }

    private function payload(Shift $shift, User $actor, Device $device): array
    {
        return [
            'shift_uuid' => $shift->uuid,
            'status' => $shift->status,
            'outlet_uuid' => $device->outlet?->uuid,
            'opening_cash' => (int) $shift->opening_cash,
            'opened_at' => $shift->opened_at?->toIso8601String(),
            'device_uuid' => $device->uuid,
            'device_name' => $device->name,
            'terminal_code' => $device->terminal_code,
            'user_uuid' => $actor->uuid,
            'user_name' => $actor->name,
        ];
    }
}
