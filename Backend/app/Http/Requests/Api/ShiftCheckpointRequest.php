<?php

namespace App\Http\Requests\Api;

use Illuminate\Foundation\Http\FormRequest;

class ShiftCheckpointRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'close_epoch' => ['nullable', 'integer', 'min:0'],
            'pending_outbox_count' => ['nullable', 'integer', 'min:0'],
            'last_sequence' => ['nullable', 'integer', 'min:0'],
        ];
    }
}
