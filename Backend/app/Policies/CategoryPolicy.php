<?php

namespace App\Policies;

use App\Models\Category;
use App\Models\User;

class CategoryPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->hasPermission('categories.view');
    }

    public function view(User $user, Category $category): bool
    {
        return $user->hasPermission('categories.view') && $user->business_id === $category->business_id;
    }

    public function create(User $user): bool
    {
        return $user->hasPermission('categories.manage');
    }

    public function update(User $user, Category $category): bool
    {
        return $user->hasPermission('categories.manage') && $user->business_id === $category->business_id;
    }

    public function delete(User $user, Category $category): bool
    {
        return $this->update($user, $category);
    }
}
