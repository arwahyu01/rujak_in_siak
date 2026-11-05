<?php

namespace App\Actions\Catalog;

use App\Models\Product;
use App\Services\AuditLogger;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class SaveProduct
{
    public function __construct(private readonly AuditLogger $audit)
    {
    }

    public function handle(array $data, int $businessId, ?Product $product = null): Product
    {
        return DB::transaction(function () use ($data, $businessId, $product) {
            $old = $product ? $product->only([
                'category_id', 'sku', 'barcode', 'name', 'description', 'unit', 'price',
                'production_cost', 'is_active', 'is_available',
            ]) : [];

            $payload = [
                'business_id' => $businessId,
                'category_id' => $data['category_id'] ?? null,
                'sku' => $data['sku'],
                'barcode' => $data['barcode'] ?? null,
                'name' => $data['name'],
                'description' => $data['description'] ?? null,
                'unit' => $data['unit'] ?? 'porsi',
                'price' => (int) $data['price'],
                'production_cost' => isset($data['production_cost']) && $data['production_cost'] !== '' ? (int) $data['production_cost'] : null,
                'is_active' => (bool) ($data['is_active'] ?? true),
                'is_available' => (bool) ($data['is_available'] ?? true),
            ];

            if (! empty($data['image'])) {
                if ($product?->image_path) {
                    Storage::disk('public')->delete($product->image_path);
                }
                $payload['image_path'] = $data['image']->store('products', 'public');
            }

            if ($product) {
                $product->update($payload);
            } else {
                $product = Product::create($payload);
            }

            $product->variants()->delete();
            foreach ($data['variants'] ?? [] as $index => $variant) {
                if (empty($variant['name'])) {
                    continue;
                }
                $product->variants()->create([
                    'uuid' => (string) Str::uuid(),
                    'name' => $variant['name'],
                    'sku' => $variant['sku'] ?? null,
                    'price_delta' => (int) ($variant['price_delta'] ?? 0),
                    'is_active' => (bool) ($variant['is_active'] ?? true),
                ]);
            }

            $product->addons()->delete();
            foreach ($data['addons'] ?? [] as $addon) {
                if (empty($addon['name'])) {
                    continue;
                }
                $product->addons()->create([
                    'uuid' => (string) Str::uuid(),
                    'name' => $addon['name'],
                    'price' => (int) ($addon['price'] ?? 0),
                    'is_active' => (bool) ($addon['is_active'] ?? true),
                ]);
            }

            $fresh = $product->refresh()->load(['variants', 'addons']);
            $this->audit->record(
                $product->wasRecentlyCreated ? 'product.created' : 'product.updated',
                'products',
                ($product->wasRecentlyCreated ? 'Membuat' : 'Memperbarui').' produk '.$product->name,
                $product,
                $old,
                $fresh->only([
                    'category_id', 'sku', 'barcode', 'name', 'description', 'unit', 'price',
                    'production_cost', 'is_active', 'is_available',
                ]) + [
                    'variants' => $fresh->variants->map->only(['name', 'sku', 'price_delta', 'is_active'])->all(),
                    'addons' => $fresh->addons->map->only(['name', 'price', 'is_active'])->all(),
                ],
                businessId: $businessId,
            );

            return $fresh;
        });
    }
}
