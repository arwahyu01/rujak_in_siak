<?php

namespace App\Actions\Users;

use App\Models\Outlet;
use App\Models\Role;
use App\Models\User;
use App\Services\AuditLogger;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class SaveUser
{
    public function __construct(private readonly AuditLogger $audit)
    {
    }

    public function handle(array $data, User $actor, ?User $user = null): User
    {
        return DB::transaction(function () use ($data, $actor, $user) {
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

            return $user->refresh()->load('roles');
        });
    }
}
