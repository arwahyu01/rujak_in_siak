<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\IdempotencyKey;

class IdempotencyService
{
    public function existing(int $businessId, string $scope, string $key, array $request): ?IdempotencyKey
    {
        $record = IdempotencyKey::query()
            ->where('business_id', $businessId)
            ->where('scope', $scope)
            ->where('key', $key)
            ->first();

        if (! $record) {
            return null;
        }

        if (! hash_equals($record->request_hash, $this->hash($request))) {
            throw ApiException::conflict(
                'IDEMPOTENCY_KEY_REUSED',
                'Idempotency key yang sama dipakai untuk payload berbeda.',
            );
        }

        return $record;
    }

    public function store(
        int $businessId,
        string $scope,
        string $key,
        array $request,
        int $status,
        array $response,
        ?int $userId = null,
        ?int $deviceId = null,
        ?string $resourceType = null,
        ?string $resourceUuid = null,
    ): IdempotencyKey {
        return IdempotencyKey::create([
            'business_id' => $businessId,
            'user_id' => $userId,
            'device_id' => $deviceId,
            'scope' => $scope,
            'key' => $key,
            'request_hash' => $this->hash($request),
            'response_status' => $status,
            'response_payload' => $response,
            'resource_type' => $resourceType,
            'resource_uuid' => $resourceUuid,
            'expires_at' => now()->addDays(7),
        ]);
    }

    public function hash(array $request): string
    {
        return hash('sha256', json_encode($this->normalize($request), JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE));
    }

    private function normalize(mixed $value): mixed
    {
        if (! is_array($value)) {
            return $value;
        }

        if (array_is_list($value)) {
            return array_map(fn ($item) => $this->normalize($item), $value);
        }

        ksort($value);

        return array_map(fn ($item) => $this->normalize($item), $value);
    }
}
