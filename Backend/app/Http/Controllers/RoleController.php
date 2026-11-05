<?php

namespace App\Http\Controllers;

use App\Actions\Users\SaveRole;
use App\Http\Requests\Users\UpdateRoleRequest;
use App\Models\Permission;
use App\Models\Role;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Inertia\Response;

class RoleController extends Controller
{
    public function index(Request $request): Response
    {
        $this->authorize('viewAny', Role::class);

        $roles = Role::query()
            ->with('permissions:id,name,slug,module')
            ->withCount('users')
            ->orderByRaw("CASE slug WHEN 'owner' THEN 0 WHEN 'admin' THEN 1 WHEN 'supervisor' THEN 2 ELSE 3 END")
            ->get();

        $permissions = Permission::query()->orderBy('module')->orderBy('name')->get();
        $groups = $permissions->groupBy('module')->map(fn ($items, $module) => [
            'module' => $module,
            'label' => match ($module) {
                'dashboard' => 'Dashboard',
                'categories' => 'Kategori',
                'products' => 'Produk',
                'sales' => 'Transaksi',
                'payments' => 'Pembayaran',
                'shifts' => 'Shift',
                'reports' => 'Laporan',
                'users' => 'Pengguna',
                'roles' => 'Peran & Hak Akses',
                'audit' => 'Audit Log',
                'sync' => 'Sinkronisasi',
                'admin' => 'Akses Web',
                default => ucfirst($module),
            },
            'permissions' => $items->map->only(['id', 'name', 'slug'])->values(),
        ])->values();

        return Inertia::render('Roles/Index', [
            'roles' => $roles,
            'permissionGroups' => $groups,
        ]);
    }

    public function update(UpdateRoleRequest $request, Role $role, SaveRole $action): RedirectResponse
    {
        $this->authorize('update', $role);

        $action->handle($role, $request->validated(), $request->user());

        return back()->with('success', 'Hak akses peran diperbarui.');
    }
}
