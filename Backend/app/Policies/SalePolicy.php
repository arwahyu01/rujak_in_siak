<?php

namespace App\Policies;

use App\Models\Sale;
use App\Models\User;

class SalePolicy
{
    public function viewAny(User $user): bool
    {
        return $user->hasPermission('sales.view');
    }

    public function view(User $user, Sale $sale): bool
    {
        return $user->hasPermission('sales.view') && $user->business_id === $sale->business_id;
    }

    public function void(User $user, Sale $sale): bool
    {
        return $user->hasPermission('sales.void') && $user->business_id === $sale->business_id;
    }

    public function refund(User $user, Sale $sale): bool
    {
        return $user->hasPermission('sales.refund') && $user->business_id === $sale->business_id;
    }
}
