<?php

namespace App\Http\Requests\Api;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class SyncPushRequest extends FormRequest
{
    public const CLIENT_EVENT_TYPES = [
        'order.created',
        'order.updated',
        'order.held',
        'order.resumed',
        'order.cancelled',
        'order.converted',
        'sale.finalized',
        'sale.voided',
        'payment.recorded',
        'payment.verification_requested',
        'shift.opened',
        'shift.cash_movement',
        'shift.closed',
    ];

    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'protocol_version' => ['required', 'integer'],
            'batch_id' => ['required', 'uuid'],
            'device_id' => ['required', 'uuid'],
            'outlet_id' => ['required', 'uuid'],
            'origin' => ['nullable', 'string', Rule::in(['online', 'offline'])],
            'lease_token' => ['nullable', 'string', 'max:16384'],
            'events' => ['required', 'array', 'min:1', 'max:50'],
            'events.*.event_id' => ['required', 'uuid'],
            'events.*.event_type' => ['required', 'string', Rule::in(self::CLIENT_EVENT_TYPES)],
            'events.*.aggregate_type' => ['required', 'string', 'max:40'],
            'events.*.aggregate_id' => ['required', 'string', 'max:64'],
            'events.*.sequence' => ['required', 'integer', 'min:1'],
            'events.*.schema_version' => ['nullable', 'integer', 'min:1'],
            'events.*.occurred_at' => ['nullable', 'date'],
            'events.*.payload' => ['required', 'array'],
        ];
    }
}
