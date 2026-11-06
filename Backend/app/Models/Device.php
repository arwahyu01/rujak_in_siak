<?php

namespace App\Models;

use App\Models\Concerns\HasUuid;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Device extends Model
{
    use HasUuid;

    public const STATUS_ACTIVE = 'active';

    public const STATUS_REVOKED = 'revoked';

    protected $fillable = [
        'uuid',
        'business_id',
        'outlet_id',
        'name',
        'terminal_code',
        'platform',
        'app_version',
        'device_fingerprint',
        'last_sequence',
        'status',
        'last_seen_at',
        'activated_at',
        'revoked_at',
    ];

    protected function casts(): array
    {
        return [
            'last_sequence' => 'integer',
            'last_seen_at' => 'datetime',
            'activated_at' => 'datetime',
            'revoked_at' => 'datetime',
        ];
    }

    public function isActive(): bool
    {
        return $this->status === self::STATUS_ACTIVE && $this->revoked_at === null;
    }

    public function business(): BelongsTo
    {
        return $this->belongsTo(Business::class);
    }

    public function outlet(): BelongsTo
    {
        return $this->belongsTo(Outlet::class);
    }

    public function authorizationLeases(): HasMany
    {
        return $this->hasMany(AuthorizationLease::class);
    }

    public function sessions(): HasMany
    {
        return $this->hasMany(UserSession::class);
    }
}
