<?php

namespace App\Actions\Shifts;

use App\Exceptions\ApiException;
use App\Models\Device;
use App\Models\Shift;
use App\Models\User;
use App\Services\AuditLogger;
use App\Services\SyncRecorder;
use Illuminate\Support\Facades\DB;

class OpenShift
{
    public function __construct(
        private readonly AuditLogger $audit,
        private readonly SyncRecorder $sync,
    ) {}

    public function handle(array $data, User $actor, Device $device): Shift
    {
        return DB::transaction(function () use ($data, $actor, $device) {
            $exists = Shift::query()
                ->where('business_id', $actor->business_id)
                ->where('user_id', $actor->id)
                ->where('status', Shift::STATUS_OPEN)
                ->lockForUpdate()
                ->exists();

            if ($exists) {
                throw ApiException::conflict(
                    'SHIFT_ALREADY_OPEN',
                    'Anda masih memiliki shift yang terbuka. Tutup shift tersebut terlebih dahulu.',
                );
            }

            $openingCash = (int) $data['opening_cash'];

            $shift = Shift::create([
                'business_id' => $actor->business_id,
                'outlet_id' => $device->outlet_id,
                'user_id' => $actor->id,
                'device_id' => $device->id,
                'status' => Shift::STATUS_OPEN,
                'opening_cash' => $openingCash,
                'expected_cash' => $openingCash,
                'opening_notes' => $data['opening_notes'] ?? null,
                'opened_at' => now(),
            ]);

            $this->audit->record(
                'shift.opened',
                'shifts',
                'Membuka shift '.$shift->uuid,
                $shift,
                [],
                ['opening_cash' => $openingCash, 'device_uuid' => $device->uuid],
                $actor,
                $actor->business_id,
            );

            $this->sync->record(
                'shift.opened',
                'shift',
                $shift->uuid,
                $this->payload($shift),
                $actor->business_id,
                $device->outlet_id,
                $device->id,
                aggregateVersion: 1,
            );

            return $shift->refresh();
        });
    }

    private function payload(Shift $shift): array
    {
        return [
            'shift_uuid' => $shift->uuid,
            'status' => $shift->status,
            'opening_cash' => (int) $shift->opening_cash,
            'opened_at' => $shift->opened_at?->toIso8601String(),
            'device_uuid' => $shift->device?->uuid,
            'user_uuid' => $shift->cashier?->uuid,
        ];
    }
}
