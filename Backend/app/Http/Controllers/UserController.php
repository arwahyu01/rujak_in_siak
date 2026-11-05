<?php

namespace App\Http\Controllers;

use App\Actions\Users\SaveUser;
use App\Http\Requests\Users\StoreUserRequest;
use App\Http\Requests\Users\UpdateUserRequest;
use App\Models\Outlet;
use App\Models\Role;
use App\Models\User;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Inertia\Response;

class UserController extends Controller
{
    public function index(Request $request): Response
    {
        $this->authorize('viewAny', User::class);

        $businessId = $request->user()->business_id;
        $search = trim((string) $request->query('q'));
        $roleId = $request->query('role_id');
        $status = (string) $request->query('status', 'all');

        $users = User::query()
            ->where('business_id', $businessId)
            ->with(['roles:id,name,slug', 'outlet:id,name'])
            ->when($search !== '', fn ($query) => $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                    ->orWhere('email', 'like', "%{$search}%")
                    ->orWhere('username', 'like', "%{$search}%");
            }))
            ->when($roleId, fn ($query) => $query->whereHas('roles', fn ($q) => $q->where('roles.id', $roleId)))
            ->when($status === 'active', fn ($query) => $query->where('is_active', true))
            ->when($status === 'inactive', fn ($query) => $query->where('is_active', false))
            ->orderBy('name')
            ->paginate(15)
            ->withQueryString();

        return Inertia::render('Users/Index', [
            'users' => $users,
            'roles' => Role::query()->orderBy('name')->get(['id', 'name', 'slug']),
            'outlets' => Outlet::query()->where('business_id', $businessId)->orderBy('name')->get(['id', 'name']),
            'filters' => [
                'q' => $search,
                'role_id' => $roleId,
                'status' => $status,
            ],
            'canManage' => $request->user()->hasPermission('users.manage'),
        ]);
    }

    public function store(StoreUserRequest $request, SaveUser $action): RedirectResponse
    {
        $this->authorize('create', User::class);

        $action->handle($request->validated(), $request->user());

        return back()->with('success', 'Pengguna berhasil dibuat.');
    }

    public function update(UpdateUserRequest $request, User $user, SaveUser $action): RedirectResponse
    {
        $this->authorize('update', $user);

        $action->handle($request->validated(), $request->user(), $user);

        return back()->with('success', 'Pengguna berhasil diperbarui.');
    }
}
