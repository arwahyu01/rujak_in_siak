<?php

namespace App\Http\Controllers;

use App\Models\AuditLog;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Inertia\Inertia;
use Inertia\Response;

class AuditLogController extends Controller
{
    public function index(Request $request): Response
    {
        $businessId = $request->user()->business_id;
        $search = trim((string) $request->query('q'));

        $query = AuditLog::query()
            ->with('user:id,name')
            ->where('business_id', $businessId)
            ->when($search !== '', fn ($q) => $q->where(function ($inner) use ($search) {
                $inner->where('description', 'like', "%{$search}%")
                    ->orWhere('action', 'like', "%{$search}%")
                    ->orWhere('auditable_id', 'like', "%{$search}%");
            }))
            ->when($request->query('module'), fn ($q, $module) => $q->where('module', $module))
            ->when($request->query('user_id'), fn ($q, $userId) => $q->where('user_id', $userId))
            ->when($request->query('date_from'), fn ($q, $date) => $q->where('created_at', '>=', Carbon::parse($date)->startOfDay()))
            ->when($request->query('date_to'), fn ($q, $date) => $q->where('created_at', '<=', Carbon::parse($date)->endOfDay()));

        return Inertia::render('Audit/Index', [
            'logs' => $query->orderByDesc('created_at')->paginate(25)->withQueryString(),
            'modules' => AuditLog::query()
                ->where('business_id', $businessId)
                ->distinct()
                ->orderBy('module')
                ->pluck('module'),
            'users' => User::query()->where('business_id', $businessId)->orderBy('name')->get(['id', 'name']),
            'filters' => $request->only(['q', 'module', 'user_id', 'date_from', 'date_to']),
        ]);
    }
}
