<?php

namespace App\Services;

use App\Models\Refund;
use App\Models\Sale;
use App\Models\SalePayment;
use App\Models\Shift;
use Illuminate\Support\Facades\DB;

class ShiftSummaryService
{
    public function calculate(Shift $shift): array
    {
        $sales = Sale::query()
            ->where('shift_id', $shift->id)
            ->where('lifecycle_status', Sale::LIFECYCLE_FINALIZED);

        $cashTendered = (int) SalePayment::query()
            ->whereHas('sale', fn ($query) => $query
                ->where('shift_id', $shift->id)
                ->where('lifecycle_status', Sale::LIFECYCLE_FINALIZED))
            ->where('method', SalePayment::METHOD_CASH)
            ->where('status', SalePayment::STATUS_CONFIRMED)
            ->sum(DB::raw('COALESCE(tendered_amount, verified_amount, amount)'));

        $cashChange = (int) SalePayment::query()
            ->whereHas('sale', fn ($query) => $query
                ->where('shift_id', $shift->id)
                ->where('lifecycle_status', Sale::LIFECYCLE_FINALIZED))
            ->where('method', SalePayment::METHOD_CASH)
            ->where('status', SalePayment::STATUS_CONFIRMED)
            ->sum('change_amount');

        $confirmedNonCash = (int) SalePayment::query()
            ->whereHas('sale', fn ($query) => $query
                ->where('shift_id', $shift->id)
                ->where('lifecycle_status', Sale::LIFECYCLE_FINALIZED))
            ->where('method', '!=', SalePayment::METHOD_CASH)
            ->where('status', SalePayment::STATUS_CONFIRMED)
            ->sum(DB::raw('COALESCE(verified_amount, amount)'));

        $awaiting = (int) SalePayment::query()
            ->whereHas('sale', fn ($query) => $query
                ->where('shift_id', $shift->id)
                ->where('lifecycle_status', Sale::LIFECYCLE_FINALIZED))
            ->where('status', SalePayment::STATUS_AWAITING_VERIFICATION)
            ->sum('amount');

        $cashRefund = (int) Refund::query()
            ->whereHas('sale', fn ($query) => $query->where('shift_id', $shift->id))
            ->where('method', SalePayment::METHOD_CASH)
            ->sum('amount');

        $cashIn = (int) $shift->cashMovements()->where('type', 'in')->sum('amount');
        $cashOut = (int) $shift->cashMovements()->where('type', 'out')->sum('amount');

        $expectedCash = (int) $shift->opening_cash
            + $cashTendered
            - $cashChange
            + $cashIn
            - $cashOut
            - $cashRefund;

        return [
            'opening_cash' => (int) $shift->opening_cash,
            'cash_tendered' => $cashTendered,
            'cash_change' => $cashChange,
            'cash_in' => $cashIn,
            'cash_out' => $cashOut,
            'cash_refund' => $cashRefund,
            'expected_cash' => $expectedCash,
            'confirmed_noncash' => $confirmedNonCash,
            'awaiting_verification_amount' => $awaiting,
            'local_transaction_count' => (clone $sales)->count(),
            'sale_total' => (int) (clone $sales)->sum('total'),
            'confirmed_amount' => (int) (clone $sales)->sum('confirmed_amount'),
            'refunded_amount' => (int) (clone $sales)->sum('refunded_amount'),
        ];
    }
}
