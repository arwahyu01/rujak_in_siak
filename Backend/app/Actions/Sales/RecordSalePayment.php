<?php

namespace App\Actions\Sales;

use App\Exceptions\ApiException;
use App\Models\Sale;
use App\Models\SalePayment;
use App\Models\User;
use App\Services\AuditLogger;
use App\Services\IdempotencyService;
use App\Services\SalePaymentAggregator;
use App\Services\SyncRecorder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class RecordSalePayment
{
    public function __construct(
        private readonly SalePaymentAggregator $aggregator,
        private readonly IdempotencyService $idempotency,
        private readonly AuditLogger $audit,
        private readonly SyncRecorder $sync,
    ) {}

    public function handle(Sale $sale, array $data, User $actor, ?int $deviceId, ?string $idempotencyKey = null): Sale
    {
        return DB::transaction(function () use ($sale, $data, $actor, $deviceId, $idempotencyKey) {
            $sale = Sale::query()->lockForUpdate()->findOrFail($sale->id);

            if ((int) $sale->business_id !== (int) $actor->business_id) {
                throw ApiException::notFound();
            }

            if ($sale->lifecycle_status !== Sale::LIFECYCLE_FINALIZED) {
                throw ApiException::conflict('SALE_VOIDED', 'Pembayaran tidak dapat dicatat pada sale yang telah di-void.');
            }

            $sale = $this->aggregator->recalculate($sale);
            $outstanding = (int) $sale->outstanding_amount;
            $amount = (int) $data['amount'];

            if ($outstanding <= 0) {
                throw ApiException::conflict('SALE_FULLY_PAID', 'Transaksi sudah tidak memiliki outstanding amount.');
            }

            if ($amount <= 0 || $amount > $outstanding) {
                throw ApiException::conflict(
                    'PAYMENT_EXCEEDS_OUTSTANDING',
                    'Nominal pembayaran harus lebih dari nol dan tidak melebihi outstanding.',
                    ['outstanding_amount' => $outstanding],
                );
            }

            $method = (string) $data['method'];
            $isCash = $method === SalePayment::METHOD_CASH;
            $tendered = $isCash ? (int) ($data['tendered_amount'] ?? $amount) : null;
            if ($isCash && $tendered < $amount) {
                throw new ApiException('CASH_TENDERED_INSUFFICIENT', 'Uang tunai diterima kurang dari nominal pembayaran.', 422);
            }

            $confirmed = $isCash || $actor->isOwner();
            $proofRequired = ! $isCash
                && ! $actor->isOwner()
                && (bool) $actor->business?->non_cash_proof_required;
            $payment = $sale->payments()->create([
                'uuid' => (string) Str::uuid(),
                'idempotency_key' => $idempotencyKey,
                'method' => $method,
                'amount' => $amount,
                'tendered_amount' => $tendered,
                'change_amount' => $isCash ? $tendered - $amount : 0,
                'verified_amount' => $confirmed ? $amount : null,
                'status' => $confirmed
                    ? SalePayment::STATUS_CONFIRMED
                    : SalePayment::STATUS_AWAITING_VERIFICATION,
                'provider_reference' => $data['provider_reference'] ?? null,
                'notes' => $data['notes'] ?? null,
                'proof_required' => $proofRequired,
                'origin' => 'online',
                'recorded_by' => $actor->id,
                'recorded_at' => now(),
                'verified_by' => $confirmed ? $actor->id : null,
                'verified_at' => $confirmed ? now() : null,
            ]);

            $sale = $this->aggregator->recalculate($sale);

            $this->audit->record(
                'payment.recorded',
                'payments',
                'Mencatat pembayaran '.$payment->uuid.' untuk '.$sale->receipt_number,
                $payment,
                [],
                $payment->only(['method', 'amount', 'tendered_amount', 'change_amount', 'status', 'provider_reference']),
                $actor,
                $sale->business_id,
            );

            $this->sync->record(
                'payment.recorded',
                'sale_payment',
                $payment->uuid,
                [
                    'sale_uuid' => $sale->uuid,
                    'payment_uuid' => $payment->uuid,
                    'method' => $payment->method,
                    'amount' => (int) $payment->amount,
                    'tendered_amount' => $payment->tendered_amount,
                    'change_amount' => (int) $payment->change_amount,
                    'status' => $payment->status,
                    'provider_reference' => $payment->provider_reference,
                    'proof_required' => (bool) $payment->proof_required,
                    'payment_status' => $sale->payment_status,
                    'outstanding_amount' => $sale->outstanding_amount,
                ],
                $sale->business_id,
                $sale->outlet_id,
                $deviceId ?? $sale->device_id,
                aggregateVersion: 1,
            );

            if ($idempotencyKey) {
                $this->idempotency->store(
                    $sale->business_id,
                    'sales.payments.record',
                    $idempotencyKey,
                    $data,
                    201,
                    ['sale_uuid' => $sale->uuid, 'payment_uuid' => $payment->uuid],
                    $actor->id,
                    $deviceId,
                    'sale_payment',
                    $payment->uuid,
                );
            }

            return $sale->refresh()->load([
                'items', 'payments.recordedBy', 'payments.verifiedBy', 'cashier', 'device', 'shift', 'outlet', 'refunds',
            ]);
        });
    }
}
