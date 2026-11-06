<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class SyncLog extends Model
{
    protected $fillable = [
        'batch_id',
        'business_id',
        'outlet_id',
        'device_id',
        'user_id',
        'protocol_version',
        'event_count',
        'accepted_count',
        'duplicate_count',
        'rejected_count',
        'conflict_count',
        'blocked_count',
        'result',
        'ip_address',
        'received_at',
    ];

    protected function casts(): array
    {
        return [
            'protocol_version' => 'integer',
            'event_count' => 'integer',
            'accepted_count' => 'integer',
            'duplicate_count' => 'integer',
            'rejected_count' => 'integer',
            'conflict_count' => 'integer',
            'blocked_count' => 'integer',
            'result' => 'array',
            'received_at' => 'datetime',
        ];
    }
}
