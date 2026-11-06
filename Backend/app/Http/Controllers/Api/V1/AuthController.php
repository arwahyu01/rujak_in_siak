<?php

namespace App\Http\Controllers\Api\V1;

use App\Exceptions\ApiException;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\LoginRequest;
use App\Http\Requests\Api\OfflineLeaseRequest;
use App\Http\Requests\Api\UpdatePinRequest;
use App\Http\Resources\DeviceResource;
use App\Http\Resources\UserResource;
use App\Models\Device;
use App\Models\User;
use App\Models\UserSession;
use App\Services\AuditLogger;
use App\Services\OfflineLeaseService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Laravel\Sanctum\PersonalAccessToken;

class AuthController extends Controller
{
    private const TOKEN_TTL_DAYS = 30;

    private const MAX_LOGIN_ATTEMPTS = 5;

    private const LOCK_MINUTES = 15;

    public function login(LoginRequest $request, AuditLogger $audit, OfflineLeaseService $leases): JsonResponse
    {
        $identifier = trim((string) $request->string('identifier'));
        $field = filter_var($identifier, FILTER_VALIDATE_EMAIL) ? 'email' : 'username';

        $user = User::query()
            ->with(['business', 'outlet'])
            ->where($field, $identifier)
            ->first();

        if (! $user) {
            throw new ApiException('AUTH_INVALID_CREDENTIALS', 'Kredensial tidak sesuai.', 401);
        }

        if ($user->locked_until && $user->locked_until->isFuture()) {
            throw new ApiException(
                'AUTH_LOCKED',
                'Akun terkunci sementara karena percobaan login gagal. Coba lagi nanti.',
                429,
                ['locked_until' => $user->locked_until->toIso8601String()],
                true,
            );
        }

        if (! $user->is_active || ! $user->business?->is_active) {
            throw new ApiException('AUTH_INVALID_CREDENTIALS', 'Kredensial tidak sesuai.', 401);
        }

        if (! Hash::check((string) $request->input('password'), $user->password)) {
            $attempts = ((int) $user->failed_login_attempts) + 1;
            $attributes = ['failed_login_attempts' => $attempts];
            if ($attempts >= self::MAX_LOGIN_ATTEMPTS) {
                $attributes['locked_until'] = now()->addMinutes(self::LOCK_MINUTES);
                $attributes['failed_login_attempts'] = 0;
            }
            $user->forceFill($attributes)->save();

            throw new ApiException('AUTH_INVALID_CREDENTIALS', 'Kredensial tidak sesuai.', 401);
        }

        $device = null;
        if ($request->filled('device_uuid')) {
            $device = Device::query()
                ->where('uuid', (string) $request->string('device_uuid'))
                ->where('business_id', $user->business_id)
                ->where('outlet_id', $user->outlet_id)
                ->first();

            if ($device && ! $device->isActive()) {
                throw new ApiException('DEVICE_REVOKED', 'Perangkat telah dicabut.', 403);
            }
        }

        $result = DB::transaction(function () use ($request, $user, $device, $audit, $leases) {
            $user->forceFill([
                'failed_login_attempts' => 0,
                'locked_until' => null,
                'last_login_at' => now(),
            ])->save();

            $expiresAt = now()->addDays(self::TOKEN_TTL_DAYS);
            $token = $user->createToken(
                (string) ($request->input('token_name') ?: 'flutter-pos'),
                ['api'],
                $expiresAt,
            );

            $session = UserSession::create([
                'uuid' => (string) Str::uuid(),
                'user_id' => $user->id,
                'device_id' => $device?->id,
                'personal_access_token_id' => $token->accessToken->id,
                'ip_address' => $request->ip(),
                'user_agent' => Str::limit((string) $request->userAgent(), 255, ''),
                'logged_in_at' => now(),
                'last_used_at' => now(),
            ]);

            if ($device) {
                $device->forceFill(['last_seen_at' => now()])->save();
            }

            $audit->record(
                'auth.api_login',
                'auth',
                'Login aplikasi POS Android',
                $user,
                actor: $user,
                businessId: $user->business_id,
            );

            $lease = $device ? $leases->issue($user, $device) : null;

            return [
                'token' => $token->plainTextToken,
                'expires_at' => $expiresAt->toIso8601String(),
                'session_uuid' => $session->uuid,
                'lease' => $lease,
            ];
        });

        return ApiResponse::data([
            'token' => $result['token'],
            'token_type' => 'Bearer',
            'expires_at' => $result['expires_at'],
            'session_uuid' => $result['session_uuid'],
            'user' => new UserResource($user->load(['business', 'outlet', 'roles'])),
            'device' => $device ? new DeviceResource($device->load('outlet')) : null,
            'offline_lease' => $result['lease'],
        ]);
    }

