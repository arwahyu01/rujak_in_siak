<?php

namespace App\Models;

use App\Models\Concerns\HasUuid;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ProductVariant extends Model
{
    use HasUuid;

    protected $fillable = [
        'product_id',
        'name',
        'sku',
        'price_delta',
        'is_active',
    ];

    protected function casts(): array
    {
        return [
            'price_delta' => 'integer',
            'is_active' => 'boolean',
        ];
    }

    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class);
    }
}
