<?php

namespace App\Console\Commands;

use App\Models\PaymentVerificationLog;
use App\Models\Sale;
use App\Models\SalePayment;
use App\Services\AuditLogger;
use App\Services\SalePaymentAggregator;
use App\Services\SyncRecorder;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Throwable;

class ConfirmOwnerPendingPayments extends Command
{
    protected $signature = 'payments:confirm-owner-pending
        {--dry-run : Hitung data yang akan diperbaiki tanpa mengubah database}
        {--chunk=100 : Jumlah pembayaran per batch}';

    protected $description = 'Konfirmasi pembayaran non-tunai lama yang masih menunggu verifikasi tetapi dicatat oleh Owner.';

    public function handle(
        SalePaymentAggregator $aggregator,
        AuditLogger $audit,
        SyncRecorder $sync,
    ): int {
        $dryRun = (bool) $this->option('dry-run');
        $chunkSize = max((int) $this->option('chunk'), 1);

        $query = SalePayment::query()
            ->where('status', SalePayment::STATUS_AWAITING_VERIFICATION)
            ->where('method', '!=', SalePayment::METHOD_CASH)
            ->whereHas('recordedBy.roles', fn ($roles) => $roles->where('slug', 'owner'))
            ->whereHas('sale', fn ($sale) => $sale->where('lifecycle_status', Sale::LIFECYCLE_FINALIZED));

        $count = (clone $query)->count();
        $total = (int) (clone $query)->sum('amount');

        $this->info(sprintf(
            '%s %d pembayaran non-tunai milik Owner dengan total Rp%s.',
            $dryRun ? 'Ditemukan' : 'Akan memproses',
            $count,
            number_format($total, 0, ',', '.'),
        ));

        if ($dryRun) {
            $this->info('Dry run selesai. Tidak ada data yang diubah.');

            return self::SUCCESS;
        }

        if ($count === 0) {
            $this->info('Tidak ada data yang perlu diperbaiki.');

            return self::SUCCESS;
        }

        $processed = 0;
        $skipped = 0;
        $failed = 0;

        $query->select('id')->chunkById($chunkSize, function ($payments) use (
            $aggregator,
            $audit,
            $sync,
            &$processed,
            &$skipped,
            &$failed,
        ) {
            foreach ($payments as $row) {
                try {
                    $confirmed = DB::transaction(function () use ($row, $aggregator, $audit, $sync) {
                        $payment = SalePayment::query()
                            ->with(['recordedBy.roles', 'sale'])
                            ->lockForUpdate()
                            ->find($row->id);

                        if (! $payment || ! $payment->sale) {
                            return false;
                        }

                        if ($payment->status !== SalePayment::STATUS_AWAITING_VERIFICATION
                            || $payment->method === SalePayment::METHOD_CASH) {
                            return false;
                        }

                        $owner = $payment->recordedBy;
                        if (! $owner?->isOwner()) {
                            return false;
                        }

                        $sale = Sale::query()->lockForUpdate()->find($payment->sale_id);
                        if (! $sale || $sale->lifecycle_status !== Sale::LIFECYCLE_FINALIZED) {
                            return false;
                        }

                        $old = $payment->only([
                            'status', 'amount', 'verified_amount', 'verified_by', 'verified_at',
                        ]);

                        $verifiedAt = $payment->verified_at ?? $payment->recorded_at ?? now();

                        $payment->forceFill([
                            'status' => SalePayment::STATUS_CONFIRMED,
                            'verified_amount' => (int) $payment->amount,
                            'verified_by' => $owner->id,
                            'verified_at' => $verifiedAt,
                        ])->save();

                        PaymentVerificationLog::create([
                            'sale_payment_id' => $payment->id,
                            'action' => 'auto_confirmed',
                            'actor_id' => $owner->id,
                            'recorded_amount' => (int) $payment->amount,
                            'verified_amount' => (int) $payment->amount,
                            'reason' => 'Koreksi data historis: pembayaran non-tunai dicatat oleh Owner.',
                            'provider_reference' => $payment->provider_reference,
                        ]);

                        $sale = $aggregator->recalculate($sale);

                        $audit->record(
                            'payment.auto_confirmed',
                            'payments',
                            'Konfirmasi otomatis pembayaran '.$payment->uuid.' untuk transaksi '.$sale->receipt_number,
                            $payment,
                            $old,
                            $payment->only([
                                'status', 'amount', 'verified_amount', 'verified_by', 'verified_at',
                            ]) + [
                                'reason' => 'Koreksi data historis pembayaran Owner.',
                                'sale_payment_status' => $sale->payment_status,
                            ],
                            null,
                            $sale->business_id,
                        );

                        $sync->record(
                            'payment.verified',
                            'sale_payment',
                            $payment->uuid,
                            [
                                'sale_uuid' => $sale->uuid,
                                'payment_uuid' => $payment->uuid,
                                'status' => $payment->status,
                                'verified_amount' => (int) $payment->verified_amount,
                                'payment_status' => $sale->payment_status,
                                'confirmed_amount' => (int) $sale->confirmed_amount,
                                'awaiting_verification_amount' => (int) $sale->awaiting_verification_amount,
                                'outstanding_amount' => (int) $sale->outstanding_amount,
                            ],
                            $sale->business_id,
                            $sale->outlet_id,
                            $sale->device_id,
                        );

                        return true;
                    });

                    $confirmed ? $processed++ : $skipped++;
                } catch (Throwable $exception) {
                    $failed++;
                    $this->error('Gagal memperbaiki pembayaran #'.$row->id.': '.$exception->getMessage());
                }
            }
        });

        $this->info(sprintf(
            'Selesai. Dikonfirmasi: %d, dilewati: %d, gagal: %d.',
            $processed,
            $skipped,
            $failed,
        ));

        return $failed > 0 ? self::FAILURE : self::SUCCESS;
    }
}
