<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\Device;
use App\Models\SyncEvent;
use App\Models\SyncLog;
use App\Models\User;
use Illuminate\Database\QueryException;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

class SyncPushService
{
    public const PROTOCOL_VERSION = 1;

    public const SCHEMA_VERSION = 1;

    public const MAX_EVENTS = 50;

    public const MAX_BYTES = 1_048_576;

    public function __construct(
        private readonly SyncEventApplier $applier,
        private readonly OfflineLeaseService $leases,
    ) {}

    public function push(array $batch, User $actor, Device $device): array
    {
        if ((int) ($batch['protocol_version'] ?? 0) !== self::PROTOCOL_VERSION) {
            throw new ApiException(
                'PROTOCOL_UPGRADE_REQUIRED',
                'Versi protokol sinkronisasi tidak didukung. Perbarui aplikasi.',
                426,
                ['supported_protocol_version' => self::PROTOCOL_VERSION],
            );
        }

        if (strtolower((string) ($batch['device_id'] ?? '')) !== $device->uuid) {
            throw new ApiException('DEVICE_MISMATCH', 'Device ID pada payload tidak sesuai dengan header perangkat.', 403);
        }

        $outletUuid = (string) ($batch['outlet_id'] ?? '');
        if ($outletUuid !== '' && strtolower($outletUuid) !== $device->outlet->uuid) {
            throw new ApiException('OUTLET_MISMATCH', 'Outlet pada payload tidak sesuai dengan perangkat.', 403);
        }

        $events = $batch['events'] ?? [];
        if (! is_array($events) || $events === [] || count($events) > self::MAX_EVENTS) {
            throw new ApiException('SYNC_BATCH_INVALID', 'Batch wajib berisi 1 sampai 50 event.', 422);
        }

        if (strlen((string) json_encode($events, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE)) > self::MAX_BYTES) {
            throw new ApiException('SYNC_BATCH_TOO_LARGE', 'Ukuran batch melebihi 1 MB.', 413);
        }

        $lease = null;
        $leaseToken = trim((string) ($batch['lease_token'] ?? ''));
        if ($leaseToken !== '') {
            $lease = $this->leases->verify($leaseToken, $device);
            if ((int) $lease['lease']->user_id !== (int) $actor->id) {
                throw new ApiException('LEASE_USER_MISMATCH', 'Lease bukan milik pengguna terautentikasi.', 401);
            }
        }

        $offlineBatch = (string) ($batch['origin'] ?? '') === 'offline';

        usort($events, fn ($a, $b) => ((int) ($a['sequence'] ?? 0)) <=> ((int) ($b['sequence'] ?? 0)));

        $results = [];
        $maxSequence = (int) $device->last_sequence;

        foreach ($events as $event) {
            $result = $this->processEvent($event, $actor, $device, $lease, $offlineBatch);
            $results[] = $result;
            $maxSequence = max($maxSequence, (int) ($event['sequence'] ?? 0));
        }

        $device->forceFill(['last_sequence' => $maxSequence])->save();

        $this->writeLog($batch, $actor, $device, $results);

        return [
            'batch_id' => (string) ($batch['batch_id'] ?? ''),
            'results' => $results,
            'server_time' => now()->toIso8601String(),
        ];
    }

