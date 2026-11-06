<?php

namespace App\Actions\Catalog;

use App\Models\Product;
use App\Services\AuditLogger;
use App\Services\SyncRecorder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class SaveProduct
{
    public function __construct(
        private readonly AuditLogger $audit,
        private readonly SyncRecorder $sync,
    ) {}

    public function handle(array $data, int $businessId, ?Product $product = null): Product
    {
        return DB::transaction(function () use ($data, $businessId, $product) {
            $old = $product ? $product->only([
                'category_id', 'sku', 'barcode', 'name', 'description', 'unit', 'price',
                'production_cost', 'tax_rate_basis_points', 'is_active', 'is_available',
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
                'tax_rate_basis_points' => isset($data['tax_rate_basis_points']) && $data['tax_rate_basis_points'] !== ''
                    ? (int) $data['tax_rate_basis_points']
                    : null,
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

            $fresh = $product->refresh()->load(['category', 'variants', 'addons']);
            $this->audit->record(
                $product->wasRecentlyCreated ? 'product.created' : 'product.updated',
                'products',
                ($product->wasRecentlyCreated ? 'Membuat' : 'Memperbarui').' produk '.$product->name,
                $product,
                $old,
                $fresh->only([
                    'category_id', 'sku', 'barcode', 'name', 'description', 'unit', 'price',
                    'production_cost', 'tax_rate_basis_points', 'is_active', 'is_available',
                ]) + [
                    'variants' => $fresh->variants->map->only(['name', 'sku', 'price_delta', 'is_active'])->all(),
                    'addons' => $fresh->addons->map->only(['name', 'price', 'is_active'])->all(),
                ],
                businessId: $businessId,
            );

            $this->sync->record(
                $product->wasRecentlyCreated ? 'product.created' : 'product.updated',
                'product',
                $fresh->uuid,
                [
                    'uuid' => $fresh->uuid,
                    'sku' => $fresh->sku,
                    'barcode' => $fresh->barcode,
                    'name' => $fresh->name,
                    'description' => $fresh->description,
                    'unit' => $fresh->unit,
                    'price' => (int) $fresh->price,
                    'tax_rate_basis_points' => $fresh->tax_rate_basis_points,
                    'is_active' => (bool) $fresh->is_active,
                    'is_available' => (bool) $fresh->is_available,
                    'image_url' => $fresh->image_url,
                    'category' => $fresh->category ? [
                        'uuid' => $fresh->category->uuid,
                        'name' => $fresh->category->name,
                    ] : null,
                    'variants' => $fresh->variants->map(fn ($variant) => [
                        'uuid' => $variant->uuid,
                        'name' => $variant->name,
                        'sku' => $variant->sku,
                        'price_delta' => (int) $variant->price_delta,
                        'is_active' => (bool) $variant->is_active,
                    ])->all(),
                    'addons' => $fresh->addons->map(fn ($addon) => [
                        'uuid' => $addon->uuid,
                        'name' => $addon->name,
                        'price' => (int) $addon->price,
                        'is_active' => (bool) $addon->is_active,
                    ])->all(),
                    'updated_at' => $fresh->updated_at?->toIso8601String(),
                ],
                $businessId,
            );

            return $fresh;
        });
    }
}
