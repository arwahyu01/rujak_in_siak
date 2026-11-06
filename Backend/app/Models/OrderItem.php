<?php

namespace App\Models;

use App\Models\Concerns\HasUuid;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class OrderItem extends Model
{
    use HasUuid;

    protected $fillable = [
        'uuid',
        'order_id',
        'product_id',
        'product_uuid',
        'sku',
        'product_name',
        'variant_uuid',
        'variant_name',
        'addons',
        'unit_price',
        'quantity',
        'item_discount',
        'tax_rate_basis_points',
        'notes',
        'line_subtotal',
        'line_total',
        'snapshot',
    ];

    protected function casts(): array
    {
        return [
            'addons' => 'array',
            'unit_price' => 'integer',
            'quantity' => 'integer',
            'item_discount' => 'integer',
            'tax_rate_basis_points' => 'integer',
            'line_subtotal' => 'integer',
            'line_total' => 'integer',
            'snapshot' => 'array',
        ];
    }

    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class);
    }

    public function modifiers(): HasMany
    {
        return $this->hasMany(OrderItemModifier::class);
    }
}