    private function processEvent(
        array $event,
        User $actor,
        Device $device,
        ?array $lease,
        bool $offlineBatch,
    ): array {
        $eventId = strtolower(trim((string) ($event['event_id'] ?? '')));
        if ($eventId === '') {
            return [
                'event_id' => null,
                'status' => 'rejected',
                'error_code' => 'EVENT_ID_REQUIRED',
                'retryable' => false,
            ];
        }

        $payload = $event['payload'] ?? [];
        $payload = is_array($payload) ? $payload : [];
        $hash = hash('sha256', json_encode($payload, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE));

        $existing = SyncEvent::query()->where('event_id', $eventId)->first();
        if ($existing) {
            if (! hash_equals((string) $existing->payload_hash, $hash)) {
                return $this->result($eventId, 'conflict', null, 'IDEMPOTENCY_KEY_REUSED', false);
            }

            $status = $existing->status;
            if ($status === 'accepted') {
                return $this->result(
                    $eventId,
                    'duplicate',
                    $existing->result['server_record_id'] ?? $existing->aggregate_id,
                    null,
                    false,
                );
            }

            $retryableLease = $status === 'rejected' && $existing->error_code === 'LEASE_REQUIRED';

            if ($status !== 'blocked_dependency' && ! $retryableLease) {
                return $this->result(
                    $eventId,
                    $status,
                    $existing->result['server_record_id'] ?? null,
                    $existing->error_code,
                    (bool) $existing->retryable,
                );
            }
        }

        if ((int) ($event['schema_version'] ?? 1) > self::SCHEMA_VERSION) {
            return $this->persistFailure(
                $event,
                $eventId,
                $hash,
                $actor,
                $device,
                $lease,
                'upgrade_required',
                'SCHEMA_VERSION_UNSUPPORTED',
                'Versi skema event belum didukung. Perbarui aplikasi.',
                false,
                $existing,
            );
        }

        $sequence = (int) ($event['sequence'] ?? 0);
        if ($sequence < 1) {
            return $this->persistFailure(
                $event,
                $eventId,
                $hash,
                $actor,
                $device,
                $lease,
                'rejected',
                'SEQUENCE_INVALID',
                'Sequence event tidak valid.',
                false,
                $existing,
            );
        }

        $sequenceOwner = SyncEvent::query()
            ->where('device_id', $device->id)
            ->where('sequence', $sequence)
            ->where('event_id', '!=', $eventId)
            ->first();

        if ($sequenceOwner) {
            return $this->persistFailure(
                $event,
                $eventId,
                $hash,
                $actor,
                $device,
                $lease,
                'conflict',
                'SEQUENCE_ALREADY_USED',
                'Sequence yang sama sudah dipakai event lain.',
                false,
                $existing,
            );
        }

        $occurredAt = $this->occurredAt($event, $payload);

        $eventOffline = $offlineBatch || (($payload['origin'] ?? null) === 'offline');
        if ($eventOffline && ! $lease) {
            return $this->persistFailure(
                $event,
                $eventId,
                $hash,
                $actor,
                $device,
                null,
                'rejected',
                'LEASE_REQUIRED',
                'Event offline memerlukan offline authorization lease.',
                false,
                $existing,
            );
        }

        if ($lease) {
            try {
                $this->leases->ensureValidAt($lease['lease'], $occurredAt);
            } catch (ApiException $exception) {
                return $this->persistFailure(
                    $event,
                    $eventId,
                    $hash,
                    $actor,
                    $device,
                    $lease,
                    'rejected',
                    $exception->errorCode,
                    $exception->getMessage(),
                    false,
                    $existing,
                );
            }
        }

        try {
            $applied = DB::transaction(function () use ($event, $eventId, $hash, $actor, $device, $lease, $occurredAt, $payload, $sequence, $existing) {
                $outcome = $this->applier->apply($event, $actor, $device, $lease['lease']->uuid ?? null);

                $attributes = [
                    'business_id' => $actor->business_id,
                    'outlet_id' => $device->outlet_id,
                    'device_id' => $device->id,
                    'event_type' => (string) $event['event_type'],
                    'aggregate_type' => (string) ($event['aggregate_type'] ?? 'unknown'),
                    'aggregate_id' => (string) ($event['aggregate_id'] ?? ''),
                    'aggregate_version' => isset($payload['version']) ? (int) $payload['version'] : null,
                    'base_version' => isset($payload['base_version']) ? (int) $payload['base_version'] : null,
                    'sequence' => $sequence,
                    'schema_version' => (int) ($event['schema_version'] ?? 1),
                    'status' => $outcome['status'] === 'duplicate' ? 'duplicate' : 'accepted',
                    'payload' => $payload,
                    'payload_hash' => $hash,
                    'source' => 'device',
                    'lease_uuid' => $lease['lease']->uuid ?? null,
                    'error_code' => null,
                    'result' => $outcome,
                    'retryable' => false,
                    'occurred_at' => $occurredAt,
                    'processed_at' => now(),
                ];

                if ($existing) {
                    $existing->forceFill($attributes)->save();
                } else {
                    SyncEvent::create(['event_id' => $eventId] + $attributes);
                }

                return $outcome;
            });

            return $this->result(
                $eventId,
                $applied['status'],
                $applied['server_record_id'] ?? null,
                null,
                false,
            );
        } catch (ApiException $exception) {
            $status = match (true) {
                $exception->retryable => 'blocked_dependency',
                $exception->status === 409 => 'conflict',
                $exception->status === 403 => 'rejected',
                $exception->status === 404 => 'blocked_dependency',
                default => 'rejected',
            };

            return $this->persistFailure(
                $event,
                $eventId,
                $hash,
                $actor,
                $device,
                $lease,
                $status,
                $exception->errorCode,
                $exception->getMessage(),
                $status === 'blocked_dependency',
                $existing,
            );
        } catch (QueryException $exception) {
            $duplicate = SyncEvent::query()->where('event_id', $eventId)->first();
            if ($duplicate) {
                return $this->result($eventId, 'duplicate', $duplicate->aggregate_id, null, false);
            }

            return $this->result($eventId, 'rejected', null, 'SERVER_PERSISTENCE_ERROR', true);
        }
    }

