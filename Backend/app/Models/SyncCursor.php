<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class SyncCursor extends Model
{
    protected $fillable = [
        'device_id',
        'user_id',
        'last_event_id',
        'last_pulled_at',
    ];

    protected function casts(): array
    {
        return [
            'last_event_id' => 'integer',
            'last_pulled_at' => 'datetime',
        ];
    }

    public function device(): BelongsTo
    {
        return $this->belongsTo(Device::class);
    }
}
