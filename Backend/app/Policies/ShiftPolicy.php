<?php

namespace App\Policies;

use App\Models\Shift;
use App\Models\User;

class ShiftPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->hasPermission('shifts.view');
    }

    public function view(User $user, Shift $shift): bool
    {
        return $user->hasPermission('shifts.view') && $user->business_id === $shift->business_id;
    }

    public function create(User $user): bool
    {
        return $user->hasPermission('shifts.manage');
    }

    public function manage(User $user, ?Shift $shift = null): bool
    {
        return $user->hasPermission('shifts.manage')
            && (! $shift || $user->business_id === $shift->business_id);
    }

    public function reconcile(User $user, Shift $shift): bool
    {
        return $user->hasPermission('shifts.reconcile') && $user->business_id === $shift->business_id;
    }
}