    private function persistFailure(
        array $event,
        string $eventId,
        string $hash,
        User $actor,
        Device $device,
        ?array $lease,
        string $status,
        string $errorCode,
        string $message,
        bool $retryable,
        ?SyncEvent $existing,
    ): array {
        $payload = is_array($event['payload'] ?? null) ? $event['payload'] : [];
        $sequence = (int) ($event['sequence'] ?? 0) ?: null;

        // The unique (device_id, sequence) index belongs to the event that
        // claimed the sequence first; keep the losing event for reconciliation
        // without violating that invariant.
        if ($errorCode === 'SEQUENCE_ALREADY_USED') {
            $sequence = null;
        }

        $attributes = [
            'business_id' => $actor->business_id,
            'outlet_id' => $device->outlet_id,
            'device_id' => $device->id,
            'event_type' => (string) ($event['event_type'] ?? 'unknown'),
            'aggregate_type' => (string) ($event['aggregate_type'] ?? 'unknown'),
            'aggregate_id' => (string) ($event['aggregate_id'] ?? ''),
            'aggregate_version' => isset($payload['version']) ? (int) $payload['version'] : null,
            'base_version' => isset($payload['base_version']) ? (int) $payload['base_version'] : null,
            'sequence' => $sequence,
            'schema_version' => (int) ($event['schema_version'] ?? 1),
            'status' => $status,
            'payload' => $payload,
            'payload_hash' => $hash,
            'source' => 'device',
            'lease_uuid' => $lease['lease']->uuid ?? null,
            'error_code' => $errorCode,
            'result' => ['status' => $status, 'error_code' => $errorCode, 'message' => $message],
            'retryable' => $retryable,
            'occurred_at' => isset($event['occurred_at']) ? $this->occurredAt($event, $payload) : null,
            'processed_at' => in_array($status, ['rejected', 'conflict', 'upgrade_required'], true) ? now() : null,
        ];

        try {
            if ($existing) {
                $existing->forceFill($attributes)->save();
            } else {
                SyncEvent::create(['event_id' => $eventId] + $attributes);
            }
        } catch (QueryException) {
            // A concurrent retry already stored this event; the caller receives a retryable result.
        }

        return $this->result($eventId, $status, null, $errorCode, $retryable);
    }

    private function writeLog(array $batch, User $actor, Device $device, array $results): void
    {
        $byStatus = collect($results)->countBy('status');

        SyncLog::create([
            'batch_id' => (string) ($batch['batch_id'] ?? ''),
            'business_id' => $actor->business_id,
            'outlet_id' => $device->outlet_id,
            'device_id' => $device->id,
            'user_id' => $actor->id,
            'protocol_version' => (int) ($batch['protocol_version'] ?? 1),
            'event_count' => count($results),
            'accepted_count' => (int) ($byStatus['accepted'] ?? 0),
            'duplicate_count' => (int) ($byStatus['duplicate'] ?? 0),
            'rejected_count' => (int) ($byStatus['rejected'] ?? 0) + (int) ($byStatus['upgrade_required'] ?? 0),
            'conflict_count' => (int) ($byStatus['conflict'] ?? 0),
            'blocked_count' => (int) ($byStatus['blocked_dependency'] ?? 0),
            'result' => $results,
            'ip_address' => request()->ip(),
            'received_at' => now(),
        ]);
    }

    private function occurredAt(array $event, array $payload): Carbon
    {
        $value = $event['occurred_at'] ?? $payload['occurred_at'] ?? null;
        if (! $value) {
            return now();
        }

        try {
            return Carbon::parse($value);
        } catch (\Throwable) {
            throw new ApiException('OCCURRED_AT_INVALID', 'Waktu event tidak valid.', 422);
        }
    }

    private function result(
        string $eventId,
        string $status,
        ?string $recordId,
        ?string $errorCode,
        bool $retryable,
    ): array {
        $result = [
            'event_id' => $eventId,
            'status' => $status,
        ];

        if ($recordId) {
            $result['server_record_id'] = $recordId;
        }
        if ($errorCode) {
            $result['error_code'] = $errorCode;
        }
        if ($errorCode || $retryable) {
            $result['retryable'] = $retryable;
        }

        return $result;
    }
}
