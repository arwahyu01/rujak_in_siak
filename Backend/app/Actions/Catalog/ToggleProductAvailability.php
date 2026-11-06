<?php

namespace App\Actions\Catalog;

use App\Models\Product;
use App\Services\AuditLogger;
use App\Services\SyncRecorder;

class ToggleProductAvailability
{
    public function __construct(
        private readonly AuditLogger $audit,
        private readonly SyncRecorder $sync,
    ) {}

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

        $fresh = $product->refresh();

        $this->sync->record(
            'product.updated',
            'product',
            $fresh->uuid,
            [
                'uuid' => $fresh->uuid,
                'is_active' => (bool) $fresh->is_active,
                'is_available' => (bool) $fresh->is_available,
                'updated_at' => $fresh->updated_at?->toIso8601String(),
            ],
            $fresh->business_id,
        );

        return $fresh;
    }
}
