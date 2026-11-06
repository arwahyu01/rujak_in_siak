<?php

namespace App\Http\Requests\Api;

use Illuminate\Foundation\Http\FormRequest;

class VerifyPaymentRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'verified_amount' => ['required', 'integer', 'min:1'],
            'provider_reference' => ['nullable', 'string', 'max:200'],
            'correction_reason' => ['nullable', 'string', 'max:500'],
            'verification_note' => ['nullable', 'string', 'max:500'],
        ];
    }
}
