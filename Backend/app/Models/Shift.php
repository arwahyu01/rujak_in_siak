<?php

namespace App\Models;

use App\Models\Concerns\HasUuid;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class Shift extends Model
{
    use HasUuid;

    public const STATUS_OPEN = 'open';

    public const STATUS_CLOSED_PENDING_SYNC = 'closed_pending_sync';

    public const STATUS_CLOSED_CONFIRMED = 'closed_confirmed';

    public const STATUS_CLOSED_SYNC_EXCEPTION = 'closed_sync_exception';

    protected $fillable = [
        'business_id',
        'outlet_id',
        'user_id',
        'device_id',
        'status',
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
        'opening_notes',
        'closing_notes',
        'opened_at',
        'closed_at',
        'approved_by',
        'approved_at',
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
            'opened_at' => 'datetime',
            'closed_at' => 'datetime',
            'approved_at' => 'datetime',
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

    public function cashier(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function device(): BelongsTo
    {
        return $this->belongsTo(Device::class);
    }

    public function approvedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'approved_by');
    }

    public function sales(): HasMany
    {
        return $this->hasMany(Sale::class);
    }

    public function cashMovements(): HasMany
    {
        return $this->hasMany(ShiftCashMovement::class);
    }

    public function closingSnapshot(): HasOne
    {
        return $this->hasOne(ShiftClosingSnapshot::class);
    }

    public function orders(): HasMany
    {
        return $this->hasMany(Order::class);
    }
}
