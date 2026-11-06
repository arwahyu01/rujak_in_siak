<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class IdempotencyKey extends Model
{
    protected $fillable = [
        'business_id',
        'user_id',
        'device_id',
        'scope',
        'key',
        'request_hash',
        'response_status',
        'response_payload',
        'resource_type',
        'resource_uuid',
        'expires_at',
    ];

    protected function casts(): array
    {
        return [
            'response_status' => 'integer',
            'response_payload' => 'array',
            'expires_at' => 'datetime',
        ];
    }
}
