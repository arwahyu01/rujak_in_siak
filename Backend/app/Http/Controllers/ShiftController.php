<?php

namespace App\Http\Controllers;

use App\Models\Sale;
use App\Models\SalePayment;
use App\Models\Shift;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Inertia\Inertia;
use Inertia\Response;

class ShiftController extends Controller
{
    public function index(Request $request): Response
    {
        $this->authorize('viewAny', Shift::class);

        $businessId = $request->user()->business_id;
        $query = Shift::query()
            ->with(['cashier:id,name', 'outlet:id,name', 'device:id,name,terminal_code'])
            ->withCount('sales')
            ->where('business_id', $businessId)
            ->when($request->query('status'), fn ($q, $status) => $q->where('status', $status))
            ->when($request->query('date_from'), fn ($q, $date) => $q->where('opened_at', '>=', Carbon::parse($date)->startOfDay()))
            ->when($request->query('date_to'), fn ($q, $date) => $q->where('opened_at', '<=', Carbon::parse($date)->endOfDay()));

        $summary = [
            'open' => (clone $query)->where('status', Shift::STATUS_OPEN)->count(),
            'pending_sync' => (clone $query)->where('status', Shift::STATUS_CLOSED_PENDING_SYNC)->count(),
            'exception' => (clone $query)->where('status', Shift::STATUS_CLOSED_SYNC_EXCEPTION)->count(),
            'variance' => (int) (clone $query)->whereNotNull('variance')->sum('variance'),
        ];

        return Inertia::render('Shifts/Index', [
            'shifts' => $query->orderByDesc('opened_at')->paginate(15)->withQueryString(),
            'summary' => $summary,
            'filters' => $request->only(['status', 'date_from', 'date_to']),
        ]);
    }

    public function show(Request $request, Shift $shift): Response
    {
        $this->authorize('view', $shift);

        $shift->load([
            'cashier:id,name,email',
            'outlet:id,name,code',
            'device:id,name,terminal_code',
            'approvedBy:id,name',
            'cashMovements.createdBy:id,name',
            'sales' => fn ($query) => $query->with('cashier:id,name')->orderByDesc('transacted_at')->limit(100),
        ]);

        $salesQuery = Sale::query()->where('shift_id', $shift->id);
        $payments = SalePayment::query()
            ->whereHas('sale', fn ($query) => $query->where('shift_id', $shift->id));

        $summary = [
            'sales_count' => (clone $salesQuery)->where('lifecycle_status', Sale::LIFECYCLE_FINALIZED)->count(),
            'sales_total' => (int) (clone $salesQuery)->where('lifecycle_status', Sale::LIFECYCLE_FINALIZED)->sum('total'),
            'void_count' => (clone $salesQuery)->where('lifecycle_status', Sale::LIFECYCLE_VOIDED)->count(),
            'cash_confirmed' => (int) (clone $payments)->where('method', SalePayment::METHOD_CASH)->where('status', SalePayment::STATUS_CONFIRMED)->sum(DB::raw('COALESCE(verified_amount, amount)')),
            'noncash_confirmed' => (int) (clone $payments)->where('method', '!=', SalePayment::METHOD_CASH)->where('status', SalePayment::STATUS_CONFIRMED)->sum(DB::raw('COALESCE(verified_amount, amount)')),
            'awaiting' => (int) (clone $payments)->where('status', SalePayment::STATUS_AWAITING_VERIFICATION)->sum('amount'),
        ];

        return Inertia::render('Shifts/Show', [
            'shift' => $shift,
            'summary' => $summary,
        ]);
    }
}
