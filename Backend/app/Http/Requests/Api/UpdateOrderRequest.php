<?php

namespace App\Http\Requests\Api;

class UpdateOrderRequest extends StoreOrderRequest
{
    public function rules(): array
    {
        return [
            'base_version' => ['required', 'integer', 'min:1'],
        ] + parent::rules();
    }
}
