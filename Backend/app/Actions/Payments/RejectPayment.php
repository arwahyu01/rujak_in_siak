<?php

namespace App\Actions\Payments;

use App\Models\PaymentVerificationLog;
use App\Models\Sale;
use App\Models\SalePayment;
use App\Models\User;
use App\Services\AuditLogger;
use App\Services\SalePaymentAggregator;
use App\Services\SyncRecorder;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class RejectPayment
{
    public function __construct(
        private readonly SalePaymentAggregator $aggregator,
        private readonly AuditLogger $audit,
        private readonly SyncRecorder $sync,
    ) {
    }

    public function handle(SalePayment $payment, array $data, User $actor): SalePayment
    {
        return DB::transaction(function () use ($payment, $data, $actor) {
            $payment = SalePayment::query()->with('sale')->lockForUpdate()->findOrFail($payment->id);
            $sale = Sale::query()->lockForUpdate()->findOrFail($payment->sale_id);

            if (! $actor->hasPermission('payments.reject')) {
                throw new AuthorizationException('Anda tidak memiliki hak untuk menolak pembayaran.');
            }

            if ((int) $payment->recorded_by === (int) $actor->id) {
                throw new AuthorizationException('Pemisahan tugas: pencatat pembayaran tidak boleh menolak pembayaran yang ia catat sendiri.');
            }

            if ($payment->status !== SalePayment::STATUS_AWAITING_VERIFICATION) {
                throw ValidationException::withMessages([
                    'payment' => 'Pembayaran ini sudah diproses dan tidak dapat ditolak ulang.',
                ]);
            }

            $old = $payment->only(['status', 'rejected_by', 'rejected_at', 'rejection_reason']);

            $payment->forceFill([
                'status' => SalePayment::STATUS_REJECTED,
                'rejected_by' => $actor->id,
                'rejected_at' => now(),
                'rejection_reason' => $data['reason'],
            ])->save();

            PaymentVerificationLog::create([
                'sale_payment_id' => $payment->id,
                'action' => 'rejected',
                'actor_id' => $actor->id,
                'recorded_amount' => (int) $payment->amount,
                'verified_amount' => null,
                'reason' => $data['reason'],
                'provider_reference' => $payment->provider_reference,
                'notes' => $data['notes'] ?? null,
            ]);

            $sale = $this->aggregator->recalculate($sale);

            $this->audit->record(
                'payment.rejected',
                'payments',
                'Menolak pembayaran '.$payment->uuid.' untuk transaksi '.$sale->receipt_number,
                $payment,
                $old,
                $payment->only(['status', 'rejected_by', 'rejected_at', 'rejection_reason']) + [
                    'sale_payment_status' => $sale->payment_status,
                ],
                $actor,
                $sale->business_id,
            );

            $this->sync->record(
                'payment.rejected',
                'sale_payment',
                $payment->uuid,
                [
                    'sale_uuid' => $sale->uuid,
                    'payment_uuid' => $payment->uuid,
                    'status' => $payment->status,
                    'reason' => $payment->rejection_reason,
                    'payment_status' => $sale->payment_status,
                ],
                $sale->business_id,
                $sale->outlet_id,
                $sale->device_id,
            );

            return $payment->refresh()->load(['sale', 'rejectedBy', 'verificationLogs.actor']);
        });
    }
}
