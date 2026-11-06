<?php

namespace App\Models;

use App\Models\Concerns\HasUuid;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ShiftClosingSnapshot extends Model
{
    use HasUuid;

    protected $fillable = [
        'uuid',
        'shift_id',
        'business_id',
        'outlet_id',
        'user_id',
        'device_id',
        'opening_cash',
        'cash_tendered',
        'cash_change',
        'cash_in',
        'cash_out',
        'cash_refund',
        'expected_cash',
        'actual_cash',
        'variance',
        'confirmed_noncash',
        'awaiting_verification_amount',
        'local_transaction_count',
        'pending_sync_count',
        'local_event_sequence',
        'closing_notes',
        'snapshot',
        'closed_at',
    ];

    protected function casts(): array
    {
        return [
            'opening_cash' => 'integer',
            'cash_tendered' => 'integer',
            'cash_change' => 'integer',
            'cash_in' => 'integer',
            'cash_out' => 'integer',
            'cash_refund' => 'integer',
            'expected_cash' => 'integer',
            'actual_cash' => 'integer',
            'variance' => 'integer',
            'confirmed_noncash' => 'integer',
            'awaiting_verification_amount' => 'integer',
            'local_transaction_count' => 'integer',
            'pending_sync_count' => 'integer',
            'local_event_sequence' => 'integer',
            'snapshot' => 'array',
            'closed_at' => 'datetime',
        ];
    }

    public function shift(): BelongsTo
    {
        return $this->belongsTo(Shift::class);
    }
}
