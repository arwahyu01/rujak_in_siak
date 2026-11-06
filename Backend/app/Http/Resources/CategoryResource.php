<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class CategoryResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'uuid' => $this->uuid,
            'name' => $this->name,
            'slug' => $this->slug,
            'description' => $this->description,
            'sort_order' => (int) $this->sort_order,
            'tax_rate_basis_points' => $this->tax_rate_basis_points,
            'is_active' => (bool) $this->is_active,
            'products_count' => $this->whenCounted('products'),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
