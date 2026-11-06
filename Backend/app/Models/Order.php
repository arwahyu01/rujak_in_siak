<?php

namespace App\Models;

use App\Models\Concerns\HasUuid;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class Order extends Model
{
    use HasUuid;

    public const STATUS_DRAFT = 'draft';

    public const STATUS_HELD = 'held';

    public const STATUS_RESUMED = 'resumed';

    public const STATUS_CONVERTED = 'converted';

    public const STATUS_CANCELLED = 'cancelled';

    public const TYPE_DINE_IN = 'dine_in';

    public const TYPE_TAKE_AWAY = 'take_away';

    public const TYPE_DELIVERY = 'delivery';

    protected $fillable = [
        'uuid',
        'business_id',
        'outlet_id',
        'device_id',
        'shift_id',
        'user_id',
        'order_number',
        'status',
        'version',
        'order_type',
        'table_number',
        'table_conflict',
        'notes',
        'subtotal',
        'item_discount_total',
        'transaction_discount_total',
        'discount_total',
        'service_charge',
        'tax_total',
        'total',
        'pricing_snapshot',
        'held_at',
        'resumed_at',
        'cancelled_at',
        'cancel_reason',
        'converted_at',
    ];

    protected function casts(): array
    {
        return [
            'version' => 'integer',
            'table_conflict' => 'boolean',
            'subtotal' => 'integer',
            'item_discount_total' => 'integer',
            'transaction_discount_total' => 'integer',
            'discount_total' => 'integer',
            'service_charge' => 'integer',
            'tax_total' => 'integer',
            'total' => 'integer',
            'pricing_snapshot' => 'array',
            'held_at' => 'datetime',
            'resumed_at' => 'datetime',
            'cancelled_at' => 'datetime',
            'converted_at' => 'datetime',
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

    public function device(): BelongsTo
    {
        return $this->belongsTo(Device::class);
    }

    public function shift(): BelongsTo
    {
        return $this->belongsTo(Shift::class);
    }

    public function cashier(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function items(): HasMany
    {
        return $this->hasMany(OrderItem::class);
    }

    public function statusHistories(): HasMany
    {
        return $this->hasMany(OrderStatusHistory::class);
    }

    public function sale(): HasOne
    {
        return $this->hasOne(Sale::class, 'source_order_id');
    }

    public function isEditable(): bool
    {
        return in_array($this->status, [self::STATUS_DRAFT, self::STATUS_HELD, self::STATUS_RESUMED], true);
    }

    public function scopeActive($query)
    {
        return $query->whereIn('status', [self::STATUS_DRAFT, self::STATUS_HELD, self::STATUS_RESUMED]);
    }
}
