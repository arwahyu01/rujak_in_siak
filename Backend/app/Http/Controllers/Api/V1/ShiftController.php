<?php

namespace App\Http\Controllers\Api\V1;

use App\Actions\Shifts\CloseShift;
use App\Actions\Shifts\OpenShift;
use App\Actions\Shifts\ReconcileShift;
use App\Actions\Shifts\RecordCashMovement;
use App\Exceptions\ApiException;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\CashMovementRequest;
use App\Http\Requests\Api\CloseShiftRequest;
use App\Http\Requests\Api\OpenShiftRequest;
use App\Http\Requests\Api\ReconcileShiftRequest;
use App\Http\Resources\ShiftResource;
use App\Models\Device;
use App\Models\Shift;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ShiftController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $this->authorize('viewAny', Shift::class);

        $device = $this->device($request);
        $perPage = min(max((int) $request->query('per_page', 20), 1), 100);

        $shifts = Shift::query()
            ->where('business_id', $request->user()->business_id)
            ->where('outlet_id', $device->outlet_id)
            ->with(['cashier', 'device', 'outlet', 'closingSnapshot'])
            ->when($request->filled('status'), fn ($query) => $query
                ->where('status', $request->query('status')))
            ->when($request->boolean('active_only'), fn ($query) => $query
                ->where('status', Shift::STATUS_OPEN))
            ->orderByDesc('opened_at')
            ->paginate($perPage)
            ->withQueryString();

        return ApiResponse::data(
            ShiftResource::collection($shifts),
            meta: [
                'pagination' => [
                    'current_page' => $shifts->currentPage(),
                    'per_page' => $shifts->perPage(),
                    'total' => $shifts->total(),
                    'last_page' => $shifts->lastPage(),
                ],
            ],
        );
    }

    public function show(Request $request, string $shift): JsonResponse
    {
        $model = $this->resolveShift($request, $shift);
        $this->authorize('view', $model);

        return ApiResponse::data(new ShiftResource($this->loadShift($model)));
    }

    public function open(OpenShiftRequest $request, OpenShift $action): JsonResponse
    {
        $this->authorize('create', Shift::class);

        $shift = $action->handle($request->validated(), $request->user(), $this->device($request));

        return ApiResponse::data(new ShiftResource($this->loadShift($shift)), 201);
    }

    public function close(CloseShiftRequest $request, CloseShift $action): JsonResponse
    {
        $shift = $this->resolveShift($request, (string) $request->validated('shift_uuid'));
        $this->authorize('manage', $shift);

        $closed = $action->handle($shift, $request->validated(), $request->user(), $this->device($request));

        return ApiResponse::data(new ShiftResource($this->loadShift($closed)));
    }

    public function cashMovement(
        CashMovementRequest $request,
        string $shift,
        RecordCashMovement $action,
    ): JsonResponse {
        $model = $this->resolveShift($request, $shift);
        $this->authorize('manage', $model);

        $updated = $action->handle($model, $request->validated(), $request->user(), $this->device($request));

        return ApiResponse::data(new ShiftResource($this->loadShift($updated)), 201);
    }

    public function reconcile(
        ReconcileShiftRequest $request,
        string $shift,
        ReconcileShift $action,
    ): JsonResponse {
        $model = $this->resolveShift($request, $shift);
        $this->authorize('reconcile', $model);

        $updated = $action->handle($model, $request->validated(), $request->user());

        return ApiResponse::data(new ShiftResource($this->loadShift($updated)));
    }

    private function resolveShift(Request $request, string $uuid): Shift
    {
        $device = $this->device($request);
        $shift = Shift::query()
            ->where('uuid', $uuid)
            ->where('business_id', $request->user()->business_id)
            ->where('outlet_id', $device->outlet_id)
            ->first();

        if (! $shift) {
            throw ApiException::notFound('Shift tidak ditemukan.');
        }

        return $shift;
    }

    private function loadShift(Shift $shift): Shift
    {
        return $shift->load([
            'cashier',
            'device',
            'outlet',
            'closingSnapshot',
            'cashMovements.createdBy',
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
