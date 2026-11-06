<?php

namespace App\Http\Controllers\Api\V1;

use App\Actions\Payments\RejectPayment;
use App\Actions\Payments\VerifyPayment;
use App\Exceptions\ApiException;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\RejectPaymentRequest;
use App\Http\Requests\Api\VerifyPaymentRequest;
use App\Http\Resources\PaymentResource;
use App\Models\Device;
use App\Models\SalePayment;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PaymentController extends Controller
{
    public function pending(Request $request): JsonResponse
    {
        $this->authorize('viewAny', SalePayment::class);

        $device = $this->device($request);
        $perPage = min(max((int) $request->query('per_page', 20), 1), 100);

        $payments = SalePayment::query()
            ->where('status', SalePayment::STATUS_AWAITING_VERIFICATION)
            ->whereHas('sale', fn ($query) => $query
                ->where('business_id', $request->user()->business_id)
                ->where('outlet_id', $device->outlet_id))
            ->with(['sale', 'recordedBy'])
            ->orderBy('recorded_at')
            ->paginate($perPage)
            ->withQueryString();

        return ApiResponse::data(
            PaymentResource::collection($payments),
            meta: [
                'pagination' => [
                    'current_page' => $payments->currentPage(),
                    'per_page' => $payments->perPage(),
                    'total' => $payments->total(),
                    'last_page' => $payments->lastPage(),
                ],
            ],
        );
    }

    public function show(Request $request, string $payment): JsonResponse
    {
        $model = $this->resolvePayment($request, $payment);
        $this->authorize('view', $model);

        return ApiResponse::data(new PaymentResource($this->loadPayment($model)));
    }

    public function verify(
        VerifyPaymentRequest $request,
        string $payment,
        VerifyPayment $action,
    ): JsonResponse {
        $model = $this->resolvePayment($request, $payment);
        $this->authorize('verify', $model);

        $updated = $action->handle($model, $request->validated(), $request->user());

        return ApiResponse::data(new PaymentResource($this->loadPayment($updated)));
    }

    public function reject(
        RejectPaymentRequest $request,
        string $payment,
        RejectPayment $action,
    ): JsonResponse {
        $model = $this->resolvePayment($request, $payment);
        $this->authorize('reject', $model);

        $updated = $action->handle($model, $request->validated(), $request->user());

        return ApiResponse::data(new PaymentResource($this->loadPayment($updated)));
    }

    private function resolvePayment(Request $request, string $uuid): SalePayment
    {
        $device = $this->device($request);
        $payment = SalePayment::query()
            ->where('uuid', $uuid)
            ->whereHas('sale', fn ($query) => $query
                ->where('business_id', $request->user()->business_id)
                ->where('outlet_id', $device->outlet_id))
            ->first();

        if (! $payment) {
            throw ApiException::notFound('Pembayaran tidak ditemukan.');
        }

        return $payment;
    }

    private function loadPayment(SalePayment $payment): SalePayment
    {
        return $payment->load(['sale', 'recordedBy', 'verifiedBy', 'rejectedBy', 'verificationLogs.actor']);
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
