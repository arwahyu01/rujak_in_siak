<?php

namespace App\Models;

use App\Models\Concerns\HasUuid;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Business extends Model
{
    use HasFactory, HasUuid;

    protected $fillable = [
        'name',
        'address',
        'phone',
        'email',
        'currency',
        'timezone',
        'tax_enabled',
        'tax_rate_basis_points',
        'service_charge_enabled',
        'service_charge_rate_basis_points',
        'tax_includes_service_charge',
        'non_cash_proof_required',
        'is_active',
    ];

    protected function casts(): array
    {
        return [
            'tax_enabled' => 'boolean',
            'service_charge_enabled' => 'boolean',
            'tax_includes_service_charge' => 'boolean',
            'non_cash_proof_required' => 'boolean',
            'is_active' => 'boolean',
        ];
    }

    public function outlets(): HasMany
    {
        return $this->hasMany(Outlet::class);
    }

    public function users(): HasMany
    {
        return $this->hasMany(User::class);
    }

    public function categories(): HasMany
    {
        return $this->hasMany(Category::class);
    }

    public function products(): HasMany
    {
        return $this->hasMany(Product::class);
    }

    public function sales(): HasMany
    {
        return $this->hasMany(Sale::class);
    }

    public function shifts(): HasMany
    {
        return $this->hasMany(Shift::class);
    }

    public function primaryOutlet(): ?Outlet
    {
        return $this->outlets()->where('is_active', true)->orderBy('id')->first();
    }
}
