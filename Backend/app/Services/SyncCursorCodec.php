<?php

namespace App\Services;

use App\Exceptions\ApiException;

class SyncCursorCodec
{
    public function encode(int $businessId, int $outletId, int $lastEventId): string
    {
        $payload = implode('|', ['v1', $businessId, $outletId, $lastEventId, now()->getTimestamp()]);
        $encoded = $this->base64UrlEncode($payload);
        $signature = $this->base64UrlEncode(hash_hmac('sha256', $encoded, $this->key(), true));

        return $encoded.'.'.$signature;
    }

    public function decode(?string $cursor, int $businessId, int $outletId): int
    {
        if ($cursor === null || $cursor === '') {
            return 0;
        }

        $parts = explode('.', $cursor);
        if (count($parts) !== 2) {
            throw new ApiException('SYNC_CURSOR_INVALID', 'Cursor sinkronisasi tidak valid.', 400);
        }

        [$encoded, $signature] = $parts;
        $expected = $this->base64UrlEncode(hash_hmac('sha256', $encoded, $this->key(), true));
        if (! hash_equals($expected, $signature)) {
            throw new ApiException('SYNC_CURSOR_INVALID', 'Tanda tangan cursor tidak valid.', 400);
        }

        $decoded = explode('|', $this->base64UrlDecode($encoded));
        if (count($decoded) !== 5 || $decoded[0] !== 'v1') {
            throw new ApiException('SYNC_CURSOR_INVALID', 'Format cursor tidak didukung.', 400);
        }

        if ((int) $decoded[1] !== $businessId || (int) $decoded[2] !== $outletId) {
            throw new ApiException('SYNC_CURSOR_SCOPE_MISMATCH', 'Cursor bukan milik outlet/perangkat ini.', 403);
        }

        return max(0, (int) $decoded[3]);
    }

    private function key(): string
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
