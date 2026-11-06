<?php

namespace App\Http\Requests\Api;

use App\Models\SalePayment;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class CheckoutRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'order_uuid' => ['required', 'uuid'],
            'base_version' => ['required', 'integer', 'min:1'],
            'notes' => ['nullable', 'string', 'max:1000'],
            'client_created_at' => ['nullable', 'date'],
            'payments' => ['nullable', 'array', 'max:10'],
            'payments.*.method' => ['required', Rule::in([
                SalePayment::METHOD_CASH,
                SalePayment::METHOD_QRIS,
                SalePayment::METHOD_TRANSFER,
                SalePayment::METHOD_EWALLET,
            ])],
            'payments.*.amount' => ['required', 'integer', 'min:1'],
            'payments.*.tendered_amount' => ['nullable', 'integer', 'min:0'],
            'payments.*.provider_reference' => ['nullable', 'string', 'max:200'],
            'payments.*.idempotency_key' => ['nullable', 'string', 'max:120'],
            'payments.*.notes' => ['nullable', 'string', 'max:500'],
        ];
    }
}
