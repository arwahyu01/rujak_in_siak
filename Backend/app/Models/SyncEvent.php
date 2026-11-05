<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class SyncEvent extends Model
{
    protected $fillable = [
        'event_id',
        'business_id',
        'outlet_id',
        'device_id',
        'event_type',
        'aggregate_type',
        'aggregate_id',
        'aggregate_version',
        'base_version',
        'sequence',
        'schema_version',
        'status',
        'payload',
        'error_code',
        'occurred_at',
        'processed_at',
    ];

    protected function casts(): array
    {
        return [
            'aggregate_version' => 'integer',
            'base_version' => 'integer',
            'sequence' => 'integer',
            'schema_version' => 'integer',
            'payload' => 'array',
            'occurred_at' => 'datetime',
            'processed_at' => 'datetime',
        ];
    }

    public function business(): BelongsTo
    {
        return $this->belongsTo(Business::class);
    }

    public function outlet(): BelongsTo
    {
        return $this->belongsTo(Outlet::class);
    }

    public function device(): BelongsTo
    {
        return $this->belongsTo(Device::class);
    }
}
