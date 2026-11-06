<?php

namespace App\Http\Requests\Api;

use App\Models\SalePayment;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class RecordPaymentRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'method' => ['required', Rule::in([
                SalePayment::METHOD_CASH,
                SalePayment::METHOD_QRIS,
                SalePayment::METHOD_TRANSFER,
                SalePayment::METHOD_EWALLET,
            ])],
            'amount' => ['required', 'integer', 'min:1'],
            'tendered_amount' => ['nullable', 'integer', 'min:0'],
            'provider_reference' => ['nullable', 'string', 'max:200'],
            'idempotency_key' => ['nullable', 'string', 'max:120'],
            'notes' => ['nullable', 'string', 'max:500'],
        ];
    }
}
