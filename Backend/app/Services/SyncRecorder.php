<?php

namespace App\Services;

use App\Models\Outlet;
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
        ?int $aggregateVersion = null,
        ?int $baseVersion = null,
        ?int $sequence = null,
        string $source = 'server',
        ?string $eventId = null,
        ?string $leaseUuid = null,
        array $result = [],
    ): SyncEvent {
        $outletId ??= Outlet::query()->where('business_id', $businessId)->value('id');

        return SyncEvent::create([
            'event_id' => $eventId ?: (string) Str::uuid(),
            'business_id' => $businessId,
            'outlet_id' => $outletId,
            'device_id' => $deviceId,
            'event_type' => $eventType,
            'aggregate_type' => $aggregateType,
            'aggregate_id' => $aggregateId,
            'aggregate_version' => $aggregateVersion,
            'base_version' => $baseVersion,
            'sequence' => $sequence,
            'schema_version' => 1,
            'status' => $status,
            'payload' => $payload,
            'payload_hash' => hash('sha256', json_encode($payload, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE)),
            'source' => $source,
            'lease_uuid' => $leaseUuid,
            'result' => $result ?: null,
            'retryable' => in_array($status, ['blocked_dependency', 'pending'], true),
            'occurred_at' => now(),
            'processed_at' => $status === 'accepted' ? now() : null,
        ]);
    }
}
