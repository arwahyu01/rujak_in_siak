<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\SyncPushRequest;
use App\Models\Category;
use App\Models\Device;
use App\Models\Product;
use App\Models\SyncCursor;
use App\Models\SyncEvent;
use App\Models\SyncLog;
use App\Services\SyncBootstrapService;
use App\Services\SyncPullService;
use App\Services\SyncPushService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;

class SyncController extends Controller
{
    public function push(SyncPushRequest $request, SyncPushService $push): JsonResponse
    {
        $result = $push->push(
            $request->validated(),
            $request->user(),
            $this->device($request),
        );

        return ApiResponse::data($result);
    }

    public function pull(Request $request, SyncPullService $pull): JsonResponse
    {
        $limit = $request->filled('limit') ? (int) $request->query('limit') : null;

        return ApiResponse::data($pull->pull(
            $request->user(),
            $this->device($request),
            $request->query('cursor'),
            $limit,
        ));
    }

    public function bootstrap(Request $request, SyncBootstrapService $bootstrap): JsonResponse
    {
        return ApiResponse::data($bootstrap->bootstrap(
            $request->user(),
            $this->device($request),
        ));
    }

    public function status(Request $request): JsonResponse
    {
        $user = $request->user();
        $device = $this->device($request);
        $cursor = SyncCursor::query()->where('device_id', $device->id)->first();
        $lastLog = SyncLog::query()
            ->where('device_id', $device->id)
            ->latest('received_at')
            ->first();

        $counts = SyncEvent::query()
            ->where('device_id', $device->id)
            ->selectRaw('status, COUNT(*) as total')
            ->groupBy('status')
            ->pluck('total', 'status');

        $catalogVersion = collect([
            Product::query()->where('business_id', $user->business_id)->max('updated_at'),
            Category::query()->where('business_id', $user->business_id)->max('updated_at'),
        ])->filter()->max();

        return ApiResponse::data([
            'device' => [
                'uuid' => $device->uuid,
                'status' => $device->status,
                'last_sequence' => (int) $device->last_sequence,
                'last_seen_at' => $device->last_seen_at?->toIso8601String(),
            ],
            'sync' => [
                'protocol_version' => SyncPushService::PROTOCOL_VERSION,
                'schema_version' => SyncPushService::SCHEMA_VERSION,
                'last_event_id' => (int) ($cursor?->last_event_id ?? 0),
                'last_pulled_at' => $cursor?->last_pulled_at?->toIso8601String(),
                'last_push_at' => $lastLog?->received_at?->toIso8601String(),
                'pending' => (int) (($counts['pending'] ?? 0) + ($counts['blocked_dependency'] ?? 0)),
                'conflicts' => (int) ($counts['conflict'] ?? 0),
                'rejected' => (int) ($counts['rejected'] ?? 0),
                'upgrade_required' => (int) ($counts['upgrade_required'] ?? 0),
            ],
            'catalog_version' => $catalogVersion ? Carbon::parse($catalogVersion)->toIso8601String() : null,
            'server_time' => now()->toIso8601String(),
        ]);
    }

    private function device(Request $request): Device
    {
        return $request->attributes->get('api_device');
    }
}
