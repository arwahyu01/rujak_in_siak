<?php

namespace App\Actions\Sales;

use App\Models\Sale;
use App\Models\SalePayment;
use App\Models\User;
use App\Services\AuditLogger;
use App\Services\SalePaymentAggregator;
use App\Services\SyncRecorder;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class VoidSale
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

            if (! $actor->hasPermission('sales.void')) {
                throw new AuthorizationException('Anda tidak memiliki hak untuk melakukan void.');
            }

            if ($sale->lifecycle_status !== Sale::LIFECYCLE_FINALIZED) {
                throw ValidationException::withMessages([
                    'sale' => 'Transaksi ini sudah tidak berstatus final dan tidak dapat di-void.',
                ]);
            }

            $this->aggregator->recalculate($sale);
            $sale->refresh();

            if ((int) $sale->awaiting_verification_amount > 0) {
                throw ValidationException::withMessages([
                    'sale' => 'Transaksi memiliki pembayaran menunggu verifikasi. Tolak pembayaran tersebut terlebih dahulu sebelum void.',
                ]);
            }

            if ((int) $sale->confirmed_amount > 0) {
                throw ValidationException::withMessages([
                    'sale' => 'Transaksi sudah memiliki pembayaran terkonfirmasi. Gunakan proses refund, bukan void.',
                ]);
            }

            if ($sale->payments()->where('status', SalePayment::STATUS_CONFIRMED)->exists()) {
                throw ValidationException::withMessages([
                    'sale' => 'Transaksi sudah memiliki pembayaran terkonfirmasi. Gunakan proses refund, bukan void.',
                ]);
            }

            $old = $sale->only(['lifecycle_status', 'payment_status', 'voided_at', 'voided_by', 'void_reason']);

            $sale->forceFill([
                'lifecycle_status' => Sale::LIFECYCLE_VOIDED,
                'payment_status' => Sale::PAYMENT_CANCELLED,
                'voided_at' => now(),
                'voided_by' => $actor->id,
                'void_reason' => $data['reason'],
            ])->save();

            $this->audit->record(
                'sale.voided',
                'sales',
                'Void transaksi '.$sale->receipt_number,
                $sale,
                $old,
                $sale->only(['lifecycle_status', 'payment_status', 'voided_at', 'voided_by', 'void_reason']),
                $actor,
                $sale->business_id,
            );

            $this->sync->record(
                'sale.voided',
                'sale',
                $sale->uuid,
                [
                    'sale_uuid' => $sale->uuid,
                    'receipt_number' => $sale->receipt_number,
                    'reason' => $sale->void_reason,
                    'lifecycle_status' => $sale->lifecycle_status,
                    'payment_status' => $sale->payment_status,
                ],
                $sale->business_id,
                $sale->outlet_id,
                $sale->device_id,
            );

            return $sale->refresh()->load(['cashier', 'voidedBy', 'items', 'payments']);
        });
    }
}
