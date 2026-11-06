<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class SaleItem extends Model
{
    protected $fillable = [
        'sale_id',
        'source_order_item_id',
        'product_id',
        'product_uuid',
        'sku',
        'product_name',
        'variant_uuid',
        'variant_name',
        'addon_summary',
        'unit_price',
        'quantity',
        'discount_amount',
        'tax_rate_basis_points',
        'tax_amount',
        'service_charge_amount',
        'subtotal',
        'total',
        'snapshot',
    ];

    protected function casts(): array
    {
        return [
            'unit_price' => 'integer',
            'quantity' => 'integer',
            'discount_amount' => 'integer',
            'tax_rate_basis_points' => 'integer',
            'tax_amount' => 'integer',
            'service_charge_amount' => 'integer',
            'subtotal' => 'integer',
            'total' => 'integer',
            'snapshot' => 'array',
        ];
    }

    public function sale(): BelongsTo
    {
        return $this->belongsTo(Sale::class);
    }

    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class);
    }
}
