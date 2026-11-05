<?php

namespace App\Services;

use App\Models\Refund;
use App\Models\Sale;
use App\Models\SaleItem;
use App\Models\SalePayment;
use App\Models\Shift;
use App\Models\SyncEvent;
use Carbon\CarbonInterface;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

class DashboardService
{
    public function summary(int $businessId, CarbonInterface $from, CarbonInterface $to, ?int $outletId = null): array
    {
        $baseSales = Sale::query()
            ->where('business_id', $businessId)
            ->when($outletId, fn ($query) => $query->where('outlet_id', $outletId))
            ->whereBetween('transacted_at', [$from, $to]);

        $finalized = (clone $baseSales)->where('lifecycle_status', Sale::LIFECYCLE_FINALIZED);

        $totalFinal = (int) (clone $finalized)->sum('total');
        $countFinal = (clone $finalized)->count();
        $discountTotal = (int) (clone $finalized)->sum('discount_total');
        $paidSales = (clone $finalized)->where('payment_status', Sale::PAYMENT_PAID);
        $paidCount = (clone $paidSales)->count();
        $paidTotal = (int) (clone $paidSales)->sum('total');

        $voided = (clone $baseSales)->where('lifecycle_status', Sale::LIFECYCLE_VOIDED);
        $voidCount = (clone $voided)->count();
        $voidTotal = (int) (clone $voided)->sum('total');

        $refundTotal = (int) Refund::query()
            ->whereBetween('refunded_at', [$from, $to])
            ->whereHas('sale', function ($query) use ($businessId, $outletId) {
                $query->where('business_id', $businessId)
                    ->when($outletId, fn ($q) => $q->where('outlet_id', $outletId));
            })
            ->sum('amount');

        $paymentQuery = SalePayment::query()
            ->whereHas('sale', function ($query) use ($businessId, $outletId, $from, $to) {
                $query->where('business_id', $businessId)
                    ->where('lifecycle_status', Sale::LIFECYCLE_FINALIZED)
                    ->when($outletId, fn ($q) => $q->where('outlet_id', $outletId))
                    ->whereBetween('transacted_at', [$from, $to]);
            });

        $confirmedPayments = (clone $paymentQuery)->where('status', SalePayment::STATUS_CONFIRMED);
        $confirmedPaymentTotal = (int) (clone $confirmedPayments)->sum(DB::raw('COALESCE(verified_amount, amount)'));
        $cashTotal = (int) (clone $confirmedPayments)->where('method', SalePayment::METHOD_CASH)->sum(DB::raw('COALESCE(verified_amount, amount)'));
        $nonCashTotal = (int) (clone $confirmedPayments)->where('method', '!=', SalePayment::METHOD_CASH)->sum(DB::raw('COALESCE(verified_amount, amount)'));
        $awaitingQuery = (clone $paymentQuery)->where('status', SalePayment::STATUS_AWAITING_VERIFICATION);
        $awaitingTotal = (int) (clone $awaitingQuery)->sum('amount');
        $awaitingCount = (clone $awaitingQuery)->count();

        $daily = (clone $finalized)
            ->selectRaw('DATE(transacted_at) as day, SUM(total) as total, COUNT(*) as transactions')
            ->groupBy('day')
            ->orderBy('day')
            ->get()
            ->keyBy(fn ($row) => Carbon::parse($row->day)->toDateString());

        $dailySales = [];
        $cursor = Carbon::parse($from)->startOfDay();
        $end = Carbon::parse($to)->startOfDay();
        while ($cursor->lessThanOrEqualTo($end)) {
            $key = $cursor->toDateString();
            $dailySales[] = [
                'date' => $key,
                'label' => $cursor->translatedFormat('d M'),
                'total' => (int) ($daily[$key]->total ?? 0),
                'transactions' => (int) ($daily[$key]->transactions ?? 0),
            ];
            $cursor->addDay();
        }

        $topProducts = SaleItem::query()
            ->whereHas('sale', function ($query) use ($businessId, $outletId, $from, $to) {
                $query->where('business_id', $businessId)
                    ->where('lifecycle_status', Sale::LIFECYCLE_FINALIZED)
                    ->when($outletId, fn ($q) => $q->where('outlet_id', $outletId))
                    ->whereBetween('transacted_at', [$from, $to]);
            })
            ->select('product_name', DB::raw('SUM(quantity) as quantity'), DB::raw('SUM(total) as revenue'))
            ->groupBy('product_name')
            ->orderByDesc('quantity')
            ->limit(5)
            ->get()
            ->map(fn ($row) => [
                'name' => $row->product_name,
                'quantity' => (int) $row->quantity,
                'revenue' => (int) $row->revenue,
            ])
            ->all();

        $paymentBreakdown = (clone $confirmedPayments)
            ->select('method', DB::raw('SUM(COALESCE(verified_amount, amount)) as total'), DB::raw('COUNT(*) as entries'))
            ->groupBy('method')
            ->get()
            ->map(fn ($row) => [
                'method' => $row->method,
                'total' => (int) $row->total,
                'entries' => (int) $row->entries,
            ])
            ->all();

        $shiftQuery = Shift::query()
            ->where('business_id', $businessId)
            ->when($outletId, fn ($query) => $query->where('outlet_id', $outletId));

        $shiftSummary = [
            'open' => (clone $shiftQuery)->where('status', Shift::STATUS_OPEN)->count(),
            'closed_pending_sync' => (clone $shiftQuery)->where('status', Shift::STATUS_CLOSED_PENDING_SYNC)->count(),
            'closed_confirmed' => (clone $shiftQuery)->where('status', Shift::STATUS_CLOSED_CONFIRMED)->count(),
            'closed_sync_exception' => (clone $shiftQuery)->where('status', Shift::STATUS_CLOSED_SYNC_EXCEPTION)->count(),
            'variance_total' => (int) (clone $shiftQuery)->whereNotNull('variance')->sum('variance'),
        ];

        $pendingSync = SyncEvent::query()
            ->where('business_id', $businessId)
            ->when($outletId, fn ($query) => $query->where('outlet_id', $outletId))
            ->whereNull('processed_at')
            ->count();

        $syncIssues = SyncEvent::query()
            ->where('business_id', $businessId)
            ->when($outletId, fn ($query) => $query->where('outlet_id', $outletId))
            ->whereIn('status', ['conflict', 'rejected', 'blocked_dependency'])
            ->count();

        $lastSync = SyncEvent::query()
            ->where('business_id', $businessId)
            ->when($outletId, fn ($query) => $query->where('outlet_id', $outletId))
            ->whereNotNull('processed_at')
            ->max('processed_at');

        $recentSales = Sale::query()
            ->with(['cashier:id,name', 'outlet:id,name'])
            ->where('business_id', $businessId)
            ->when($outletId, fn ($query) => $query->where('outlet_id', $outletId))
            ->orderByDesc('transacted_at')
            ->limit(8)
            ->get()
            ->map(fn (Sale $sale) => [
                'id' => $sale->id,
                'uuid' => $sale->uuid,
                'receipt_number' => $sale->receipt_number,
                'cashier' => $sale->cashier?->name,
                'total' => $sale->total,
                'payment_status' => $sale->payment_status,
                'lifecycle_status' => $sale->lifecycle_status,
                'transacted_at' => $sale->transacted_at?->toIso8601String(),
            ])
            ->all();

        $recentPendingPayments = SalePayment::query()
            ->with(['sale:id,receipt_number,total', 'recordedBy:id,name'])
            ->where('status', SalePayment::STATUS_AWAITING_VERIFICATION)
            ->whereHas('sale', function ($query) use ($businessId, $outletId) {
                $query->where('business_id', $businessId)
                    ->when($outletId, fn ($q) => $q->where('outlet_id', $outletId));
            })
            ->orderBy('recorded_at')
            ->limit(5)
            ->get()
            ->map(fn (SalePayment $payment) => [
                'id' => $payment->id,
                'sale_id' => $payment->sale_id,
                'receipt_number' => $payment->sale?->receipt_number,
                'method' => $payment->method,
                'amount' => $payment->amount,
                'recorded_by' => $payment->recordedBy?->name,
                'recorded_at' => $payment->recorded_at?->toIso8601String(),
            ])
            ->all();

        return [
            'period' => [
                'from' => Carbon::parse($from)->toDateString(),
                'to' => Carbon::parse($to)->toDateString(),
            ],
            'metrics' => [
                'total_final' => $totalFinal,
                'total_final_count' => $countFinal,
                'payments_received' => $confirmedPaymentTotal,
                'paid_total' => $paidTotal,
                'paid_count' => $paidCount,
                'cash_total' => $cashTotal,
                'non_cash_total' => $nonCashTotal,
                'awaiting_total' => $awaitingTotal,
                'awaiting_count' => $awaitingCount,
                'discount_total' => $discountTotal,
                'void_total' => $voidTotal,
                'void_count' => $voidCount,
                'refund_total' => $refundTotal,
                'average_transaction' => $paidCount > 0 ? (int) round($paidTotal / $paidCount) : 0,
                'outstanding_total' => max((int) (clone $finalized)->sum('outstanding_amount'), 0),
            ],
            'daily_sales' => $dailySales,
            'top_products' => $topProducts,
            'payment_breakdown' => $paymentBreakdown,
            'shift_summary' => $shiftSummary,
            'sync' => [
                'pending' => $pendingSync,
                'issues' => $syncIssues,
                'last_processed_at' => $lastSync,
            ],
            'recent_sales' => $recentSales,
            'recent_pending_payments' => $recentPendingPayments,
        ];
    }
}
