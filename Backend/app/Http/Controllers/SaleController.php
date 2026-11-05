<?php

namespace App\Http\Controllers;

use App\Actions\Sales\RefundSale;
use App\Actions\Sales\VoidSale;
use App\Http\Requests\Sales\RefundSaleRequest;
use App\Http\Requests\Sales\VoidSaleRequest;
use App\Models\AuditLog;
use App\Models\Sale;
use App\Models\SalePayment;
use App\Models\User;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Inertia\Inertia;
use Inertia\Response;

class SaleController extends Controller
{
    public function index(Request $request): Response
    {
        $this->authorize('viewAny', Sale::class);

        $businessId = $request->user()->business_id;
        $query = Sale::query()
            ->where('business_id', $businessId)
            ->with(['cashier:id,name', 'outlet:id,name'])
            ->when(trim((string) $request->query('q')) !== '', function ($q) use ($request) {
                $search = trim((string) $request->query('q'));
                $q->where(function ($inner) use ($search) {
                    $inner->where('receipt_number', 'like', "%{$search}%")
                        ->orWhere('table_number', 'like', "%{$search}%");
                });
            })
            ->when($request->query('payment_status'), fn ($q, $status) => $q->where('payment_status', $status))
            ->when($request->query('lifecycle_status'), fn ($q, $status) => $q->where('lifecycle_status', $status))
            ->when($request->query('cashier_id'), fn ($q, $cashier) => $q->where('user_id', $cashier))
            ->when($request->query('date_from'), fn ($q, $date) => $q->where('transacted_at', '>=', Carbon::parse($date)->startOfDay()))
            ->when($request->query('date_to'), fn ($q, $date) => $q->where('transacted_at', '<=', Carbon::parse($date)->endOfDay()));

        $summaryQuery = clone $query;
        $summary = [
            'count' => (clone $summaryQuery)->count(),
            'total' => (int) (clone $summaryQuery)->sum('total'),
            'paid' => (int) (clone $summaryQuery)->where('payment_status', Sale::PAYMENT_PAID)->sum('total'),
            'awaiting' => (int) (clone $summaryQuery)->sum('awaiting_verification_amount'),
            'voided' => (clone $summaryQuery)->where('lifecycle_status', Sale::LIFECYCLE_VOIDED)->count(),
        ];

        return Inertia::render('Sales/Index', [
            'sales' => $query->orderByDesc('transacted_at')->paginate(15)->withQueryString(),
            'summary' => $summary,
            'cashiers' => User::query()
                ->where('business_id', $businessId)
                ->orderBy('name')
                ->get(['id', 'name']),
            'filters' => $request->only(['q', 'payment_status', 'lifecycle_status', 'cashier_id', 'date_from', 'date_to']),
        ]);
    }

    public function show(Request $request, Sale $sale): Response
    {
        $this->authorize('view', $sale);

        $sale->load([
            'cashier:id,name,email',
            'outlet:id,name,code',
            'device:id,name,terminal_code',
            'shift:id,uuid,status,opened_at,closed_at',
            'items.product:id,name,image_path',
            'payments.recordedBy:id,name',
            'payments.verifiedBy:id,name',
            'payments.rejectedBy:id,name',
            'payments.verificationLogs.actor:id,name',
            'refunds.createdBy:id,name',
            'voidedBy:id,name',
        ]);

        $paymentIds = $sale->payments->pluck('id')->all();
        $auditTrail = AuditLog::query()
            ->with('user:id,name')
            ->where(function ($query) use ($sale, $paymentIds) {
                $query->where(function ($inner) use ($sale) {
                    $inner->where('auditable_type', Sale::class)->where('auditable_id', (string) $sale->id);
                })->orWhere(function ($inner) use ($paymentIds) {
                    $inner->where('auditable_type', SalePayment::class)->whereIn('auditable_id', array_map('strval', $paymentIds));
                });
            })
            ->orderByDesc('created_at')
            ->limit(50)
            ->get();

        $confirmed = (int) $sale->confirmed_amount;
        $refunded = (int) $sale->refunded_amount;
        $canVoid = $request->user()->can('void', $sale);
        $canRefund = $request->user()->can('refund', $sale);

        $voidBlockedReason = null;
        if (! $canVoid) {
            $voidBlockedReason = $request->user()->hasPermission('sales.void')
                ? 'Anda tidak memiliki otoritas pada transaksi ini.'
                : 'Anda tidak memiliki permission void.';
        } elseif ($sale->lifecycle_status !== Sale::LIFECYCLE_FINALIZED) {
            $voidBlockedReason = 'Transaksi sudah di-void.';
        } elseif ((int) $sale->awaiting_verification_amount > 0) {
            $voidBlockedReason = 'Tolak pembayaran yang masih menunggu verifikasi terlebih dahulu.';
        } elseif ($confirmed > 0) {
            $voidBlockedReason = 'Pembayaran sudah terkonfirmasi. Gunakan refund, bukan void.';
        }

        return Inertia::render('Sales/Show', [
            'sale' => $sale,
            'auditTrail' => $auditTrail,
            'abilities' => [
                'void' => $canVoid && $voidBlockedReason === null,
                'refund' => $canRefund && ($confirmed - $refunded) > 0,
            ],
            'voidBlockedReason' => $voidBlockedReason,
            'refundableAmount' => max($confirmed - $refunded, 0),
        ]);
    }

    public function void(VoidSaleRequest $request, Sale $sale, VoidSale $action): RedirectResponse
    {
        $this->authorize('void', $sale);

        $action->handle($sale, $request->validated(), $request->user());

        return back()->with('success', 'Transaksi berhasil di-void.');
    }

    public function refund(RefundSaleRequest $request, Sale $sale, RefundSale $action): RedirectResponse
    {
        $this->authorize('refund', $sale);

        $action->handle($sale, $request->validated(), $request->user());

        return back()->with('success', 'Refund berhasil dicatat.');
    }
}