    public function logout(Request $request, AuditLogger $audit, OfflineLeaseService $leases): JsonResponse
    {
        $user = $request->user();
        $token = $user->currentAccessToken();

        DB::transaction(function () use ($request, $user, $token, $audit, $leases) {
            if ($token instanceof PersonalAccessToken) {
                UserSession::query()
                    ->where('personal_access_token_id', $token->id)
                    ->whereNull('revoked_at')
                    ->update(['revoked_at' => now(), 'revoked_reason' => 'logout']);

                $token->delete();
            }

            $deviceUuid = trim((string) $request->header('X-Device-Id'));
            if ($deviceUuid !== '') {
                $device = Device::query()
                    ->where('uuid', $deviceUuid)
                    ->where('business_id', $user->business_id)
                    ->first();
                if ($device) {
                    $leases->revokeForUserDevice($user, $device, 'logout');
                }
            }

            $audit->record('auth.api_logout', 'auth', 'Logout aplikasi POS Android', $user, actor: $user, businessId: $user->business_id);
        });

        return ApiResponse::data(['message' => 'Logout berhasil.']);
    }

    public function refresh(Request $request, AuditLogger $audit): JsonResponse
    {
        $user = $request->user();
        $oldToken = $user->currentAccessToken();

        $result = DB::transaction(function () use ($user, $oldToken, $audit) {
            $expiresAt = now()->addDays(self::TOKEN_TTL_DAYS);
            $newToken = $user->createToken('flutter-pos-refresh', ['api'], $expiresAt);

            if ($oldToken instanceof PersonalAccessToken) {
                UserSession::query()
                    ->where('personal_access_token_id', $oldToken->id)
                    ->whereNull('revoked_at')
                    ->update(['personal_access_token_id' => $newToken->accessToken->id, 'last_used_at' => now()]);

                $oldToken->delete();
            }

            $audit->record('auth.token_refreshed', 'auth', 'Refresh token aplikasi POS', $user, actor: $user, businessId: $user->business_id);

            return [
                'token' => $newToken->plainTextToken,
                'expires_at' => $expiresAt->toIso8601String(),
            ];
        });

        return ApiResponse::data([
            'token' => $result['token'],
            'token_type' => 'Bearer',
            'expires_at' => $result['expires_at'],
        ]);
    }

    public function me(Request $request): JsonResponse
    {
        $user = $request->user()->load(['business', 'outlet', 'roles']);

        $device = null;
        $deviceUuid = trim((string) $request->header('X-Device-Id'));
        if ($deviceUuid !== '') {
            $device = Device::query()
                ->with('outlet')
                ->where('uuid', $deviceUuid)
                ->where('business_id', $user->business_id)
                ->first();
        }

        return ApiResponse::data([
            'user' => new UserResource($user),
            'device' => $device ? new DeviceResource($device) : null,
            'server_time' => now()->toIso8601String(),
        ]);
    }

    public function updatePin(UpdatePinRequest $request, AuditLogger $audit, OfflineLeaseService $leases): JsonResponse
    {
        $user = $request->user();

        if (! Hash::check((string) $request->input('current_password'), $user->password)) {
            throw new ApiException('CURRENT_PASSWORD_INVALID', 'Password saat ini tidak sesuai.', 422);
        }

        DB::transaction(function () use ($request, $user, $audit, $leases) {
            $user->forceFill([
                'pin_hash' => Hash::make((string) $request->input('pin')),
                'pin_updated_at' => now(),
                'auth_version' => ((int) $user->auth_version) + 1,
            ])->save();

            $leases->revokeForDevice(
                Device::query()->where('uuid', $request->header('X-Device-Id'))->firstOrFail(),
                'pin_changed',
            );

            $audit->record('auth.pin_updated', 'auth', 'Memperbarui PIN kasir', $user, actor: $user, businessId: $user->business_id);
        });

        return ApiResponse::data(['message' => 'PIN berhasil diperbarui. Minta lease offline baru bila diperlukan.']);
    }

    public function offlineLease(
        OfflineLeaseRequest $request,
        OfflineLeaseService $leases,
        AuditLogger $audit,
    ): JsonResponse {
        $user = $request->user();
        $device = $request->attributes->get('api_device');

        if ($user->pin_hash !== null) {
            if (! $request->filled('pin') && ! $request->filled('password')) {
                throw new ApiException('AUTH_PROOF_REQUIRED', 'PIN atau password diperlukan untuk menerbitkan lease offline.', 422);
            }

            $validPin = $request->filled('pin') && Hash::check((string) $request->input('pin'), $user->pin_hash);
            $validPassword = $request->filled('password') && Hash::check((string) $request->input('password'), $user->password);

            if (! $validPin && ! $validPassword) {
                throw new ApiException('AUTH_PROOF_INVALID', 'PIN/password tidak sesuai.', 401);
            }
        }

        $lease = $leases->issue($user, $device, (int) $request->input('hours', OfflineLeaseService::MAX_HOURS));

        $audit->record(
            'auth.offline_lease_issued',
            'auth',
            'Menerbitkan offline authorization lease untuk perangkat '.$device->terminal_code,
            $device,
            actor: $user,
            businessId: $user->business_id,
        );

        return ApiResponse::data($lease);
    }
}
