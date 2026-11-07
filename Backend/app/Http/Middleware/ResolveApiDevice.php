<?php

namespace App\Http\Middleware;

use App\Exceptions\ApiException;
use App\Models\Device;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class ResolveApiDevice
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();
        if (! $user) {
            throw new ApiException('UNAUTHENTICATED', 'Token autentikasi tidak valid.', 401);
        }

        if (! $user->is_active) {
            throw new ApiException('ACCOUNT_INACTIVE', 'Akun tidak aktif.', 403);
        }

        $deviceUuid = trim((string) $request->header('X-Device-Id'));
        if ($deviceUuid === '') {
            throw new ApiException('DEVICE_REQUIRED', 'Header X-Device-Id wajib diisi.', 400);
        }

        $device = Device::query()
            ->where('uuid', $deviceUuid)
            ->where('business_id', $user->business_id)
            ->where(function ($query) use ($user) {
                $query->where('outlet_id', $user->outlet_id)
                    ->orWhereNull('outlet_id');
            })
            ->first();

        if (! $device) {
            throw new ApiException('DEVICE_NOT_REGISTERED', 'Perangkat tidak terdaftar pada bisnis/outlet ini.', 403);
        }

        if (! $device->isActive()) {
            throw new ApiException('DEVICE_REVOKED', 'Perangkat telah dicabut. Hubungi Owner.', 403);
        }

        $device->forceFill(['last_seen_at' => now()])->save();
        $request->attributes->set('api_device', $device);
        $request->attributes->set('api_outlet', $device->outlet);

        return $next($request);
    }
}
