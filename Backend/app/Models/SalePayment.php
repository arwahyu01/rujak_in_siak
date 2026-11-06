<?php

namespace App\Models;

use App\Models\Concerns\HasUuid;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class SalePayment extends Model
{
    use HasUuid;

    public const METHOD_CASH = 'cash';

    public const METHOD_QRIS = 'qris';

    public const METHOD_TRANSFER = 'transfer';

    public const METHOD_EWALLET = 'ewallet';

    public const STATUS_RECORDED = 'recorded';

    public const STATUS_AWAITING_VERIFICATION = 'awaiting_verification';

    public const STATUS_CONFIRMED = 'confirmed';

    public const STATUS_REJECTED = 'rejected';

    public const STATUS_CANCELLED = 'cancelled';

    public const STATUS_REFUNDED = 'refunded';

    protected $fillable = [
        'sale_id',
        'uuid',
        'idempotency_key',
        'method',
        'amount',
        'tendered_amount',
        'change_amount',
        'verified_amount',
        'status',
        'provider_reference',
        'notes',
        'proof_path',
        'origin',
        'recorded_by',
        'recorded_at',
        'verified_by',
        'verified_at',
        'rejected_by',
        'rejected_at',
        'rejection_reason',
    ];

    protected function casts(): array
    {
        return [
            'amount' => 'integer',
            'tendered_amount' => 'integer',
            'change_amount' => 'integer',
            'verified_amount' => 'integer',
            'recorded_at' => 'datetime',
            'verified_at' => 'datetime',
            'rejected_at' => 'datetime',
        ];
    }

    public function isCash(): bool
    {
        return $this->method === self::METHOD_CASH;
    }

    public function sale(): BelongsTo
    {
        return $this->belongsTo(Sale::class);
    }

    public function recordedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'recorded_by');
    }

    public function verifiedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'verified_by');
    }

    public function rejectedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'rejected_by');
    }

    public function verificationLogs(): HasMany
    {
        return $this->hasMany(PaymentVerificationLog::class);
    }

    public function confirmedAmount(): int
    {
        return (int) ($this->verified_amount ?? $this->amount);
    }
}
