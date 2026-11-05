<?php

namespace App\Models;

use App\Models\Concerns\HasUuid;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Sale extends Model
{
    use HasUuid;

    public const LIFECYCLE_FINALIZED = 'finalized';
    public const LIFECYCLE_VOIDED = 'voided';

    public const PAYMENT_UNPAID = 'unpaid';
    public const PAYMENT_PARTIALLY_PAID = 'partially_paid';
    public const PAYMENT_AWAITING_VERIFICATION = 'awaiting_verification';
    public const PAYMENT_PAID = 'paid';
    public const PAYMENT_PARTIALLY_REFUNDED = 'partially_refunded';
    public const PAYMENT_REFUNDED = 'refunded';
    public const PAYMENT_CANCELLED = 'cancelled';

    protected $fillable = [
        'business_id',
        'outlet_id',
        'shift_id',
        'user_id',
        'device_id',
        'receipt_number',
        'order_type',
        'table_number',
        'lifecycle_status',
        'payment_status',
        'subtotal',
        'item_discount_total',
        'transaction_discount_total',
        'discount_total',
        'service_charge',
        'tax_total',
        'total',
        'confirmed_amount',
        'awaiting_verification_amount',
        'outstanding_amount',
        'refunded_amount',
        'notes',
        'source_order_uuid',
        'transacted_at',
        'voided_at',
        'voided_by',
        'void_reason',
    ];

    protected function casts(): array
    {
        return [
            'subtotal' => 'integer',
            'item_discount_total' => 'integer',
            'transaction_discount_total' => 'integer',
            'discount_total' => 'integer',
            'service_charge' => 'integer',
            'tax_total' => 'integer',
            'total' => 'integer',
            'confirmed_amount' => 'integer',
            'awaiting_verification_amount' => 'integer',
            'outstanding_amount' => 'integer',
            'refunded_amount' => 'integer',
            'transacted_at' => 'datetime',
            'voided_at' => 'datetime',
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

    public function shift(): BelongsTo
    {
        return $this->belongsTo(Shift::class);
    }

    public function cashier(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function device(): BelongsTo
    {
        return $this->belongsTo(Device::class);
    }

    public function items(): HasMany
    {
        return $this->hasMany(SaleItem::class);
    }

    public function payments(): HasMany
    {
        return $this->hasMany(SalePayment::class);
    }

    public function refunds(): HasMany
    {
        return $this->hasMany(Refund::class);
    }

    public function voidedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'voided_by');
    }

    public function scopeFinalized($query)
    {
        return $query->where('lifecycle_status', self::LIFECYCLE_FINALIZED);
    }

    public function scopeNotVoided($query)
    {
        return $query->where('lifecycle_status', '!=', self::LIFECYCLE_VOIDED);
    }
}
