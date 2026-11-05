<?php

namespace App\Actions\Catalog;

use App\Models\Product;
use App\Services\AuditLogger;

class ToggleProductAvailability
{
    public function __construct(private readonly AuditLogger $audit)
    {
    }

    public function handle(Product $product, string $field): Product
    {
        abort_unless(in_array($field, ['is_active', 'is_available'], true), 404);

        $old = (bool) $product->{$field};
        $product->update([$field => ! $old]);

        $this->audit->record(
            'product.availability_changed',
            'products',
            'Mengubah status '.($field === 'is_active' ? 'aktif' : 'ketersediaan').' produk '.$product->name,
            $product,
            [$field => $old],
            [$field => ! $old],
            businessId: $product->business_id,
        );

        return $product->refresh();
    }
}
