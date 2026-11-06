<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PaymentVerificationLog extends Model
{
    public $timestamps = false;

    protected $fillable = [
        'sale_payment_id',
        'action',
        'actor_id',
        'recorded_amount',
        'verified_amount',
        'reason',
        'provider_reference',
        'notes',
    ];

    protected function casts(): array
    {
        return [
            'recorded_amount' => 'integer',
            'verified_amount' => 'integer',
            'created_at' => 'datetime',
        ];
    }

    public function payment(): BelongsTo
    {
        return $this->belongsTo(SalePayment::class, 'sale_payment_id');
    }

    public function actor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'actor_id');
    }
}
