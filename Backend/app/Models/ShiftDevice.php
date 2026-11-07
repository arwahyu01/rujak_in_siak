<?php

namespace App\Models;

use App\Models\Concerns\HasUuid;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ShiftDevice extends Model
{
    use HasUuid;

    protected $fillable = [
        'uuid',
        'shift_id',
        'business_id',
        'outlet_id',
        'device_id',
        'user_id',
        'requires_checkpoint',
        'last_ack_epoch',
        'last_sequence',
        'checkpoint_outbox_pending',
        'acknowledged_at',
        'first_seen_at',
        'last_seen_at',
    ];

    protected function casts(): array
    {
        return [
            'requires_checkpoint' => 'boolean',
            'last_ack_epoch' => 'integer',
            'last_sequence' => 'integer',
            'checkpoint_outbox_pending' => 'integer',
            'acknowledged_at' => 'datetime',
            'first_seen_at' => 'datetime',
            'last_seen_at' => 'datetime',
        ];
    }

    public function shift(): BelongsTo
    {
        return $this->belongsTo(Shift::class);
    }

    public function device(): BelongsTo
    {
        return $this->belongsTo(Device::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
