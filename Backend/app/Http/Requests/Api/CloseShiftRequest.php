<?php

namespace App\Http\Requests\Api;

use Illuminate\Foundation\Http\FormRequest;

class CloseShiftRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'shift_uuid' => ['required', 'uuid'],
            'actual_cash' => ['required', 'integer', 'min:0', 'max:999999999999'],
            'closing_notes' => ['nullable', 'string', 'max:1000'],
            'pending_sync_count' => ['nullable', 'integer', 'min:0'],
            'local_event_sequence' => ['nullable', 'integer', 'min:0'],
            'closed_at' => ['nullable', 'date'],
        ];
    }
}
