<?php

namespace App\Actions\Payments;

use App\Models\SalePayment;
use App\Models\User;
use App\Services\AuditLogger;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\ValidationException;

class UploadPaymentProof
{
    public function __construct(private readonly AuditLogger $audit) {}

    /**
     * @return array{payment: SalePayment, created: bool}
     */
    public function handle(SalePayment $payment, UploadedFile $file, User $actor): array
    {
        if ($payment->isCash()) {
            throw ValidationException::withMessages([
                'proof' => 'Bukti pembayaran hanya berlaku untuk pembayaran non-tunai.',
            ]);
        }

        $sale = $payment->sale;
        $extension = match ($file->getMimeType()) {
            'image/png' => 'png',
            'image/webp' => 'webp',
            default => 'jpg',
        };

        $path = sprintf(
            'payment-proofs/%d/%d/%s/%s.%s',
            $sale->business_id,
            $sale->outlet_id,
            $sale->uuid,
            $payment->uuid,
            $extension,
        );

        $disk = Storage::disk('local');
        $newHash = hash_file('sha256', $file->getRealPath());
        $oldPath = $payment->proof_path;
        $hadProof = $oldPath !== null && $disk->exists($oldPath);

        if ($hadProof && hash_file('sha256', $disk->path($oldPath)) === $newHash) {
            return ['payment' => $payment, 'created' => false];
        }

        $disk->putFileAs(dirname($path), $file, basename($path));

        try {
            $stored = DB::transaction(function () use ($payment, $actor, $path) {
                $locked = SalePayment::query()->lockForUpdate()->findOrFail($payment->id);
                $old = $locked->only(['method', 'proof_path', 'proof_uploaded_at']);

                $locked->forceFill([
                    'proof_path' => $path,
                    'proof_uploaded_by' => $actor->id,
                    'proof_uploaded_at' => now(),
                ])->save();

                $this->audit->record(
                    'payment.proof_uploaded',
                    'payments',
                    'Bukti pembayaran diunggah untuk pembayaran '.$locked->uuid,
                    $locked,
                    ['has_proof' => $old['proof_path'] !== null, 'proof_uploaded_at' => $old['proof_uploaded_at']?->toIso8601String()],
                    ['has_proof' => true, 'proof_uploaded_at' => $locked->proof_uploaded_at?->toIso8601String()],
                    $actor,
                    $locked->sale->business_id,
                );

                return $locked;
            });
        } catch (\Throwable $error) {
            if ($path !== $oldPath) {
                $disk->delete($path);
            }
            throw $error;
        }

        if ($oldPath && $oldPath !== $path) {
            $disk->delete($oldPath);
        }

        return ['payment' => $stored, 'created' => ! $hadProof];
    }
}
