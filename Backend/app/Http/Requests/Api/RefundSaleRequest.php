<?php

namespace App\Http\Requests\Api;

use App\Models\SalePayment;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class RefundSaleRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'amount' => ['required', 'integer', 'min:1'],
            'reason' => ['required', 'string', 'max:500'],
            'method' => ['nullable', Rule::in([
                SalePayment::METHOD_CASH,
                SalePayment::METHOD_QRIS,
                SalePayment::METHOD_TRANSFER,
                SalePayment::METHOD_EWALLET,
            ])],
            'idempotency_key' => ['nullable', 'string', 'max:120'],
        ];
    }
}
