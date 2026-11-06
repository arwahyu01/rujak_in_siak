<?php

namespace App\Http\Requests\Api;

use Illuminate\Foundation\Http\FormRequest;

class OfflineLeaseRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'hours' => ['nullable', 'integer', 'min:1', 'max:72'],
            'pin' => ['nullable', 'digits_between:4,6'],
            'password' => ['nullable', 'string', 'max:255'],
        ];
    }
}
