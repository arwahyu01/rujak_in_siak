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

    public const STATUS_CLOSING = 'closing';

    public const STATUS_CLOSED_PENDING_SYNC = 'closed_pending_sync';

    public const STATUS_CLOSED_CONFIRMED = 'closed_confirmed';

    public const STATUS_CLOSED_SYNC_EXCEPTION = 'closed_sync_exception';

    protected $fillable = [
        'business_id',
        'outlet_id',
        'user_id',
        'device_id',
        'status',
        'open_slot',
        'close_epoch',
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
        'closing_started_at',
        'closing_requested_by',
        'closing_requested_device_id',
        'close_actual_cash',
        'closed_by_user_id',
        'closed_device_id',
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
            'close_epoch' => 'integer',
            'close_actual_cash' => 'integer',
            'opened_at' => 'datetime',
            'closed_at' => 'datetime',
            'closing_started_at' => 'datetime',
            'approved_at' => 'datetime',
        ];
    }

    public function isActive(): bool
    {
        return in_array($this->status, [self::STATUS_OPEN, self::STATUS_CLOSING], true);
    }

    public function isAcceptingTransactions(): bool
    {
        return $this->status === self::STATUS_OPEN;
    }

    public function isFinalized(): bool
    {
        return in_array($this->status, [
            self::STATUS_CLOSED_CONFIRMED,
            self::STATUS_CLOSED_SYNC_EXCEPTION,
        ], true);
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

    public function closingRequestedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'closing_requested_by');
    }

    public function closingRequestedDevice(): BelongsTo
    {
        return $this->belongsTo(Device::class, 'closing_requested_device_id');
    }

    public function closedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'closed_by_user_id');
    }

    public function closedDevice(): BelongsTo
    {
        return $this->belongsTo(Device::class, 'closed_device_id');
    }

    public function participants(): HasMany
    {
        return $this->hasMany(ShiftDevice::class);
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
