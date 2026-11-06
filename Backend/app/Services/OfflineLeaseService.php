<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\AuthorizationLease;
use App\Models\Device;
use App\Models\User;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class OfflineLeaseService
{
    public const MAX_HOURS = 72;

    public function issue(User $user, Device $device, int $hours = self::MAX_HOURS): array
    {
        if (! $device->isActive()) {
            throw new ApiException('DEVICE_REVOKED', 'Perangkat telah dicabut.', 403);
        }

        if ((int) $device->business_id !== (int) $user->business_id || (int) $device->outlet_id !== (int) $user->outlet_id) {
            throw new ApiException('DEVICE_SCOPE_MISMATCH', 'Perangkat tidak berada pada cakupan pengguna.', 403);
        }

        if (! $user->is_active) {
            throw new ApiException('ACCOUNT_INACTIVE', 'Akun tidak aktif.', 403);
        }

        $hours = max(1, min($hours, self::MAX_HOURS));
        $authVersion = $user->auth_version !== null
            ? (int) $user->auth_version
            : (int) (User::query()->whereKey($user->getKey())->value('auth_version') ?? 0);

        return DB::transaction(function () use ($user, $device, $hours, $authVersion) {
            AuthorizationLease::query()
                ->where('device_id', $device->id)
                ->whereNull('revoked_at')
                ->where('expires_at', '>', now())
                ->update([
                    'revoked_at' => now(),
                    'revoked_reason' => 'superseded',
                ]);

            $issuedAt = now();
            $expiresAt = $issuedAt->copy()->addHours($hours);
            $payload = [
                'lease_id' => (string) Str::uuid(),
                'user_id' => $user->uuid,
                'device_id' => $device->uuid,
                'business_id' => $user->business->uuid,
                'outlet_id' => $device->outlet->uuid,
                'roles' => $user->roleSlugs(),
                'permissions' => $user->permissionSlugs(),
                'issued_at' => $issuedAt->getTimestamp(),
                'expires_at' => $expiresAt->getTimestamp(),
                'auth_version' => $authVersion,
            ];

            $token = $this->sign($payload);

            $lease = AuthorizationLease::create([
                'uuid' => $payload['lease_id'],
                'user_id' => $user->id,
                'device_id' => $device->id,
                'business_id' => $user->business_id,
                'outlet_id' => $device->outlet_id,
                'auth_version' => $authVersion,
                'roles' => $payload['roles'],
                'permissions' => $payload['permissions'],
                'signature_hash' => hash('sha256', $token),
                'issued_at' => $issuedAt,
                'expires_at' => $expiresAt,
            ]);

            return [
                'token' => $token,
                'lease' => [
                    'id' => $lease->uuid,
                    'user_id' => $user->uuid,
                    'device_id' => $device->uuid,
                    'business_id' => $user->business->uuid,
                    'outlet_id' => $device->outlet->uuid,
                    'roles' => $payload['roles'],
                    'permissions' => $payload['permissions'],
                    'issued_at' => $issuedAt->toIso8601String(),
                    'expires_at' => $expiresAt->toIso8601String(),
                    'authentication_version' => (int) $user->auth_version,
                ],
            ];
        });
    }

    /**
     * @return array{lease: AuthorizationLease, payload: array}
     */
    public function verify(string $token, Device $device): array
    {
        $parts = explode('.', $token);
        if (count($parts) !== 2) {
            throw new ApiException('LEASE_INVALID', 'Offline authorization lease tidak valid.', 401);
        }

        [$payloadPart, $signature] = $parts;
        $expected = $this->base64UrlEncode(hash_hmac('sha256', $payloadPart, $this->signingKey(), true));

        if (! hash_equals($expected, $signature)) {
            throw new ApiException('LEASE_INVALID', 'Tanda tangan offline lease tidak valid.', 401);
        }

        $payload = json_decode($this->base64UrlDecode($payloadPart), true);
        if (! is_array($payload) || empty($payload['lease_id'])) {
            throw new ApiException('LEASE_INVALID', 'Isi offline lease tidak valid.', 401);
        }

        $lease = AuthorizationLease::query()
            ->with(['user'])
            ->where('uuid', $payload['lease_id'])
            ->where('device_id', $device->id)
            ->first();

        if (! $lease) {
            throw new ApiException('LEASE_NOT_FOUND', 'Offline lease tidak ditemukan untuk perangkat ini.', 401);
        }

        if (! hash_equals($lease->signature_hash, hash('sha256', $token))) {
            throw new ApiException('LEASE_INVALID', 'Offline lease tidak cocok dengan catatan server.', 401);
        }

        if ($lease->revoked_at !== null) {
            throw new ApiException('LEASE_REVOKED', 'Offline lease telah dicabut.', 401);
        }

        if ((int) $lease->auth_version !== (int) $lease->user->auth_version || ! $lease->user->is_active) {
            throw new ApiException('LEASE_AUTH_VERSION_CHANGED', 'Otorisasi telah berubah. Login ulang diperlukan.', 401);
        }

        return ['lease' => $lease, 'payload' => $payload];
    }

    /**
     * A lease may be expired now but still proves authorization for events that
     * occurred before its expiration. Devices revoked before the occurrence are
     * never authorized.
     */
    public function ensureValidAt(AuthorizationLease $lease, Carbon $occurredAt): void
    {
        if ($lease->revoked_at !== null && $lease->revoked_at->lessThanOrEqualTo($occurredAt)) {
            throw new ApiException('LEASE_REVOKED_AT_EVENT', 'Lease sudah dicabut pada waktu event.', 401);
        }

        if ($lease->issued_at->greaterThan($occurredAt)) {
            throw new ApiException('LEASE_NOT_YET_ISSUED', 'Lease belum diterbitkan pada waktu event.', 401);
        }

        if ($lease->expires_at->lessThan($occurredAt)) {
            throw new ApiException('LEASE_EXPIRED_AT_EVENT', 'Lease telah kedaluwarsa pada waktu event.', 401);
        }
    }

    public function revokeForDevice(Device $device, string $reason = 'device_revoked'): int
    {
        return AuthorizationLease::query()
            ->where('device_id', $device->id)
            ->whereNull('revoked_at')
            ->update([
                'revoked_at' => now(),
                'revoked_reason' => $reason,
            ]);
    }

    public function revokeForUserDevice(User $user, Device $device, string $reason): int
    {
        return AuthorizationLease::query()
            ->where('user_id', $user->id)
            ->where('device_id', $device->id)
            ->whereNull('revoked_at')
            ->update([
                'revoked_at' => now(),
                'revoked_reason' => $reason,
            ]);
    }

    private function sign(array $payload): string
    {
        $encoded = $this->base64UrlEncode(json_encode($payload, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE));
        $signature = $this->base64UrlEncode(hash_hmac('sha256', $encoded, $this->signingKey(), true));

        return $encoded.'.'.$signature;
    }

    private function signingKey(): string
    {
        $key = (string) config('app.key');
        if (str_starts_with($key, 'base64:')) {
            $key = base64_decode(substr($key, 7), true) ?: $key;
        }

        return $key;
    }

    private function base64UrlEncode(string $value): string
    {
        return rtrim(strtr(base64_encode($value), '+/', '-_'), '=');
    }

    private function base64UrlDecode(string $value): string
    {
        return base64_decode(strtr($value, '-_', '+/'), true) ?: '';
    }
}
