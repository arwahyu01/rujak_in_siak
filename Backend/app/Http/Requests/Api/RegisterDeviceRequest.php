<?php

namespace App\Http\Requests\Api;

use Illuminate\Foundation\Http\FormRequest;

class RegisterDeviceRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'uuid' => ['required', 'uuid'],
            'name' => ['required', 'string', 'max:120'],
            'terminal_code' => ['required', 'string', 'max:20', 'regex:/^[A-Za-z0-9_-]+$/'],
            'platform' => ['nullable', 'in:android,ios,web'],
            'app_version' => ['nullable', 'string', 'max:40'],
            'device_fingerprint' => ['nullable', 'string', 'max:191'],
        ];
    }
}
