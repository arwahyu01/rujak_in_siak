<?php

namespace App\Services;

use App\Models\Sale;
use App\Models\SalePayment;
use Illuminate\Support\Facades\DB;

class SalePaymentAggregator
{
    public function recalculate(Sale $sale): Sale
    {
        $sale->refresh();

        $confirmed = (int) $sale->payments()
            ->where('status', SalePayment::STATUS_CONFIRMED)
            ->sum(DB::raw('COALESCE(verified_amount, amount)'));

        $awaiting = (int) $sale->payments()
            ->where('status', SalePayment::STATUS_AWAITING_VERIFICATION)
            ->sum('amount');

        $refunded = (int) $sale->refunds()->sum('amount');
        $netConfirmed = max($confirmed - $refunded, 0);
        $outstanding = max((int) $sale->total - $netConfirmed, 0);

        if ($sale->lifecycle_status === Sale::LIFECYCLE_VOIDED) {
            $status = Sale::PAYMENT_CANCELLED;
        } elseif ($refunded > 0) {
            if ($confirmed <= $refunded) {
                $status = Sale::PAYMENT_REFUNDED;
            } elseif ($netConfirmed < (int) $sale->total) {
                $status = Sale::PAYMENT_PARTIALLY_REFUNDED;
            } else {
                $status = Sale::PAYMENT_PAID;
            }
        } elseif ((int) $sale->total === 0 || $confirmed >= (int) $sale->total) {
            $status = Sale::PAYMENT_PAID;
        } elseif ($awaiting > 0 && $confirmed < (int) $sale->total) {
            $status = Sale::PAYMENT_AWAITING_VERIFICATION;
        } elseif ($confirmed > 0) {
            $status = Sale::PAYMENT_PARTIALLY_PAID;
        } else {
            $status = Sale::PAYMENT_UNPAID;
        }

        $sale->forceFill([
            'confirmed_amount' => $confirmed,
            'awaiting_verification_amount' => $awaiting,
            'outstanding_amount' => $outstanding,
            'refunded_amount' => $refunded,
            'payment_status' => $status,
        ])->save();

        return $sale->refresh();
    }
}
