<?php

namespace App\Http\Controllers\Api\V1;

use App\Actions\Orders\CreateOrder;
use App\Actions\Orders\TransitionOrder;
use App\Actions\Orders\UpdateOrder;
use App\Exceptions\ApiException;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\StoreOrderRequest;
use App\Http\Requests\Api\TransitionOrderRequest;
use App\Http\Requests\Api\UpdateOrderRequest;
use App\Http\Resources\OrderResource;
use App\Models\Device;
use App\Models\Order;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class OrderController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $this->authorize('viewAny', Order::class);

        $device = $this->device($request);
        $status = (string) $request->query('status', 'active');
        $search = trim((string) $request->query('q'));
        $perPage = min(max((int) $request->query('per_page', 20), 1), 100);

        $orders = Order::query()
            ->where('business_id', $request->user()->business_id)
            ->where('outlet_id', $device->outlet_id)
            ->with(['shift', 'device', 'cashier', 'items.modifiers'])
            ->when($status === 'active', fn ($query) => $query->active())
            ->when($status !== 'active' && $status !== 'all', fn ($query) => $query->where('status', $status))
            ->when($search !== '', fn ($query) => $query->where(function ($query) use ($search) {
                $query->where('order_number', 'like', "%{$search}%")
                    ->orWhere('table_number', 'like', "%{$search}%");
            }))
            ->when($request->filled('shift_uuid'), fn ($query) => $query->whereHas(
                'shift',
                fn ($shift) => $shift->where('uuid', $request->query('shift_uuid')),
            ))
            ->orderByDesc('updated_at')
            ->paginate($perPage)
            ->withQueryString();

        return ApiResponse::data(
            OrderResource::collection($orders),
            meta: [
                'pagination' => [
                    'current_page' => $orders->currentPage(),
                    'per_page' => $orders->perPage(),
                    'total' => $orders->total(),
                    'last_page' => $orders->lastPage(),
                ],
            ],
        );
    }

    public function show(Request $request, string $order): JsonResponse
    {
        $model = $this->resolveOrder($request, $order);
        $this->authorize('view', $model);

        return ApiResponse::data(new OrderResource($this->loadOrder($model)));
    }

    public function store(StoreOrderRequest $request, CreateOrder $action): JsonResponse
    {
        $this->authorize('create', Order::class);

        $order = $action->handle(
            $request->validated(),
            $request->user(),
            $this->device($request),
        );

        return ApiResponse::data(new OrderResource($this->loadOrder($order)), 201);
    }

    public function update(UpdateOrderRequest $request, string $order, UpdateOrder $action): JsonResponse
    {
        $model = $this->resolveOrder($request, $order);
        $this->authorize('update', $model);

        $updated = $action->handle($model, $request->validated(), $request->user());

        return ApiResponse::data(new OrderResource($this->loadOrder($updated)));
    }

    public function hold(TransitionOrderRequest $request, string $order, TransitionOrder $action): JsonResponse
    {
        $model = $this->resolveOrder($request, $order);
        $this->authorize('update', $model);

        $updated = $action->hold($model, (int) $request->validated('base_version'), $request->user());

        return ApiResponse::data(new OrderResource($this->loadOrder($updated)));
    }

    public function resume(TransitionOrderRequest $request, string $order, TransitionOrder $action): JsonResponse
    {
        $model = $this->resolveOrder($request, $order);
        $this->authorize('update', $model);

        $updated = $action->resume($model, (int) $request->validated('base_version'), $request->user());

        return ApiResponse::data(new OrderResource($this->loadOrder($updated)));
    }

    public function cancel(TransitionOrderRequest $request, string $order, TransitionOrder $action): JsonResponse
    {
        $model = $this->resolveOrder($request, $order);
        $this->authorize('update', $model);

        $updated = $action->cancel(
            $model,
            (int) $request->validated('base_version'),
            $request->user(),
            (string) $request->validated('reason'),
        );

        return ApiResponse::data(new OrderResource($this->loadOrder($updated)));
    }

    private function resolveOrder(Request $request, string $uuid): Order
    {
        $order = Order::query()
            ->where('uuid', $uuid)
            ->where('business_id', $request->user()->business_id)
            ->first();

        if (! $order) {
            throw ApiException::notFound('Order tidak ditemukan.');
        }

        return $order;
    }

    private function loadOrder(Order $order): Order
    {
        return $order->load([
            'items.modifiers',
            'shift',
            'device',
            'cashier',
            'statusHistories.actor',
            'sale',
        ]);
    }

    private function device(Request $request): Device
    {
        $device = $request->attributes->get('api_device');
        if (! $device instanceof Device) {
            throw new ApiException('DEVICE_REQUIRED', 'Konteks perangkat tidak tersedia.', 400);
        }

        return $device;
    }
}
