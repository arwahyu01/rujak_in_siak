<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ProductResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'uuid' => $this->uuid,
            'sku' => $this->sku,
            'barcode' => $this->barcode,
            'name' => $this->name,
            'description' => $this->description,
            'unit' => $this->unit,
            'price' => (int) $this->price,
            'tax_rate_basis_points' => $this->tax_rate_basis_points,
            'is_active' => (bool) $this->is_active,
            'is_available' => (bool) $this->is_available,
            'image_url' => $this->image_url,
            'category' => $this->whenLoaded('category', fn () => $this->category ? [
                'uuid' => $this->category->uuid,
                'name' => $this->category->name,
            ] : null),
            'variants' => $this->whenLoaded('variants', fn () => $this->variants->map(fn ($variant) => [
                'uuid' => $variant->uuid,
                'name' => $variant->name,
                'sku' => $variant->sku,
                'price_delta' => (int) $variant->price_delta,
                'is_active' => (bool) $variant->is_active,
            ])->all()),
            'addons' => $this->whenLoaded('addons', fn () => $this->addons->map(fn ($addon) => [
                'uuid' => $addon->uuid,
                'name' => $addon->name,
                'price' => (int) $addon->price,
                'is_active' => (bool) $addon->is_active,
            ])->all()),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
