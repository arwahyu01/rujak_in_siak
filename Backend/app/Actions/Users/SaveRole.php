<?php

namespace App\Actions\Users;

use App\Models\AuthorizationLease;
use App\Models\Permission;
use App\Models\Role;
use App\Models\User;
use App\Services\AuditLogger;
use App\Services\SyncRecorder;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class SaveRole
{
    public function __construct(
        private readonly AuditLogger $audit,
        private readonly SyncRecorder $sync,
    ) {}

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

            $this->invalidateUsers($role);

            return $role->refresh()->load('permissions');
        });
    }

    private function invalidateUsers(Role $role): void
    {
        $role->users()->get()->each(function (User $user) {
            $user->bumpAuthVersion();

            AuthorizationLease::query()
                ->where('user_id', $user->id)
                ->whereNull('revoked_at')
                ->update(['revoked_at' => now(), 'revoked_reason' => 'permissions_changed']);

            $this->sync->record(
                'permission.changed',
                'user',
                $user->uuid,
                [
                    'user_uuid' => $user->uuid,
                    'roles' => $user->roleSlugs(),
                    'permissions' => $user->permissionSlugs(),
                    'authentication_version' => (int) $user->auth_version,
                    'changed_at' => now()->toIso8601String(),
                ],
                $user->business_id,
            );
        });
    }
}
