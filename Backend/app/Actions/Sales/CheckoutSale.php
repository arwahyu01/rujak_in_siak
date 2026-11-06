<?php

namespace App\Actions\Sales;

use App\Exceptions\ApiException;
use App\Models\Device;
use App\Models\Order;
use App\Models\Sale;
use App\Models\SalePayment;
use App\Models\Shift;
use App\Models\User;
use App\Services\AuditLogger;
use App\Services\IdempotencyService;
use App\Services\OrderSnapshot;
use App\Services\PricingCalculator;
use App\Services\ReceiptNumberService;
use App\Services\SalePaymentAggregator;
use App\Services\SyncRecorder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class CheckoutSale
{
    public function __construct(
        private readonly PricingCalculator $pricing,
        private readonly ReceiptNumberService $receipts,
        private readonly SalePaymentAggregator $aggregator,
        private readonly OrderSnapshot $snapshots,
        private readonly IdempotencyService $idempotency,
        private readonly AuditLogger $audit,
        private readonly SyncRecorder $sync,
    ) {}

    public function handle(
        array $data,
        User $actor,
        Device $device,
        ?string $idempotencyKey = null,
        ?string $requestFingerprint = null,
    ): Sale {
        return DB::transaction(function () use ($data, $actor, $device, $idempotencyKey, $requestFingerprint) {
            $order = Order::query()
                ->with(['items.modifiers', 'business', 'outlet', 'shift'])
                ->where('uuid', $data['order_uuid'])
                ->where('business_id', $actor->business_id)
                ->lockForUpdate()
                ->first();

            if (! $order) {
                throw ApiException::notFound('Order tidak ditemukan.');
            }

            if ((int) $order->outlet_id !== (int) $device->outlet_id) {
                throw ApiException::forbidden('Order bukan milik outlet perangkat ini.');
            }

            if ($order->status === Order::STATUS_CONVERTED || $order->sale()->exists()) {
                $saleUuid = $order->sale()->value('uuid');
                throw ApiException::conflict(
                    'ORDER_ALREADY_CONVERTED',
                    'Order ini sudah menghasilkan sale. Muat transaksi yang sudah ada.',
                    ['sale_uuid' => $saleUuid],
                );
            }

            if ($order->status === Order::STATUS_CANCELLED) {
                throw ApiException::conflict('ORDER_CANCELLED', 'Order yang dibatalkan tidak dapat di-checkout.');
            }

            if ($order->status === Order::STATUS_HELD) {
                throw ApiException::conflict('ORDER_HELD', 'Resume held order sebelum checkout.');
            }

            if (! $order->isEditable()) {
                throw ApiException::conflict('ORDER_NOT_CHECKOUTABLE', 'Status order tidak dapat di-checkout.');
            }

            $baseVersion = (int) $data['base_version'];
            if ($baseVersion !== (int) $order->version) {
                throw ApiException::conflict(
                    'ORDER_VERSION_MISMATCH',
                    'Order telah diubah pada perangkat lain. Muat ulang sebelum checkout.',
                    ['current_version' => (int) $order->version, 'base_version' => $baseVersion],
                );
            }

            $shift = Shift::query()->lockForUpdate()->find($order->shift_id);
            if (! $shift || $shift->status !== Shift::STATUS_OPEN) {
                throw new ApiException('SHIFT_NOT_OPEN', 'Shift order tidak aktif. Buka shift baru sebelum checkout.', 422);
            }

            if ((int) $shift->device_id !== (int) $device->id) {
                throw ApiException::forbidden('Shift bukan milik perangkat ini.');
            }

            if ($order->items->isEmpty()) {
                throw new ApiException('ORDER_EMPTY', 'Order tidak memiliki item.', 422);
            }

            $config = $order->pricing_snapshot['config'] ?? [
                'tax_enabled' => $order->business->tax_enabled,
                'tax_rate_basis_points' => $order->business->tax_rate_basis_points,
                'service_charge_enabled' => $order->business->service_charge_enabled,
                'service_charge_rate_basis_points' => $order->business->service_charge_rate_basis_points,
                'tax_includes_service_charge' => $order->business->tax_includes_service_charge,
            ];

            $calculated = $this->pricing->calculate(
                $order->items->map(fn ($item) => [
                    'unit_price' => (int) $item->unit_price,
                    'quantity' => (int) $item->quantity,
                    'item_discount' => (int) $item->item_discount,
                    'tax_rate_basis_points' => (int) $item->tax_rate_basis_points,
                ])->all(),
                $config,
                (int) $order->transaction_discount_total,
            );

            $payments = $this->validatePayments($data['payments'] ?? [], $calculated['total']);
            $receiptNumber = $this->receipts->next($order->outlet, $device->terminal_code);

            $sale = Sale::create([
                'business_id' => $order->business_id,
                'outlet_id' => $order->outlet_id,
                'shift_id' => $shift->id,
                'user_id' => $actor->id,
                'device_id' => $device->id,
                'source_order_id' => $order->id,
                'source_order_version' => $baseVersion,
                'origin' => 'online',
                'receipt_number' => $receiptNumber,
                'order_type' => $order->order_type,
                'table_number' => $order->table_number,
                'lifecycle_status' => Sale::LIFECYCLE_FINALIZED,
                'payment_status' => Sale::PAYMENT_UNPAID,
                'subtotal' => $calculated['subtotal'],
                'item_discount_total' => $calculated['item_discount_total'],
                'transaction_discount_total' => $calculated['transaction_discount_total'],
                'discount_total' => $calculated['discount_total'],
                'service_charge' => $calculated['service_charge'],
                'tax_total' => $calculated['tax_total'],
                'total' => $calculated['total'],
                'confirmed_amount' => 0,
                'awaiting_verification_amount' => 0,
                'outstanding_amount' => $calculated['total'],
                'refunded_amount' => 0,
                'notes' => $data['notes'] ?? $order->notes,
                'source_order_uuid' => $order->uuid,
                'pricing_snapshot' => [
                    'config' => $calculated['config'],
                    'lines' => $calculated['lines'],
                    'calculated_at' => now()->toIso8601String(),
                ],
                'transacted_at' => now(),
            ]);

            foreach ($order->items as $index => $item) {
                $line = $calculated['lines'][$index];
                $sale->items()->create([
                    'source_order_item_id' => $item->id,
                    'product_id' => $item->product_id,
                    'product_uuid' => $item->product_uuid,
                    'sku' => $item->sku,
                    'product_name' => $item->product_name,
                    'variant_uuid' => $item->variant_uuid,
                    'variant_name' => $item->variant_name,
                    'addon_summary' => collect($item->addons ?? [])->pluck('name')->implode(', '),
                    'unit_price' => (int) $item->unit_price,
                    'quantity' => (int) $item->quantity,
                    'discount_amount' => $line['discount_amount'],
                    'tax_rate_basis_points' => $line['tax_rate_basis_points'],
                    'tax_amount' => $line['tax_amount'],
                    'service_charge_amount' => $line['service_charge_amount'],
                    'subtotal' => $line['gross'],
                    'total' => $line['total'],
                    'snapshot' => [
                        ...($item->snapshot ?? []),
                        'transaction_discount_allocation' => $line['transaction_discount_allocation'],
                        'taxable_base' => $line['taxable_base'],
                    ],
                ]);
            }

            foreach ($payments as $payment) {
                $sale->payments()->create([
                    'uuid' => $payment['uuid'],
                    'idempotency_key' => $payment['idempotency_key'],
                    'method' => $payment['method'],
                    'amount' => $payment['amount'],
                    'tendered_amount' => $payment['tendered_amount'],
                    'change_amount' => $payment['change_amount'],
                    'verified_amount' => $payment['status'] === SalePayment::STATUS_CONFIRMED ? $payment['amount'] : null,
                    'status' => $payment['status'],
                    'provider_reference' => $payment['provider_reference'],
                    'notes' => $payment['notes'],
                    'origin' => 'online',
                    'recorded_by' => $actor->id,
                    'recorded_at' => now(),
                    'verified_by' => $payment['status'] === SalePayment::STATUS_CONFIRMED ? $actor->id : null,
                    'verified_at' => $payment['status'] === SalePayment::STATUS_CONFIRMED ? now() : null,
                ]);
            }

            $sale = $this->aggregator->recalculate($sale);

            $originalStatus = $order->status;
            $version = $baseVersion + 1;
            $order->update([
                'status' => Order::STATUS_CONVERTED,
                'version' => $version,
                'converted_at' => now(),
                'subtotal' => $calculated['subtotal'],
                'item_discount_total' => $calculated['item_discount_total'],
                'transaction_discount_total' => $calculated['transaction_discount_total'],
                'discount_total' => $calculated['discount_total'],
                'service_charge' => $calculated['service_charge'],
                'tax_total' => $calculated['tax_total'],
                'total' => $calculated['total'],
            ]);

            $order->statusHistories()->create([
                'from_status' => $originalStatus,
                'to_status' => Order::STATUS_CONVERTED,
                'actor_user_id' => $actor->id,
                'version' => $version,
                'created_at' => now(),
            ]);

            $this->audit->record(
                'sale.finalized',
                'sales',
                'Checkout '.$sale->receipt_number.' dari order '.$order->order_number,
                $sale,
                [],
                [
                    'receipt_number' => $sale->receipt_number,
                    'total' => $sale->total,
                    'payment_status' => $sale->payment_status,
                    'confirmed_amount' => $sale->confirmed_amount,
                    'awaiting_verification_amount' => $sale->awaiting_verification_amount,
                    'source_order_uuid' => $order->uuid,
                ],
                $actor,
                $order->business_id,
            );

            $this->sync->record(
                'sale.finalized',
                'sale',
                $sale->uuid,
                $this->salePayload($sale),
                $order->business_id,
                $order->outlet_id,
                $device->id,
                aggregateVersion: 1,
                baseVersion: null,
            );

            $this->sync->record(
                'order.converted',
                'order',
                $order->uuid,
                $this->snapshots->payload($order->fresh(['items.modifiers', 'shift', 'device', 'cashier'])),
                $order->business_id,
                $order->outlet_id,
                $device->id,
                aggregateVersion: $version,
                baseVersion: $baseVersion,
            );

            if ($idempotencyKey) {
                $this->idempotency->store(
                    $order->business_id,
                    'sales.checkout',
                    $idempotencyKey,
                    ['fingerprint' => $requestFingerprint, 'data' => $data],
                    201,
                    ['sale_uuid' => $sale->uuid],
                    $actor->id,
                    $device->id,
                    'sale',
                    $sale->uuid,
                );
            }

            return $sale->refresh()->load([
                'items', 'payments.recordedBy', 'payments.verifiedBy', 'cashier', 'device', 'shift', 'outlet', 'refunds',
            ]);
        });
    }

    private function validatePayments(array $payments, int $total): array
    {
        $validated = [];
        $sum = 0;

        foreach ($payments as $payment) {
            $method = (string) ($payment['method'] ?? '');
            $amount = (int) ($payment['amount'] ?? 0);

            if (! in_array($method, [
                SalePayment::METHOD_CASH,
                SalePayment::METHOD_QRIS,
                SalePayment::METHOD_TRANSFER,
                SalePayment::METHOD_EWALLET,
            ], true)) {
                throw new ApiException('PAYMENT_METHOD_INVALID', 'Metode pembayaran tidak valid.', 422);
            }

            if ($amount <= 0) {
                throw new ApiException('PAYMENT_AMOUNT_INVALID', 'Nominal pembayaran harus lebih besar dari nol.', 422);
            }

            $sum += $amount;
            if ($sum > $total) {
                throw new ApiException('PAYMENT_EXCEEDS_TOTAL', 'Total pembayaran melebihi nilai transaksi.', 422);
            }

            if ($method === SalePayment::METHOD_CASH) {
                $tendered = (int) ($payment['tendered_amount'] ?? $amount);
                if ($tendered < $amount) {
                    throw new ApiException('CASH_TENDERED_INSUFFICIENT', 'Uang tunai diterima kurang dari nominal pembayaran.', 422);
                }
                $status = SalePayment::STATUS_CONFIRMED;
                $change = $tendered - $amount;
            } else {
                $tendered = null;
                $change = 0;
                $status = SalePayment::STATUS_AWAITING_VERIFICATION;
                if (empty($payment['provider_reference'])) {
                    throw new ApiException('PROVIDER_REFERENCE_REQUIRED', 'Referensi pembayaran non-tunai wajib diisi.', 422);
                }
            }

            $validated[] = [
                'uuid' => (string) Str::uuid(),
                'idempotency_key' => $payment['idempotency_key'] ?? null,
                'method' => $method,
                'amount' => $amount,
                'tendered_amount' => $tendered,
                'change_amount' => $change,
                'status' => $status,
                'provider_reference' => $payment['provider_reference'] ?? null,
                'notes' => $payment['notes'] ?? null,
            ];
        }

        return $validated;
    }

    private function salePayload(Sale $sale): array
    {
        $sale->loadMissing(['items', 'payments']);

        return [
            'sale_uuid' => $sale->uuid,
            'receipt_number' => $sale->receipt_number,
            'source_order_uuid' => $sale->source_order_uuid,
            'lifecycle_status' => $sale->lifecycle_status,
            'payment_status' => $sale->payment_status,
            'subtotal' => (int) $sale->subtotal,
            'discount_total' => (int) $sale->discount_total,
            'service_charge' => (int) $sale->service_charge,
            'tax_total' => (int) $sale->tax_total,
            'total' => (int) $sale->total,
            'confirmed_amount' => (int) $sale->confirmed_amount,
            'awaiting_verification_amount' => (int) $sale->awaiting_verification_amount,
            'outstanding_amount' => (int) $sale->outstanding_amount,
            'refunded_amount' => (int) $sale->refunded_amount,
            'transacted_at' => $sale->transacted_at?->toIso8601String(),
            'shift_uuid' => $sale->shift?->uuid,
            'device_uuid' => $sale->device?->uuid,
            'payments' => $sale->payments->map(fn (SalePayment $payment) => [
                'payment_uuid' => $payment->uuid,
                'method' => $payment->method,
                'amount' => (int) $payment->amount,
                'tendered_amount' => $payment->tendered_amount,
                'change_amount' => (int) $payment->change_amount,
                'status' => $payment->status,
                'provider_reference' => $payment->provider_reference,
            ])->all(),
        ];
    }
}
