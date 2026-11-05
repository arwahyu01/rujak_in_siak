<?php

namespace App\Services;

use App\Models\Sale;
use App\Models\SaleItem;
use App\Models\SalePayment;
use App\Models\Shift;
use Carbon\CarbonInterface;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

class ReportService
{
    public function sales(int $businessId, CarbonInterface $from, CarbonInterface $to, ?int $outletId = null): array
    {
        $query = Sale::query()
            ->where('sales.business_id', $businessId)
            ->when($outletId, fn ($q) => $q->where('sales.outlet_id', $outletId))
            ->whereBetween('sales.transacted_at', [$from, $to]);

        $finalized = (clone $query)->where('sales.lifecycle_status', Sale::LIFECYCLE_FINALIZED);

        $daily = (clone $finalized)
            ->selectRaw('DATE(transacted_at) as day, COUNT(*) as transactions, SUM(total) as total, SUM(discount_total) as discounts, SUM(tax_total) as tax, SUM(service_charge) as service_charge')
            ->groupBy('day')
            ->orderBy('day')
            ->get()
            ->map(fn ($row) => [
                'date' => Carbon::parse($row->day)->toDateString(),
                'transactions' => (int) $row->transactions,
                'total' => (int) $row->total,
                'discounts' => (int) $row->discounts,
                'tax' => (int) $row->tax,
                'service_charge' => (int) $row->service_charge,
            ])
            ->all();

        $byCashier = (clone $finalized)
            ->join('users', 'users.id', '=', 'sales.user_id')
            ->select('users.name', DB::raw('COUNT(*) as transactions'), DB::raw('SUM(sales.total) as total'))
            ->groupBy('users.name')
            ->orderByDesc('total')
            ->get()
            ->map(fn ($row) => [
                'name' => $row->name,
                'transactions' => (int) $row->transactions,
                'total' => (int) $row->total,
            ])
            ->all();

        $byOrderType = (clone $finalized)
            ->select('order_type', DB::raw('COUNT(*) as transactions'), DB::raw('SUM(total) as total'))
            ->groupBy('order_type')
            ->get()
            ->map(fn ($row) => [
                'order_type' => $row->order_type,
                'transactions' => (int) $row->transactions,
                'total' => (int) $row->total,
            ])
            ->all();

        return [
            'summary' => [
                'transactions' => (clone $finalized)->count(),
                'total' => (int) (clone $finalized)->sum('total'),
                'discounts' => (int) (clone $finalized)->sum('discount_total'),
                'tax' => (int) (clone $finalized)->sum('tax_total'),
                'service_charge' => (int) (clone $finalized)->sum('service_charge'),
                'voided_transactions' => (clone $query)->where('sales.lifecycle_status', Sale::LIFECYCLE_VOIDED)->count(),
                'voided_total' => (int) (clone $query)->where('sales.lifecycle_status', Sale::LIFECYCLE_VOIDED)->sum('total'),
            ],
            'daily' => $daily,
            'by_cashier' => $byCashier,
            'by_order_type' => $byOrderType,
        ];
    }

    public function payments(int $businessId, CarbonInterface $from, CarbonInterface $to, ?int $outletId = null): array
    {
        $query = SalePayment::query()
            ->with(['sale:id,receipt_number,total,payment_status,lifecycle_status,transacted_at', 'recordedBy:id,name', 'verifiedBy:id,name'])
            ->whereHas('sale', function ($q) use ($businessId, $outletId, $from, $to) {
                $q->where('business_id', $businessId)
                    ->when($outletId, fn ($x) => $x->where('outlet_id', $outletId))
                    ->whereBetween('transacted_at', [$from, $to]);
            });

        $byMethod = (clone $query)
            ->select('method', DB::raw('COUNT(*) as entries'), DB::raw('SUM(amount) as recorded'), DB::raw("SUM(CASE WHEN status = 'confirmed' THEN COALESCE(verified_amount, amount) ELSE 0 END) as confirmed"))
            ->groupBy('method')
            ->get()
            ->map(fn ($row) => [
                'method' => $row->method,
                'entries' => (int) $row->entries,
                'recorded' => (int) $row->recorded,
                'confirmed' => (int) $row->confirmed,
            ])
            ->all();

        $statuses = (clone $query)
            ->select('status', DB::raw('COUNT(*) as entries'), DB::raw('SUM(amount) as total'))
            ->groupBy('status')
            ->get()
            ->map(fn ($row) => [
                'status' => $row->status,
                'entries' => (int) $row->entries,
                'total' => (int) $row->total,
            ])
            ->all();

        $rows = (clone $query)->orderByDesc('recorded_at')->limit(200)->get()->map(fn (SalePayment $payment) => [
            'id' => $payment->id,
            'receipt_number' => $payment->sale?->receipt_number,
            'sale_id' => $payment->sale_id,
            'method' => $payment->method,
            'amount' => $payment->amount,
            'verified_amount' => $payment->verified_amount,
            'status' => $payment->status,
            'provider_reference' => $payment->provider_reference,
            'recorded_by' => $payment->recordedBy?->name,
            'verified_by' => $payment->verifiedBy?->name,
            'recorded_at' => $payment->recorded_at?->toIso8601String(),
        ])->all();

        return [
            'by_method' => $byMethod,
            'by_status' => $statuses,
            'rows' => $rows,
        ];
    }

