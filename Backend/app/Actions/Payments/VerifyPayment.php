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

class VerifyPayment
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

            $this->authorize($payment, $actor);

            if ($payment->status !== SalePayment::STATUS_AWAITING_VERIFICATION) {
                throw ValidationException::withMessages([
                    'payment' => 'Pembayaran ini sudah diproses dan tidak dapat diverifikasi ulang.',
                ]);
            }

            $this->aggregator->recalculate($sale);
            $sale->refresh();

            $recorded = (int) $payment->amount;
            $verified = (int) $data['verified_amount'];
            $outstanding = max((int) $sale->outstanding_amount, 0);

            if ($verified <= 0) {
                throw ValidationException::withMessages([
                    'verified_amount' => 'Nominal terverifikasi harus lebih besar dari nol.',
                ]);
            }

            if ($verified > $outstanding) {
                throw ValidationException::withMessages([
                    'verified_amount' => 'Nominal terverifikasi melebihi outstanding transaksi. Kelebihan pembayaran harus diselesaikan melalui proses terpisah.',
                ]);
            }

            $isCorrection = $verified > $recorded;
            if ($isCorrection) {
                if (! $actor->hasPermission('payments.correct_amount')) {
                    throw new AuthorizationException('Koreksi nominal memerlukan persetujuan supervisor.');
                }
                if (empty($data['correction_reason'])) {
                    throw ValidationException::withMessages([
                        'correction_reason' => 'Alasan koreksi wajib diisi untuk nominal yang lebih besar dari nilai tercatat.',
                    ]);
                }
            }

            $old = $payment->only(['status', 'amount', 'verified_amount', 'provider_reference', 'verified_by', 'verified_at']);

            $payment->forceFill([
                'status' => SalePayment::STATUS_CONFIRMED,
                'verified_amount' => $verified,
                'provider_reference' => $data['provider_reference'] ?? $payment->provider_reference,
                'verified_by' => $actor->id,
                'verified_at' => now(),
            ])->save();

            PaymentVerificationLog::create([
                'sale_payment_id' => $payment->id,
                'action' => $isCorrection ? 'corrected' : 'verified',
                'actor_id' => $actor->id,
                'recorded_amount' => $recorded,
                'verified_amount' => $verified,
                'reason' => $isCorrection ? $data['correction_reason'] : ($data['verification_note'] ?? null),
                'provider_reference' => $data['provider_reference'] ?? null,
                'notes' => $data['verification_note'] ?? null,
            ]);

            $sale = $this->aggregator->recalculate($sale, );

            $this->audit->record(
                $isCorrection ? 'payment.amount_corrected' : 'payment.verified',
                'payments',
                'Verifikasi pembayaran '.$payment->uuid.' untuk transaksi '.$sale->receipt_number,
                $payment,
                $old,
                $payment->only(['status', 'amount', 'verified_amount', 'provider_reference', 'verified_by', 'verified_at']) + [
                    'reason' => $isCorrection ? $data['correction_reason'] : ($data['verification_note'] ?? null),
                    'sale_payment_status' => $sale->payment_status,
                ],
                $actor,
                $sale->business_id,
            );

            $this->sync->record(
                'payment.verified',
                'sale_payment',
                $payment->uuid,
                [
                    'sale_uuid' => $sale->uuid,
                    'payment_uuid' => $payment->uuid,
                    'status' => $payment->status,
                    'verified_amount' => $payment->verified_amount,
                    'payment_status' => $sale->payment_status,
                    'confirmed_amount' => $sale->confirmed_amount,
                    'awaiting_verification_amount' => $sale->awaiting_verification_amount,
                    'outstanding_amount' => $sale->outstanding_amount,
                ],
                $sale->business_id,
                $sale->outlet_id,
                $sale->device_id,
            );

            return $payment->refresh()->load(['sale', 'verifiedBy', 'verificationLogs.actor']);
        });
    }

    private function authorize(SalePayment $payment, User $actor): void
    {
        if (! $actor->hasPermission('payments.verify')) {
            throw new AuthorizationException('Anda tidak memiliki hak untuk memverifikasi pembayaran.');
        }

        if ((int) $payment->recorded_by === (int) $actor->id) {
            throw new AuthorizationException('Pemisahan tugas: pencatat pembayaran tidak boleh memverifikasi pembayaran yang ia catat sendiri.');
        }
    }
}
