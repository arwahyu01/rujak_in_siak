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
}
