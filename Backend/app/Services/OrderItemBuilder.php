<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\Business;
use App\Models\Product;
use Illuminate\Support\Str;

class OrderItemBuilder
{
    /**
     * Prices always come from the server catalog, never from the client payload.
     */
    public function build(array $items, Business $business): array
    {
        $productUuids = collect($items)
            ->pluck('product_uuid')
            ->filter()
            ->unique()
            ->values()
            ->all();

        $products = Product::query()
            ->with(['category', 'variants', 'addons'])
            ->where('business_id', $business->id)
            ->whereIn('uuid', $productUuids)
            ->get()
            ->keyBy('uuid');

        if ($products->count() !== count($productUuids)) {
            throw new ApiException('PRODUCT_NOT_FOUND', 'Satu atau lebih produk tidak ditemukan pada bisnis ini.', 422);
        }

        $result = [];
        foreach ($items as $index => $input) {
            /** @var Product|null $product */
            $product = $products->get($input['product_uuid']);
            if (! $product || ! $product->is_active) {
                throw new ApiException('PRODUCT_INACTIVE', "Produk item #{$index} tidak aktif.", 422);
            }
            if (! $product->is_available) {
                throw new ApiException('PRODUCT_UNAVAILABLE', "Produk {$product->name} sedang tidak tersedia.", 422);
            }

            $quantity = (int) ($input['quantity'] ?? 0);
            if ($quantity < 1 || $quantity > 100) {
                throw new ApiException('QUANTITY_INVALID', "Kuantitas item #{$index} harus antara 1 dan 100.", 422);
            }

            $variant = null;
            $modifiers = [];
            $unitPrice = (int) $product->price;

            if (! empty($input['variant_uuid'])) {
                $variant = $product->variants->firstWhere('uuid', $input['variant_uuid']);
                if (! $variant || ! $variant->is_active) {
                    throw new ApiException('VARIANT_INVALID', "Varian produk {$product->name} tidak valid/tidak aktif.", 422);
                }
                $unitPrice += (int) $variant->price_delta;
                $modifiers[] = [
                    'type' => 'variant',
                    'modifier_uuid' => $variant->uuid,
                    'name' => $variant->name,
                    'price' => (int) $variant->price_delta,
                    'quantity' => 1,
                    'snapshot' => $variant->only(['uuid', 'name', 'sku', 'price_delta', 'is_active']),
                ];
            }

            $selectedAddons = [];
            foreach (array_unique($input['addon_uuids'] ?? []) as $addonUuid) {
                $addon = $product->addons->firstWhere('uuid', $addonUuid);
                if (! $addon || ! $addon->is_active) {
                    throw new ApiException('ADDON_INVALID', "Add-on produk {$product->name} tidak valid/tidak aktif.", 422);
                }
                $unitPrice += (int) $addon->price;
                $selectedAddons[] = [
                    'uuid' => $addon->uuid,
                    'name' => $addon->name,
                    'price' => (int) $addon->price,
                ];
                $modifiers[] = [
                    'type' => 'addon',
                    'modifier_uuid' => $addon->uuid,
                    'name' => $addon->name,
                    'price' => (int) $addon->price,
                    'quantity' => 1,
                    'snapshot' => $addon->only(['uuid', 'name', 'price', 'is_active']),
                ];
            }

            if ($unitPrice < 0) {
                throw new ApiException('PRICE_INVALID', "Harga akhir produk {$product->name} tidak valid.", 422);
            }

            $taxRate = $product->tax_rate_basis_points
                ?? $product->category?->tax_rate_basis_points
                ?? (int) $business->tax_rate_basis_points;

            $lineSubtotal = $unitPrice * $quantity;
            $itemDiscount = max(0, (int) ($input['item_discount'] ?? 0));
            if ($itemDiscount > $lineSubtotal) {
                throw new ApiException('ITEM_DISCOUNT_EXCEEDS_LINE', "Diskon item {$product->name} melebihi nilai baris.", 422);
            }

            $result[] = [
                'item' => [
                    'uuid' => (string) Str::uuid(),
                    'product_id' => $product->id,
                    'product_uuid' => $product->uuid,
                    'sku' => $product->sku,
                    'product_name' => $product->name,
                    'variant_uuid' => $variant?->uuid,
                    'variant_name' => $variant?->name,
                    'addons' => $selectedAddons,
                    'unit_price' => $unitPrice,
                    'quantity' => $quantity,
                    'item_discount' => $itemDiscount,
                    'tax_rate_basis_points' => (int) $taxRate,
                    'notes' => $input['notes'] ?? null,
                    'line_subtotal' => $lineSubtotal,
                    'line_total' => $lineSubtotal - $itemDiscount,
                    'snapshot' => [
                        'product' => [
                            'uuid' => $product->uuid,
                            'sku' => $product->sku,
                            'name' => $product->name,
                            'category_uuid' => $product->category?->uuid,
                            'category_name' => $product->category?->name,
                            'unit' => $product->unit,
                        ],
                        'variant' => $variant?->only(['uuid', 'name', 'sku', 'price_delta']),
                        'addons' => $selectedAddons,
                        'tax_rate_basis_points' => (int) $taxRate,
                    ],
                ],
                'modifiers' => $modifiers,
            ];
        }

        return $result;
    }
}
