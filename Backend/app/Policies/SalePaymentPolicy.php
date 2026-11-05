<?php

namespace App\Policies;

use App\Models\SalePayment;
use App\Models\User;

class SalePaymentPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->hasPermission('payments.view_pending');
    }

    public function view(User $user, SalePayment $payment): bool
    {
        return $user->hasPermission('payments.view_pending')
            && $user->business_id === $payment->sale?->business_id;
    }

    public function verify(User $user, SalePayment $payment): bool
    {
        return $user->hasPermission('payments.verify')
            && $user->business_id === $payment->sale?->business_id
            && (int) $payment->recorded_by !== (int) $user->id
            && $payment->status === SalePayment::STATUS_AWAITING_VERIFICATION;
    }

    public function reject(User $user, SalePayment $payment): bool
    {
        return $user->hasPermission('payments.reject')
            && $user->business_id === $payment->sale?->business_id
            && (int) $payment->recorded_by !== (int) $user->id
            && $payment->status === SalePayment::STATUS_AWAITING_VERIFICATION;
    }
}
