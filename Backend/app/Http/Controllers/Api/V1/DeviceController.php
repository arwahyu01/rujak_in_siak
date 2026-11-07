<?php

namespace App\Http\Controllers\Api\V1;

use App\Exceptions\ApiException;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\RegisterDeviceRequest;
use App\Http\Resources\DeviceResource;
use App\Models\Device;
use App\Models\UserSession;
use App\Services\AuditLogger;
use App\Services\OfflineLeaseService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Laravel\Sanctum\PersonalAccessToken;

class DeviceController extends Controller
{
    public function register(
        RegisterDeviceRequest $request,
        OfflineLeaseService $leases,
        AuditLogger $audit,
    ): JsonResponse {
        $user = $request->user()->load(['business', 'outlet']);
        $outlet = $user->outlet ?? $user->business->primaryOutlet();

        if (! $outlet) {
            throw new ApiException('OUTLET_UNAVAILABLE', 'Tidak ada outlet aktif untuk registrasi perangkat.', 422);
        }

        $device = DB::transaction(function () use ($request, $user, $outlet, $leases, $audit) {
            // Serialize terminal allocation within an outlet so concurrent device
            // registrations cannot select the same POS number.
            $outlet = $outlet->newQuery()->whereKey($outlet->id)->lockForUpdate()->firstOrFail();
            $existing = Device::query()->where('uuid', (string) $request->input('uuid'))->first();

            if ($existing && ((int) $existing->business_id !== (int) $user->business_id
                || (int) $existing->outlet_id !== (int) $outlet->id)) {
                throw new ApiException('DEVICE_SCOPE_MISMATCH', 'Perangkat bukan milik bisnis/outlet ini.', 403);
            }

            if ($existing && ! $existing->isActive()) {
                throw new ApiException('DEVICE_REVOKED', 'Perangkat telah dicabut dan tidak dapat didaftarkan ulang. Gunakan terminal baru.', 403);
            }

            if ($existing && $existing->device_fingerprint && $request->filled('device_fingerprint')
                && ! hash_equals($existing->device_fingerprint, (string) $request->input('device_fingerprint'))) {
                throw new ApiException('DEVICE_FINGERPRINT_MISMATCH', 'Fingerprint perangkat tidak cocok dengan registrasi sebelumnya.', 403);
            }

            $terminalCode = strtoupper(trim((string) $request->input('terminal_code')));
            if ($terminalCode === '') {
                $terminalCode = $existing?->terminal_code ?? $this->nextTerminalCode($outlet->id);
            }
            $terminalTaken = Device::query()
                ->where('outlet_id', $outlet->id)
                ->where('terminal_code', $terminalCode)
                ->when($existing, fn ($query) => $query->whereKeyNot($existing->id))
                ->exists();

            if ($terminalTaken) {
                throw ApiException::conflict('TERMINAL_CODE_TAKEN', 'Terminal code sudah dipakai perangkat lain di outlet ini.');
            }

            $attributes = [
                'outlet_id' => $existing?->outlet_id ?? $outlet->id,
                'name' => (string) $request->string('name'),
                'terminal_code' => $terminalCode,
                'platform' => $request->input('platform', 'android'),
                'app_version' => $request->input('app_version'),
                'device_fingerprint' => $request->input('device_fingerprint'),
                'status' => Device::STATUS_ACTIVE,
                'last_seen_at' => now(),
                'activated_at' => $existing?->activated_at ?? now(),
            ];

            if ($existing) {
                $existing->update($attributes);
                $device = $existing;
                $action = 'device.updated';
            } else {
                $device = Device::create([
                    ...$attributes,
                    'uuid' => (string) $request->input('uuid'),
                    'business_id' => $user->business_id,
                    'last_sequence' => 0,
                ]);
                $action = 'device.registered';
            }

            $token = $user->currentAccessToken();
            if ($token instanceof PersonalAccessToken) {
                UserSession::query()
                    ->where('personal_access_token_id', $token->id)
                    ->whereNull('revoked_at')
                    ->update(['device_id' => $device->id, 'last_used_at' => now()]);
            }

            $lease = $leases->issue($user, $device->load(['business', 'outlet']));

            $audit->record(
                $action,
                'devices',
                'Registrasi perangkat '.$device->terminal_code,
                $device,
                [],
                $device->only(['name', 'terminal_code', 'platform', 'status']),
                $user,
                $user->business_id,
            );

            return ['device' => $device, 'lease' => $lease];
        });

        return ApiResponse::data([
            'device' => new DeviceResource($device['device']->load('outlet')),
            'offline_lease' => $device['lease'],
        ], 201);
    }

    private function nextTerminalCode(int $outletId): string
    {
        $used = Device::query()
            ->where('outlet_id', $outletId)
            ->pluck('terminal_code')
            ->map(fn ($code) => strtoupper((string) $code))
            ->all();
        $used = array_fill_keys($used, true);

        for ($number = 1; $number <= 999999; $number++) {
            $candidate = 'POS'.$number;
            if (! isset($used[$candidate])) {
                return $candidate;
            }
        }

        throw ApiException::conflict('TERMINAL_CODE_EXHAUSTED', 'Tidak ada kode terminal yang tersedia untuk outlet ini.');
    }

    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $devices = Device::query()
            ->with('outlet')
            ->where('business_id', $user->business_id)
            ->when($user->outlet_id, fn ($query) => $query->where('outlet_id', $user->outlet_id))
            ->orderBy('name')
            ->paginate(min(100, max(1, (int) $request->query('per_page', 25))));

        return ApiResponse::data(
            DeviceResource::collection($devices->items()),
            meta: [
                'current_page' => $devices->currentPage(),
                'last_page' => $devices->lastPage(),
                'per_page' => $devices->perPage(),
                'total' => $devices->total(),
            ],
        );
    }

    public function revoke(Request $request, Device $device, OfflineLeaseService $leases, AuditLogger $audit): JsonResponse
    {
        $user = $request->user();

        if ((int) $device->business_id !== (int) $user->business_id) {
            throw ApiException::notFound();
        }

        if (! $device->isActive()) {
            throw ApiException::conflict('DEVICE_ALREADY_REVOKED', 'Perangkat sudah dicabut.');
        }

        DB::transaction(function () use ($device, $user, $leases, $audit) {
            $device->forceFill([
                'status' => Device::STATUS_REVOKED,
                'revoked_at' => now(),
            ])->save();

            $leases->revokeForDevice($device, 'device_revoked');

            $tokenIds = UserSession::query()
                ->where('device_id', $device->id)
                ->whereNotNull('personal_access_token_id')
                ->pluck('personal_access_token_id')
                ->unique()
                ->all();

            UserSession::query()
                ->where('device_id', $device->id)
                ->whereNull('revoked_at')
                ->update(['revoked_at' => now(), 'revoked_reason' => 'device_revoked']);

            if ($tokenIds !== []) {
                PersonalAccessToken::query()->whereIn('id', $tokenIds)->delete();
            }

            $audit->record(
                'device.revoked',
                'devices',
                'Mencabut perangkat '.$device->terminal_code,
                $device,
                ['status' => Device::STATUS_ACTIVE],
                ['status' => Device::STATUS_REVOKED, 'revoked_at' => now()->toIso8601String()],
                $user,
                $user->business_id,
            );
        });

        return ApiResponse::data(new DeviceResource($device->fresh()->load('outlet')));
    }
}
