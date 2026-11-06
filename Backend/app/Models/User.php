<?php

namespace App\Models;

use App\Models\Concerns\HasUuid;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Illuminate\Support\Collection;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasUuid, Notifiable;

    protected $fillable = [
        'name',
        'email',
        'username',
        'phone',
        'password',
        'business_id',
        'outlet_id',
        'is_active',
    ];

    protected $hidden = [
        'password',
        'pin_hash',
        'remember_token',
    ];

    /** @var array<int, string>|null */
    private ?array $permissionSlugCache = null;

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'last_login_at' => 'datetime',
            'pin_updated_at' => 'datetime',
            'locked_until' => 'datetime',
            'is_active' => 'boolean',
            'password' => 'hashed',
            'auth_version' => 'integer',
            'failed_login_attempts' => 'integer',
        ];
    }

    public function business(): BelongsTo
    {
        return $this->belongsTo(Business::class);
    }

    public function outlet(): BelongsTo
    {
        return $this->belongsTo(Outlet::class);
    }

    public function roles(): BelongsToMany
    {
        return $this->belongsToMany(Role::class, 'user_roles');
    }

    public function sales(): HasMany
    {
        return $this->hasMany(Sale::class, 'user_id');
    }

    public function shifts(): HasMany
    {
        return $this->hasMany(Shift::class, 'user_id');
    }

    public function orders(): HasMany
    {
        return $this->hasMany(Order::class, 'user_id');
    }

    public function sessions(): HasMany
    {
        return $this->hasMany(UserSession::class);
    }

    public function authorizationLeases(): HasMany
    {
        return $this->hasMany(AuthorizationLease::class);
    }

    public function permissionSlugs(): array
    {
        if ($this->permissionSlugCache !== null) {
            return $this->permissionSlugCache;
        }

        if (! $this->relationLoaded('roles')) {
            $this->load('roles.permissions');
        }

        if ($this->roles->contains(fn (Role $role) => $role->slug === 'owner')) {
            return $this->permissionSlugCache = Permission::query()->pluck('slug')->all();
        }

        return $this->permissionSlugCache = $this->roles
            ->flatMap(fn (Role $role) => $role->permissions)
            ->pluck('slug')
            ->unique()
            ->values()
            ->all();
    }

    /** @return Collection<int, string> */
    public function permissionNames(): Collection
    {
        return collect($this->permissionSlugs());
    }

    public function hasPermission(string $permission): bool
    {
        return in_array($permission, $this->permissionSlugs(), true);
    }

    public function hasAnyPermission(array $permissions): bool
    {
        return count(array_intersect($permissions, $this->permissionSlugs())) > 0;
    }

    public function hasRole(string $role): bool
    {
        return $this->roles->contains(fn (Role $roleModel) => $roleModel->slug === $role);
    }

    public function isOwner(): bool
    {
        return $this->hasRole('owner');
    }

    public function roleSlugs(): array
    {
        if (! $this->relationLoaded('roles')) {
            $this->load('roles');
        }

        return $this->roles->pluck('slug')->values()->all();
    }

    /**
     * Any change to identity, role, permission, password, PIN, or active state
     * invalidates previously issued offline leases.
     */
    public function bumpAuthVersion(): void
    {
        $this->forceFill(['auth_version' => ((int) $this->auth_version) + 1])->save();
        $this->permissionSlugCache = null;
    }
}
