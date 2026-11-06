<?php

namespace App\Http\Controllers\Api\V1;

use App\Actions\Sales\CheckoutSale;
use App\Actions\Sales\RecordSalePayment;
use App\Actions\Sales\RefundSale;
use App\Actions\Sales\VoidSale;
use App\Exceptions\ApiException;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\CheckoutRequest;
use App\Http\Requests\Api\RecordPaymentRequest;
use App\Http\Requests\Api\RefundSaleRequest;
use App\Http\Requests\Api\VoidSaleRequest;
use App\Http\Resources\SaleResource;
use App\Models\Device;
use App\Models\Sale;
use App\Services\IdempotencyService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;

class SaleController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $this->authorize('viewAny', Sale::class);

        $device = $this->device($request);
        $business = $request->user()->business;
        $search = trim((string) $request->query('q'));
        $perPage = min(max((int) $request->query('per_page', 20), 1), 100);

        $sales = Sale::query()
            ->where('business_id', $business->id)
            ->where('outlet_id', $device->outlet_id)
            ->with(['cashier', 'device', 'shift'])
            ->when($search !== '', fn ($query) => $query->where(function ($query) use ($search) {
                $query->where('receipt_number', 'like', "%{$search}%")
                    ->orWhere('table_number', 'like', "%{$search}%");
            }))
            ->when($request->filled('payment_status'), fn ($query) => $query
                ->where('payment_status', $request->query('payment_status')))
            ->when($request->filled('lifecycle_status'), fn ($query) => $query
                ->where('lifecycle_status', $request->query('lifecycle_status')))
            ->when($request->filled('shift_uuid'), fn ($query) => $query->whereHas(
                'shift',
                fn ($shift) => $shift->where('uuid', $request->query('shift_uuid')),
            ))
            ->when($request->filled('date_from'), fn ($query) => $query->where(
                'transacted_at',
                '>=',
                $this->localDate($request->query('date_from'), $business->timezone)->startOfDay(),
            ))
            ->when($request->filled('date_to'), fn ($query) => $query->where(
                'transacted_at',
                '<=',
                $this->localDate($request->query('date_to'), $business->timezone)->endOfDay(),
            ))
            ->orderByDesc('transacted_at')
            ->paginate($perPage)
            ->withQueryString();

        return ApiResponse::data(
            SaleResource::collection($sales),
            meta: [
                'pagination' => [
                    'current_page' => $sales->currentPage(),
                    'per_page' => $sales->perPage(),
                    'total' => $sales->total(),
                    'last_page' => $sales->lastPage(),
                ],
            ],
        );
    }

    public function show(Request $request, string $sale): JsonResponse
    {
        $model = $this->resolveSale($request, $sale);
        $this->authorize('view', $model);

        return ApiResponse::data(new SaleResource($this->loadSale($model)));
    }

    public function checkout(
        CheckoutRequest $request,
        CheckoutSale $action,
        IdempotencyService $idempotency,
    ): JsonResponse {
        $this->authorize('create', Sale::class);

        $device = $this->device($request);
        $data = $request->validated();
        $key = $this->idempotencyKey($request);
        $idempotencyRequest = ['fingerprint' => null, 'data' => $data];

        if ($key) {
            $existing = $idempotency->existing(
                $request->user()->business_id,
                'sales.checkout',
                $key,
                $idempotencyRequest,
            );

            if ($existing) {
                $sale = Sale::query()
                    ->where('uuid', $existing->resource_uuid)
                    ->where('business_id', $request->user()->business_id)
                    ->firstOrFail();

                return ApiResponse::data(new SaleResource($this->loadSale($sale)), 201);
            }
        }

        $sale = $action->handle($data, $request->user(), $device, $key);

        return ApiResponse::data(new SaleResource($this->loadSale($sale->fresh())), 201);
    }

    public function void(
        VoidSaleRequest $request,
        string $sale,
        VoidSale $action,
        IdempotencyService $idempotency,
    ): JsonResponse {
        $model = $this->resolveSale($request, $sale);
        $this->authorize('void', $model);

        $data = $request->validated();
        unset($data['idempotency_key']);
        $key = $this->idempotencyKey($request);

        if ($key) {
            $idempotency->existing($model->business_id, 'sales.void', $key, $data);
        }

        $updated = $action->handle($model, $data, $request->user(), $key);

        return ApiResponse::data(new SaleResource($this->loadSale($updated)));
    }

    public function refund(
        RefundSaleRequest $request,
        string $sale,
        RefundSale $action,
        IdempotencyService $idempotency,
    ): JsonResponse {
        $model = $this->resolveSale($request, $sale);
        $this->authorize('refund', $model);

        $data = $request->validated();
        unset($data['idempotency_key']);
        $key = $this->idempotencyKey($request);

        if ($key) {
            $idempotency->existing($model->business_id, 'sales.refund', $key, $data);
        }

        $updated = $action->handle($model, $data, $request->user(), $key);

        return ApiResponse::data(new SaleResource($this->loadSale($updated)));
    }

    public function recordPayment(
        RecordPaymentRequest $request,
        string $sale,
        RecordSalePayment $action,
        IdempotencyService $idempotency,
    ): JsonResponse {
        $model = $this->resolveSale($request, $sale);
        $this->authorize('view', $model);

        $device = $this->device($request);
        $data = $request->validated();
        $key = $this->idempotencyKey($request);
        unset($data['idempotency_key']);

        if ($key) {
            $existing = $idempotency->existing(
                $model->business_id,
                'sales.payments.record',
                $key,
                $data,
            );

            if ($existing) {
                $model = $this->resolveSale($request, $sale);

                return ApiResponse::data(new SaleResource($this->loadSale($model)));
            }
        }

        $updated = $action->handle($model, $data, $request->user(), $device->id, $key);

        return ApiResponse::data(new SaleResource($this->loadSale($updated)), 201);
    }

    private function resolveSale(Request $request, string $uuid): Sale
    {
        $device = $this->device($request);
        $sale = Sale::query()
            ->where('uuid', $uuid)
            ->where('business_id', $request->user()->business_id)
            ->where('outlet_id', $device->outlet_id)
            ->first();

        if (! $sale) {
            throw ApiException::notFound('Transaksi tidak ditemukan.');
        }

        return $sale;
    }

    private function loadSale(Sale $sale): Sale
    {
        return $sale->load([
            'items',
            'payments.recordedBy',
            'payments.verifiedBy',
            'payments.rejectedBy',
            'refunds.createdBy',
            'cashier',
            'device',
            'shift',
            'voidedBy',
        ]);
    }

    private function idempotencyKey(Request $request): ?string
    {
        $key = trim((string) ($request->header('Idempotency-Key') ?: $request->input('idempotency_key', '')));

        return $key === '' ? null : $key;
    }

    private function localDate(string $value, ?string $timezone): Carbon
    {
        try {
            return Carbon::parse($value, $timezone ?: config('app.timezone'));
        } catch (\Throwable) {
            throw new ApiException('DATE_INVALID', 'Format tanggal tidak valid.', 422);
        }
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
