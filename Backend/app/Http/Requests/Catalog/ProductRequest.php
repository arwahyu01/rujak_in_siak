<?php

namespace App\Http\Requests\Catalog;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class ProductRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $product = $this->route('product');
        $businessId = $this->user()->business_id;

        return [
            'name' => ['required', 'string', 'max:150'],
            'sku' => [
                'required', 'string', 'max:60',
                Rule::unique('products', 'sku')
                    ->where('business_id', $businessId)
                    ->ignore($product?->id),
            ],
            'barcode' => ['nullable', 'string', 'max:80'],
            'category_id' => [
                'nullable', 'integer',
                Rule::exists('categories', 'id')->where('business_id', $businessId),
            ],
            'description' => ['nullable', 'string', 'max:3000'],
            'unit' => ['nullable', 'string', 'max:30'],
            'price' => ['required', 'integer', 'min:0', 'max:999999999999'],
            'production_cost' => ['nullable', 'integer', 'min:0', 'max:999999999999'],
            'is_active' => ['nullable', 'boolean'],
            'is_available' => ['nullable', 'boolean'],
            'image' => ['nullable', 'image', 'mimes:jpg,jpeg,png,webp', 'max:2048'],
            'variants' => ['nullable', 'array'],
            'variants.*.name' => ['nullable', 'string', 'max:120'],
            'variants.*.sku' => ['nullable', 'string', 'max:60'],
            'variants.*.price_delta' => ['nullable', 'integer', 'min:-999999999', 'max:999999999'],
            'variants.*.is_active' => ['nullable', 'boolean'],
            'addons' => ['nullable', 'array'],
            'addons.*.name' => ['nullable', 'string', 'max:120'],
            'addons.*.price' => ['nullable', 'integer', 'min:0', 'max:999999999'],
            'addons.*.is_active' => ['nullable', 'boolean'],
        ];
    }
}
