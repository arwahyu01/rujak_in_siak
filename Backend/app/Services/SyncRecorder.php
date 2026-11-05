<?php

namespace App\Services;

use App\Models\SyncEvent;
use Illuminate\Support\Str;

class SyncRecorder
{
    public function record(
        string $eventType,
        string $aggregateType,
        string $aggregateId,
        array $payload,
        int $businessId,
        ?int $outletId = null,
        ?int $deviceId = null,
        string $status = 'accepted',
    ): SyncEvent {
        return SyncEvent::create([
            'event_id' => (string) Str::uuid(),
            'business_id' => $businessId,
            'outlet_id' => $outletId ?? \App\Models\Outlet::query()->where('business_id', $businessId)->value('id'),
            'device_id' => $deviceId,
            'event_type' => $eventType,
            'aggregate_type' => $aggregateType,
            'aggregate_id' => $aggregateId,
            'schema_version' => 1,
            'status' => $status,
            'payload' => $payload,
            'occurred_at' => now(),
            'processed_at' => $status === 'accepted' ? now() : null,
        ]);
    }
}
