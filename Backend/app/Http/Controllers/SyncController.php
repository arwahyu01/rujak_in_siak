<?php

namespace App\Http\Controllers;

use App\Models\SyncEvent;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Inertia\Response;

class SyncController extends Controller
{
    public function index(Request $request): Response
    {
        $businessId = $request->user()->business_id;
        $query = SyncEvent::query()
            ->with(['outlet:id,name', 'device:id,name,terminal_code'])
            ->where('business_id', $businessId)
            ->when($request->query('status'), fn ($q, $status) => $q->where('status', $status))
            ->when($request->query('event_type'), fn ($q, $type) => $q->where('event_type', $type))
            ->when(trim((string) $request->query('q')) !== '', function ($q) use ($request) {
                $search = trim((string) $request->query('q'));
                $q->where(function ($inner) use ($search) {
                    $inner->where('aggregate_id', 'like', "%{$search}%")
                        ->orWhere('event_id', 'like', "%{$search}%");
                });
            });

        $byStatus = SyncEvent::query()
            ->where('business_id', $businessId)
            ->selectRaw('status, COUNT(*) as total')
            ->groupBy('status')
            ->pluck('total', 'status');

        return Inertia::render('Sync/Index', [
            'events' => $query->orderByDesc('created_at')->paginate(20)->withQueryString(),
            'summary' => [
                'total' => SyncEvent::query()->where('business_id', $businessId)->count(),
                'pending' => SyncEvent::query()
                    ->where('business_id', $businessId)
                    ->whereIn('status', ['pending', 'blocked_dependency'])
                    ->count(),
                'issues' => SyncEvent::query()
                    ->where('business_id', $businessId)
                    ->whereIn('status', ['conflict', 'rejected', 'upgrade_required'])
                    ->count(),
                'by_status' => $byStatus,
                'last_processed_at' => SyncEvent::query()->where('business_id', $businessId)->max('processed_at'),
            ],
            'eventTypes' => SyncEvent::query()
                ->where('business_id', $businessId)
                ->distinct()
                ->orderBy('event_type')
                ->pluck('event_type'),
            'filters' => $request->only(['q', 'status', 'event_type']),
        ]);
    }
}
