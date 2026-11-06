<?php

namespace App\Actions\Users;

use App\Models\AuthorizationLease;
use App\Models\Outlet;
use App\Models\Role;
use App\Models\User;
use App\Models\UserSession;
use App\Services\AuditLogger;
use App\Services\SyncRecorder;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;
use Laravel\Sanctum\PersonalAccessToken;

class SaveUser
{
    public function __construct(
        private readonly AuditLogger $audit,
        private readonly SyncRecorder $sync,
    ) {}

    public function handle(array $data, User $actor, ?User $user = null): User
    {
        return DB::transaction(function () use ($data, $actor, $user) {
            $created = $user === null;
            $role = Role::query()->findOrFail($data['role_id']);

            if ($user && $user->is($actor) && ! (bool) ($data['is_active'] ?? true)) {
                throw ValidationException::withMessages([
                    'is_active' => 'Anda tidak dapat menonaktifkan akun sendiri.',
                ]);
            }

            if ($user && $role->slug === 'owner') {
                $otherOwners = User::query()
                    ->whereHas('roles', fn ($query) => $query->where('slug', 'owner'))
                    ->whereKeyNot($user->id)
                    ->where('is_active', true)
                    ->count();
                if (! (bool) ($data['is_active'] ?? true) && $otherOwners === 0) {
                    throw ValidationException::withMessages([
                        'is_active' => 'Tidak dapat menonaktifkan satu-satunya akun Owner yang aktif.',
                    ]);
                }
            }

            $old = $user ? $user->only(['name', 'email', 'username', 'phone', 'is_active']) + ['role' => $user->roles->first()?->slug] : [];

            $outletId = $data['outlet_id'] ?? $actor->outlet_id;
            if ($outletId && ! Outlet::query()->where('business_id', $actor->business_id)->whereKey($outletId)->exists()) {
                throw ValidationException::withMessages([
                    'outlet_id' => 'Outlet tidak valid untuk bisnis ini.',
                ]);
            }

            $payload = [
                'name' => $data['name'],
                'email' => $data['email'],
                'username' => $data['username'] ?? null,
                'phone' => $data['phone'] ?? null,
                'business_id' => $actor->business_id,
                'outlet_id' => $outletId,
                'is_active' => (bool) ($data['is_active'] ?? true),
            ];

            if ($user) {
                $user->update($payload);
            } else {
                $payload['password'] = $data['password'];
                $payload['email_verified_at'] = now();
                $user = User::create($payload);
            }

            if (! empty($data['password']) && $user->exists) {
                $user->update(['password' => $data['password']]);
            }

            $roleChanged = ! $created && ! $user->roles()->whereKey($role->id)->exists();
            $user->roles()->sync([$role->id]);

            $this->audit->record(
                $old ? 'user.updated' : 'user.created',
                'users',
                ($old ? 'Memperbarui' : 'Membuat').' pengguna '.$user->name,
                $user,
                $old,
                $user->only(['name', 'email', 'username', 'phone', 'is_active']) + ['role' => $role->slug],
                $actor,
                $actor->business_id,
            );

            $securityChanged = $roleChanged
                || ! empty($data['password'])
                || $user->wasChanged(['email', 'username', 'is_active', 'outlet_id']);

            if (! $created && $securityChanged) {
                $this->invalidateAuthorization($user);
            }

            return $user->refresh()->load('roles');
        });
    }

    private function invalidateAuthorization(User $user): void
    {
        $user->bumpAuthVersion();

        AuthorizationLease::query()
            ->where('user_id', $user->id)
            ->whereNull('revoked_at')
            ->update(['revoked_at' => now(), 'revoked_reason' => 'user_identity_changed']);

        if (! $user->is_active) {
            $tokenIds = UserSession::query()
                ->where('user_id', $user->id)
                ->whereNotNull('personal_access_token_id')
                ->pluck('personal_access_token_id')
                ->unique()
                ->all();

            UserSession::query()
                ->where('user_id', $user->id)
                ->whereNull('revoked_at')
                ->update(['revoked_at' => now(), 'revoked_reason' => 'account_deactivated']);

            if ($tokenIds !== []) {
                PersonalAccessToken::query()->whereIn('id', $tokenIds)->delete();
            }
        }

        $this->sync->record(
            'permission.changed',
            'user',
            $user->uuid,
            [
                'user_uuid' => $user->uuid,
                'roles' => $user->roleSlugs(),
                'permissions' => $user->permissionSlugs(),
                'authentication_version' => (int) $user->auth_version,
                'is_active' => (bool) $user->is_active,
                'changed_at' => now()->toIso8601String(),
            ],
            $user->business_id,
        );
    }
}
