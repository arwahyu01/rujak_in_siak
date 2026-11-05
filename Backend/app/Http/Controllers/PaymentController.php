<?php

namespace App\Http\Controllers;

use App\Actions\Payments\RejectPayment;
use App\Actions\Payments\VerifyPayment;
use App\Http\Requests\Payments\RejectPaymentRequest;
use App\Http\Requests\Payments\VerifyPaymentRequest;
use App\Models\SalePayment;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Inertia\Response;

class PaymentController extends Controller
{
    public function pending(Request $request): Response
    {
        $this->authorize('viewAny', SalePayment::class);

        $businessId = $request->user()->business_id;
        $query = SalePayment::query()
            ->with(['sale:id,receipt_number,total,payment_status,lifecycle_status,transacted_at', 'recordedBy:id,name'])
            ->where('status', SalePayment::STATUS_AWAITING_VERIFICATION)
            ->whereHas('sale', fn ($q) => $q->where('business_id', $businessId))
            ->when(trim((string) $request->query('q')) !== '', function ($q) use ($request) {
                $search = trim((string) $request->query('q'));
                $q->where(function ($inner) use ($search) {
                    $inner->where('provider_reference', 'like', "%{$search}%")
                        ->orWhereHas('sale', fn ($sale) => $sale->where('receipt_number', 'like', "%{$search}%"));
                });
            })
            ->when($request->query('method'), fn ($q, $method) => $q->where('method', $method));

        $summary = [
            'count' => (clone $query)->count(),
            'total' => (int) (clone $query)->sum('amount'),
        ];

        $payments = $query->orderBy('recorded_at')->paginate(15)->withQueryString();

        $user = $request->user();
        $payments->through(fn (SalePayment $payment) => [
            ...$payment->toArray(),
            'can_verify' => $user->can('verify', $payment),
            'can_reject' => $user->can('reject', $payment),
            'is_own_entry' => (int) $payment->recorded_by === (int) $user->id,
        ]);

        $recent = SalePayment::query()
            ->with(['sale:id,receipt_number', 'recordedBy:id,name', 'verifiedBy:id,name', 'rejectedBy:id,name'])
            ->whereIn('status', [SalePayment::STATUS_CONFIRMED, SalePayment::STATUS_REJECTED])
            ->whereHas('sale', fn ($q) => $q->where('business_id', $businessId))
            ->orderByDesc('updated_at')
            ->limit(10)
            ->get();

        return Inertia::render('Payments/Pending', [
            'payments' => $payments,
            'summary' => $summary,
            'recent' => $recent,
            'filters' => $request->only(['q', 'method']),
            'separationOfDuties' => true,
        ]);
    }

    public function verify(VerifyPaymentRequest $request, SalePayment $payment, VerifyPayment $action): RedirectResponse
    {
        $this->authorize('verify', $payment);

        $action->handle($payment, $request->validated(), $request->user());

        return back()->with('success', 'Pembayaran berhasil diverifikasi.');
    }

    public function reject(RejectPaymentRequest $request, SalePayment $payment, RejectPayment $action): RedirectResponse
    {
        $this->authorize('reject', $payment);

        $action->handle($payment, $request->validated(), $request->user());

        return back()->with('success', 'Pembayaran ditolak dan alasan tercatat.');
    }
}
