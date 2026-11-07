<?php

namespace App\Services;

use App\Http\Resources\CategoryResource;
use App\Http\Resources\DeviceResource;
use App\Http\Resources\ProductResource;
use App\Http\Resources\ShiftResource;
use App\Models\Category;
use App\Models\Device;
use App\Models\Product;
use App\Models\SalePayment;
use App\Models\Shift;
use App\Models\SyncEvent;
use App\Models\User;
use Illuminate\Support\Carbon;

class SyncBootstrapService
{
    public const OFFLINE_CATALOG_MAX_AGE_HOURS = 72;

    public function __construct(
        private readonly SyncPullService $pull,
        private readonly ShiftSyncCoordinator $shifts,
    ) {}

    public function bootstrap(User $user, Device $device): array
    {
        $business = $user->business;

        // Capture the cursor before reading catalog so changes made during the
        // bootstrap are still delivered by the first pull.
        $initialEventId = (int) SyncEvent::query()
            ->where('business_id', $business->id)
            ->where('outlet_id', $device->outlet_id)
            ->max('id');

        $categories = Category::query()
            ->where('business_id', $business->id)
            ->where('is_active', true)
            ->withCount(['products' => fn ($query) => $query
                ->where('is_active', true)
                ->where('is_available', true)])
            ->orderBy('sort_order')
            ->orderBy('name')
            ->get();

        $products = Product::query()
            ->where('business_id', $business->id)
            ->where('is_active', true)
            ->with(['category', 'variants', 'addons'])
            ->orderBy('name')
            ->get();

        $openShift = Shift::query()
            ->where('business_id', $business->id)
            ->where('outlet_id', $device->outlet_id)
            ->whereIn('status', [Shift::STATUS_OPEN, Shift::STATUS_CLOSING])
            ->latest('opened_at')
            ->first();

        if ($openShift) {
            $this->shifts->registerParticipant($openShift, $device, $user, true);
            $openShift = $this->shifts->decorate($openShift);
        }

        $catalogVersion = collect([
            Product::query()->where('business_id', $business->id)->max('updated_at'),
            Category::query()->where('business_id', $business->id)->max('updated_at'),
        ])->filter()->max();

        return [
            'device' => (new DeviceResource($device->load('outlet')))->resolve(),
            'business' => [
                'uuid' => $business->uuid,
                'name' => $business->name,
                'address' => $business->address,
                'phone' => $business->phone,
                'email' => $business->email,
                'currency' => $business->currency ?: 'IDR',
                'timezone' => $business->timezone ?: 'Asia/Jakarta',
            ],
            'outlet' => [
                'uuid' => $device->outlet->uuid,
                'name' => $device->outlet->name,
                'code' => $device->outlet->code,
                'address' => $device->outlet->address,
                'phone' => $device->outlet->phone,
            ],
            'user' => [
                'uuid' => $user->uuid,
                'name' => $user->name,
                'username' => $user->username,
                'roles' => $user->roleSlugs(),
                'permissions' => $user->permissionSlugs(),
                'authentication_version' => (int) $user->auth_version,
                'has_pin' => $user->pin_hash !== null,
            ],
            'catalog' => [
                'categories' => CategoryResource::collection($categories)->resolve(),
                'products' => ProductResource::collection($products)->resolve(),
                'catalog_version' => $catalogVersion ? Carbon::parse($catalogVersion)->toIso8601String() : null,
                'offline_catalog_max_age_hours' => self::OFFLINE_CATALOG_MAX_AGE_HOURS,
            ],
            'config' => [
                'currency' => $business->currency ?: 'IDR',
                'timezone' => $business->timezone ?: 'Asia/Jakarta',
                'tax' => [
                    'enabled' => (bool) $business->tax_enabled,
                    'rate_basis_points' => (int) $business->tax_rate_basis_points,
                    'includes_service_charge' => (bool) $business->tax_includes_service_charge,
                ],
                'service_charge' => [
                    'enabled' => (bool) $business->service_charge_enabled,
                    'rate_basis_points' => (int) $business->service_charge_rate_basis_points,
                ],
                'receipt_number_format' => 'RJS-{OUTLET}-{TERMINAL}-{SEQUENCE}',
                'payment_methods' => [
                    SalePayment::METHOD_CASH,
                    SalePayment::METHOD_QRIS,
                    SalePayment::METHOD_TRANSFER,
                    SalePayment::METHOD_EWALLET,
                ],
                'non_cash_proof_required' => (bool) $business->non_cash_proof_required,
                'order_types' => ['dine_in', 'take_away', 'delivery'],
                'offline_lease_max_hours' => OfflineLeaseService::MAX_HOURS,
                'sync' => [
                    'protocol_version' => SyncPushService::PROTOCOL_VERSION,
                    'schema_version' => SyncPushService::SCHEMA_VERSION,
                    'max_batch_events' => SyncPushService::MAX_EVENTS,
                    'max_batch_bytes' => SyncPushService::MAX_BYTES,
                    'pull_limit' => SyncPullService::MAX_LIMIT,
                ],
            ],
            'open_shift' => $openShift ? (new ShiftResource($openShift))->resolve() : null,
            'sync' => [
                'cursor' => $this->pull->markCursor($user, $device, $initialEventId),
                'server_time' => now()->toIso8601String(),
            ],
        ];
    }
}
