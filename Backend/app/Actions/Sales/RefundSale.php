<?php

namespace App\Actions\Sales;

use App\Models\Refund;
use App\Models\Sale;
use App\Models\User;
use App\Services\AuditLogger;
use App\Services\SalePaymentAggregator;
use App\Services\SyncRecorder;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class RefundSale
{
    public function __construct(
        private readonly SalePaymentAggregator $aggregator,
        private readonly AuditLogger $audit,
        private readonly SyncRecorder $sync,
    ) {
    }

    public function handle(Sale $sale, array $data, User $actor): Sale
    {
        return DB::transaction(function () use ($sale, $data, $actor) {
            $sale = Sale::query()->lockForUpdate()->findOrFail($sale->id);

            if (! $actor->hasPermission('sales.refund')) {
                throw new AuthorizationException('Anda tidak memiliki hak untuk melakukan refund.');
            }

            if ($sale->lifecycle_status !== Sale::LIFECYCLE_FINALIZED) {
                throw ValidationException::withMessages([
                    'sale' => 'Transaksi yang sudah di-void tidak dapat direfund.',
                ]);
            }

            $this->aggregator->recalculate($sale);
            $sale->refresh();

            $available = max((int) $sale->confirmed_amount - (int) $sale->refunded_amount, 0);

            if ($available <= 0) {
                throw ValidationException::withMessages([
                    'amount' => 'Tidak ada dana terkonfirmasi yang dapat direfund.',
                ]);
            }

            $amount = (int) $data['amount'];
            if ($amount <= 0 || $amount > $available) {
                throw ValidationException::withMessages([
                    'amount' => 'Nominal refund harus lebih dari nol dan tidak boleh melebihi dana terkonfirmasi yang belum direfund (Rp '.number_format($available, 0, ',', '.').').',
                ]);
            }

            $refund = Refund::create([
                'sale_id' => $sale->id,
                'amount' => $amount,
                'reason' => $data['reason'],
                'created_by' => $actor->id,
                'refunded_at' => now(),
            ]);

            $sale = $this->aggregator->recalculate($sale);

            $this->audit->record(
                'sale.refunded',
                'sales',
                'Refund transaksi '.$sale->receipt_number.' sebesar Rp '.number_format($amount, 0, ',', '.'),
                $sale,
                ['refunded_amount' => $sale->refunded_amount - $amount, 'payment_status' => $sale->payment_status],
                ['refunded_amount' => $sale->refunded_amount, 'payment_status' => $sale->payment_status, 'reason' => $data['reason']],
                $actor,
                $sale->business_id,
            );

            $this->sync->record(
                'sale.refunded',
                'sale',
                $sale->uuid,
                [
                    'sale_uuid' => $sale->uuid,
                    'refund_uuid' => $refund->uuid,
                    'amount' => $amount,
                    'reason' => $data['reason'],
                    'payment_status' => $sale->payment_status,
                    'refunded_amount' => $sale->refunded_amount,
                ],
                $sale->business_id,
                $sale->outlet_id,
                $sale->device_id,
            );

            return $sale->refresh()->load(['cashier', 'items', 'payments', 'refunds.createdBy']);
        });
    }
}
