<?php

namespace App\Http\Requests\Api;

use App\Models\Order;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreOrderRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'order_type' => ['nullable', Rule::in([Order::TYPE_DINE_IN, Order::TYPE_TAKE_AWAY, Order::TYPE_DELIVERY])],
            'table_number' => ['nullable', 'string', 'max:30'],
            'notes' => ['nullable', 'string', 'max:1000'],
            'transaction_discount' => ['nullable', 'integer', 'min:0', 'max:999999999999'],
            'table_override' => ['nullable', 'boolean'],
            'table_override_reason' => ['nullable', 'string', 'max:500', 'required_if:table_override,true'],
            'items' => ['required', 'array', 'min:1', 'max:200'],
            'items.*.product_uuid' => ['required', 'uuid'],
            'items.*.variant_uuid' => ['nullable', 'uuid'],
            'items.*.addon_uuids' => ['nullable', 'array'],
            'items.*.addon_uuids.*' => ['uuid'],
            'items.*.quantity' => ['required', 'integer', 'min:1', 'max:100'],
            'items.*.item_discount' => ['nullable', 'integer', 'min:0'],
            'items.*.notes' => ['nullable', 'string', 'max:500'],
        ];
    }
}