    public function products(int $businessId, CarbonInterface $from, CarbonInterface $to, ?int $outletId = null): array
    {
        $query = SaleItem::query()
            ->whereHas('sale', function ($q) use ($businessId, $outletId, $from, $to) {
                $q->where('business_id', $businessId)
                    ->where('lifecycle_status', Sale::LIFECYCLE_FINALIZED)
                    ->when($outletId, fn ($x) => $x->where('outlet_id', $outletId))
                    ->whereBetween('transacted_at', [$from, $to]);
            });

        $rows = (clone $query)
            ->select('product_name', 'sku', DB::raw('SUM(quantity) as quantity'), DB::raw('SUM(subtotal) as gross'), DB::raw('SUM(discount_amount) as discounts'), DB::raw('SUM(total) as total'))
            ->groupBy('product_name', 'sku')
            ->orderByDesc('quantity')
            ->limit(200)
            ->get()
            ->map(fn ($row) => [
                'name' => $row->product_name,
                'sku' => $row->sku,
                'quantity' => (int) $row->quantity,
                'gross' => (int) $row->gross,
                'discounts' => (int) $row->discounts,
                'total' => (int) $row->total,
            ])
            ->all();

        return [
            'rows' => $rows,
            'summary' => [
                'products_sold' => array_sum(array_column($rows, 'quantity')),
                'revenue' => array_sum(array_column($rows, 'total')),
            ],
        ];
    }

    public function shifts(int $businessId, CarbonInterface $from, CarbonInterface $to, ?int $outletId = null): array
    {
        $rows = Shift::query()
            ->with(['cashier:id,name', 'outlet:id,name', 'approvedBy:id,name'])
            ->where('business_id', $businessId)
            ->when($outletId, fn ($q) => $q->where('outlet_id', $outletId))
            ->whereBetween('opened_at', [$from, $to])
            ->orderByDesc('opened_at')
            ->limit(200)
            ->get()
            ->map(fn (Shift $shift) => [
                'id' => $shift->id,
                'cashier' => $shift->cashier?->name,
                'outlet' => $shift->outlet?->name,
                'status' => $shift->status,
                'opening_cash' => $shift->opening_cash,
                'expected_cash' => $shift->expected_cash,
                'actual_cash' => $shift->actual_cash,
                'variance' => $shift->variance,
                'confirmed_noncash' => $shift->confirmed_noncash,
                'awaiting_verification_amount' => $shift->awaiting_verification_amount,
                'pending_sync_count' => $shift->pending_sync_count,
                'opened_at' => $shift->opened_at?->toIso8601String(),
                'closed_at' => $shift->closed_at?->toIso8601String(),
                'approved_by' => $shift->approvedBy?->name,
            ])
            ->all();

        return [
            'rows' => $rows,
            'summary' => [
                'shifts' => count($rows),
                'variance' => array_sum(array_map(fn ($row) => (int) ($row['variance'] ?? 0), $rows)),
                'pending_sync' => array_sum(array_column($rows, 'pending_sync_count')),
            ],
        ];
    }

    public function exportRows(string $type, int $businessId, CarbonInterface $from, CarbonInterface $to, ?int $outletId = null): array
    {
        return match ($type) {
            'sales' => $this->salesExportRows($businessId, $from, $to, $outletId),
            'payments' => $this->paymentsExportRows($businessId, $from, $to, $outletId),
            'products' => $this->products($businessId, $from, $to, $outletId)['rows'],
            'shifts' => $this->shifts($businessId, $from, $to, $outletId)['rows'],
            default => [],
        };
    }

    private function salesExportRows(int $businessId, CarbonInterface $from, CarbonInterface $to, ?int $outletId): array
    {
        return Sale::query()
            ->with('cashier:id,name')
            ->where('business_id', $businessId)
            ->when($outletId, fn ($q) => $q->where('outlet_id', $outletId))
            ->whereBetween('transacted_at', [$from, $to])
            ->orderBy('transacted_at')
            ->get()
            ->map(fn (Sale $sale) => [
                'receipt_number' => $sale->receipt_number,
                'transacted_at' => $sale->transacted_at?->format('Y-m-d H:i:s'),
                'cashier' => $sale->cashier?->name,
                'order_type' => $sale->order_type,
                'table_number' => $sale->table_number,
                'subtotal' => $sale->subtotal,
                'discount_total' => $sale->discount_total,
                'service_charge' => $sale->service_charge,
                'tax_total' => $sale->tax_total,
                'total' => $sale->total,
                'payment_status' => $sale->payment_status,
                'lifecycle_status' => $sale->lifecycle_status,
            ])
            ->all();
    }

    private function paymentsExportRows(int $businessId, CarbonInterface $from, CarbonInterface $to, ?int $outletId): array
    {
        return SalePayment::query()
            ->with(['sale:id,receipt_number', 'recordedBy:id,name', 'verifiedBy:id,name'])
            ->whereHas('sale', function ($q) use ($businessId, $outletId, $from, $to) {
                $q->where('business_id', $businessId)
                    ->when($outletId, fn ($x) => $x->where('outlet_id', $outletId))
                    ->whereBetween('transacted_at', [$from, $to]);
            })
            ->orderBy('recorded_at')
            ->get()
            ->map(fn (SalePayment $payment) => [
                'receipt_number' => $payment->sale?->receipt_number,
                'method' => $payment->method,
                'amount' => $payment->amount,
                'verified_amount' => $payment->verified_amount,
                'status' => $payment->status,
                'provider_reference' => $payment->provider_reference,
                'recorded_by' => $payment->recordedBy?->name,
                'verified_by' => $payment->verifiedBy?->name,
                'recorded_at' => $payment->recorded_at?->format('Y-m-d H:i:s'),
            ])
            ->all();
    }
}
