<?php

namespace App\Actions\Users;

use App\Models\Permission;
use App\Models\Role;
use App\Models\User;
use App\Services\AuditLogger;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class SaveRole
{
    public function __construct(private readonly AuditLogger $audit)
    {
    }

    public function handle(Role $role, array $data, User $actor): Role
    {
        if ($role->slug === 'owner') {
            throw ValidationException::withMessages([
                'role' => 'Peran Owner selalu memiliki seluruh permission dan tidak dapat diubah.',
            ]);
        }

        return DB::transaction(function () use ($role, $data, $actor) {
            $oldPermissions = $role->permissions()->pluck('slug')->all();
            $permissions = Permission::query()
                ->whereIn('id', $data['permissions'] ?? [])
                ->get(['id', 'slug']);
            $permissionIds = $permissions->pluck('id')->all();

            if (! $permissions->contains('slug', 'admin.access') && $role->users()->where('is_active', true)->exists()) {
                throw ValidationException::withMessages([
                    'permissions' => 'Permission akses web tidak boleh dilepas selama peran masih dipakai pengguna aktif. Nonaktifkan atau pindahkan pengguna terlebih dahulu.',
                ]);
            }

            $role->update([
                'name' => $data['name'] ?? $role->name,
                'description' => $data['description'] ?? $role->description,
            ]);
            $role->permissions()->sync($permissionIds);

            $this->audit->record(
                'role.updated',
                'roles',
                'Memperbarui hak akses peran '.$role->name,
                $role,
                ['permissions' => $oldPermissions],
                ['permissions' => $role->permissions()->pluck('slug')->all()],
                $actor,
                $actor->business_id,
            );

            return $role->refresh()->load('permissions');
        });
    }
}
