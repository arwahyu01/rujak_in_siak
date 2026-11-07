<?php

namespace App\Services;

use App\Actions\Shifts\CloseShift;
use App\Exceptions\ApiException;
use App\Models\Device;
use App\Models\Order;
use App\Models\Outlet;
use App\Models\Product;
use App\Models\Sale;
use App\Models\SalePayment;
use App\Models\Shift;
use App\Models\User;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

/**
 * Applies an already validated device event inside a per-event transaction.
 * Monetary snapshots are validated for arithmetic integrity but never
 * re-priced against the current catalog, because the sale price is historical.
 */
class SyncEventApplier
{
    public function __construct(
        private readonly SalePaymentAggregator $aggregator,
        private readonly ReceiptNumberService $receipts,
        private readonly OrderNumberService $orderNumbers,
        private readonly ShiftSummaryService $shiftSummary,
        private readonly ShiftSyncCoordinator $shifts,
    ) {}

    /**
     * @return array{status: string, server_record_id: ?string, error_code?: string, message?: string}
     */
    public function apply(array $event, User $actor, Device $device, ?string $leaseUuid = null): array
    {
        $type = (string) $event['event_type'];
        $payload = $event['payload'] ?? [];

        $requiredPermission = $this->requiredPermission($type);
        if ($requiredPermission && ! $actor->hasPermission($requiredPermission)) {
            throw new ApiException('FORBIDDEN', "Tidak memiliki permission {$requiredPermission} untuk event {$type}.", 403);
        }

        return DB::transaction(function () use ($type, $payload, $actor, $device, $event) {
            return match ($type) {
                'order.created' => $this->createOrder($payload, $actor, $device),
                'order.updated' => $this->updateOrder($payload, $actor, $device, (string) $event['event_type']),
                'order.held', 'order.resumed', 'order.cancelled' => $this->transitionOrder($payload, $actor, $device, $type),
                'order.converted' => $this->convertOrder($payload, $actor, $device),
                'sale.finalized' => $this->finalizeSale($payload, $actor, $device),
                'sale.voided' => $this->voidSale($payload, $actor, $device),
                'payment.recorded', 'payment.verification_requested' => $this->recordPayment(
                    $payload,
                    $actor,
                    $device,
                    $type === 'payment.verification_requested',
                ),
                'shift.opened' => $this->openShift($payload, $actor, $device),
                'shift.cash_movement' => $this->recordCashMovement($payload, $actor, $device),
                'shift.closed' => $this->closeShift($payload, $actor, $device),
                default => throw new ApiException('EVENT_TYPE_UNSUPPORTED', 'Tipe event tidak didukung.', 422),
            };
        });
    }

    public function requiredPermission(string $eventType): ?string
    {
        return match (true) {
            str_starts_with($eventType, 'order.') => 'orders.manage',
            $eventType === 'sale.finalized' => 'sales.checkout',
            $eventType === 'sale.voided' => 'sales.void',
            str_starts_with($eventType, 'payment.') => 'payments.record',
            str_starts_with($eventType, 'shift.') => 'shifts.manage',
            default => null,
        };
    }

    private function createOrder(array $payload, User $actor, Device $device): array
    {
        $uuid = $this->requireUuid($payload, 'order_uuid');
        $existing = Order::query()->where('uuid', $uuid)->first();
        if ($existing) {
            if ((int) $existing->business_id !== (int) $actor->business_id) {
                throw ApiException::conflict('ORDER_UUID_COLLISION', 'Order UUID sudah digunakan pada bisnis lain.');
            }
            if ((int) $existing->version === (int) ($payload['version'] ?? 1)) {
                return $this->result('duplicate', $existing->uuid);
            }

            throw ApiException::conflict('ORDER_ALREADY_EXISTS', 'Order sudah ada dengan versi berbeda.', [
                'current_version' => (int) $existing->version,
            ]);
        }

        $this->assertTotals($payload);

        $shift = $this->resolveTransactionShift($payload['shift_uuid'] ?? null, $device);

        $order = Order::create([
            'uuid' => $uuid,
            'business_id' => $actor->business_id,
            'outlet_id' => $device->outlet_id,
            'device_id' => $device->id,
            'shift_id' => $shift?->id,
            'user_id' => $actor->id,
            'order_number' => $this->orderNumber($payload, $actor->business_id, $device),
            'status' => $this->orderStatus($payload['status'] ?? Order::STATUS_DRAFT),
            'version' => max(1, (int) ($payload['version'] ?? 1)),
            'order_type' => $payload['order_type'] ?? Order::TYPE_DINE_IN,
            'table_number' => $payload['table_number'] ?? null,
            'table_conflict' => (bool) ($payload['table_conflict'] ?? false),
            'notes' => $payload['notes'] ?? null,
            ...$this->orderTotals($payload),
            'pricing_snapshot' => $payload['pricing_snapshot'] ?? null,
            'held_at' => $this->date($payload['held_at'] ?? null),
            'resumed_at' => $this->date($payload['resumed_at'] ?? null),
            'cancelled_at' => $this->date($payload['cancelled_at'] ?? null),
            'cancel_reason' => $payload['cancel_reason'] ?? null,
            'converted_at' => $this->date($payload['converted_at'] ?? null),
        ]);

        $occurredAt = $this->date($payload['created_at'] ?? null) ?? now();
        $order->timestamps = false;
        $order->forceFill([
            'created_at' => $occurredAt,
            'updated_at' => $this->date($payload['updated_at'] ?? null) ?? $occurredAt,
        ])->saveQuietly();
        $order->timestamps = true;

        $this->replaceOrderItems($order, $payload['items'] ?? [], $actor->business_id);
        $order->statusHistories()->create([
            'from_status' => null,
            'to_status' => $order->status,
            'actor_user_id' => $actor->id,
            'version' => (int) $order->version,
            'created_at' => $order->created_at ?? now(),
        ]);

        if ($shift) {
            $this->shifts->markTransactionParticipant($shift, $device, $actor);
        }

        return $this->result('accepted', $order->uuid);
    }

    private function updateOrder(array $payload, User $actor, Device $device, string $eventType): array
    {
        $order = $this->findOrder($payload, $actor);
        $base = (int) ($payload['base_version'] ?? $payload['version'] ?? 0);
        $targetVersion = (int) ($payload['version'] ?? $base + 1);

        if ($base !== (int) $order->version) {
            if ($targetVersion === (int) $order->version) {
                return $this->result('duplicate', $order->uuid);
            }

            throw ApiException::conflict('ORDER_VERSION_MISMATCH', 'Versi order tidak sesuai dengan data server.', [
                'current_version' => (int) $order->version,
                'base_version' => $base,
            ]);
        }

        if (! $order->isEditable()) {
            throw ApiException::conflict('ORDER_NOT_EDITABLE', 'Order yang sudah converted/cancelled tidak dapat diubah.');
        }

        $this->assertTotals($payload);
        $order->update([
            ...$this->orderTotals($payload),
            'version' => $base + 1,
            'order_type' => $payload['order_type'] ?? $order->order_type,
            'table_number' => $payload['table_number'] ?? $order->table_number,
            'table_conflict' => (bool) ($payload['table_conflict'] ?? $order->table_conflict),
            'notes' => $payload['notes'] ?? $order->notes,
            'pricing_snapshot' => $payload['pricing_snapshot'] ?? $order->pricing_snapshot,
        ]);
        $this->replaceOrderItems($order, $payload['items'] ?? [], $actor->business_id);
        $this->recordHistory($order, $order->status, $order->status, $actor, $base + 1);

        return $this->result('accepted', $order->uuid);
    }

    private function transitionOrder(array $payload, User $actor, Device $device, string $type): array
    {
        $order = $this->findOrder($payload, $actor);
        $base = (int) ($payload['base_version'] ?? 0);
        $target = match ($type) {
            'order.held' => Order::STATUS_HELD,
            'order.resumed' => Order::STATUS_RESUMED,
            'order.cancelled' => Order::STATUS_CANCELLED,
        };

        if ($order->status === $target) {
            return $this->result('duplicate', $order->uuid);
        }

        if ($base !== (int) $order->version) {
            throw ApiException::conflict('ORDER_VERSION_MISMATCH', 'Versi order tidak sesuai dengan data server.', [
                'current_version' => (int) $order->version,
                'base_version' => $base,
            ]);
        }

        $allowed = match ($target) {
            Order::STATUS_HELD => in_array($order->status, [Order::STATUS_DRAFT, Order::STATUS_RESUMED], true),
            Order::STATUS_RESUMED => $order->status === Order::STATUS_HELD,
            Order::STATUS_CANCELLED => $order->isEditable(),
        };

        if (! $allowed) {
            throw ApiException::conflict('ORDER_STATUS_INVALID', "Order berstatus {$order->status} tidak dapat dipindahkan ke {$target}.");
        }

        $from = $order->status;
        $updates = ['status' => $target, 'version' => $base + 1];
        if ($target === Order::STATUS_HELD) {
            $updates['held_at'] = $this->date($payload['held_at'] ?? null) ?? now();
        } elseif ($target === Order::STATUS_RESUMED) {
            $updates['resumed_at'] = $this->date($payload['resumed_at'] ?? null) ?? now();
        } else {
            $reason = trim((string) ($payload['cancel_reason'] ?? $payload['reason'] ?? ''));
            if ($reason === '') {
                throw new ApiException('CANCEL_REASON_REQUIRED', 'Alasan pembatalan order wajib diisi.', 422);
            }
            $updates['cancelled_at'] = $this->date($payload['cancelled_at'] ?? null) ?? now();
            $updates['cancel_reason'] = $reason;
        }

        $order->update($updates);
        $this->recordHistory($order, $from, $target, $actor, $base + 1, $payload['reason'] ?? $payload['cancel_reason'] ?? null);

        return $this->result('accepted', $order->uuid);
    }

    private function convertOrder(array $payload, User $actor, Device $device): array
    {
        $order = $this->findOrder($payload, $actor);
        $base = (int) ($payload['base_version'] ?? 0);

        if ($order->status === Order::STATUS_CONVERTED) {
            return $this->result('duplicate', $order->uuid);
        }

        if ($base !== (int) $order->version) {
            throw ApiException::conflict('ORDER_VERSION_MISMATCH', 'Versi order tidak sesuai saat konversi.', [
                'current_version' => (int) $order->version,
                'base_version' => $base,
            ]);
        }

        $from = $order->status;
        $order->update([
            'status' => Order::STATUS_CONVERTED,
            'version' => $base + 1,
            'converted_at' => $this->date($payload['converted_at'] ?? null) ?? now(),
        ]);
        $this->recordHistory($order, $from, Order::STATUS_CONVERTED, $actor, $base + 1);

        return $this->result('accepted', $order->uuid);
    }

    private function finalizeSale(array $payload, User $actor, Device $device): array
    {
        $saleUuid = $this->requireUuid($payload, 'sale_uuid');
        $existing = Sale::query()->where('uuid', $saleUuid)->first();
        if ($existing) {
            if ((int) $existing->business_id !== (int) $actor->business_id) {
                throw ApiException::conflict('SALE_UUID_COLLISION', 'Sale UUID sudah digunakan pada bisnis lain.');
            }

            return $this->result('duplicate', $existing->uuid);
        }

        $this->assertTotals($payload);
        $order = $this->findOrder($payload, $actor);

        if ($order->sale()->exists()) {
            throw ApiException::conflict('ORDER_ALREADY_CONVERTED', 'Order sudah menghasilkan sale lain.', [
                'sale_uuid' => $order->sale()->value('uuid'),
            ]);
        }

        if ($order->status !== Order::STATUS_CONVERTED) {
            $base = (int) ($payload['source_order_version'] ?? $order->version);
            if ($base !== (int) $order->version) {
                throw ApiException::conflict('ORDER_VERSION_MISMATCH', 'Versi order tidak sesuai saat checkout.', [
                    'current_version' => (int) $order->version,
                    'base_version' => $base,
                ]);
            }
            $from = $order->status;
            $order->update([
                'status' => Order::STATUS_CONVERTED,
                'version' => $base + 1,
                'converted_at' => now(),
            ]);
            $this->recordHistory($order, $from, Order::STATUS_CONVERTED, $actor, $base + 1);
            $order->refresh();
        }

        $receiptNumber = trim((string) ($payload['receipt_number'] ?? ''));
        if ($receiptNumber === '') {
            throw new ApiException('RECEIPT_NUMBER_REQUIRED', 'Nomor struk offline wajib dikirim.', 422);
        }
        if (Sale::query()->where('receipt_number', $receiptNumber)->exists()) {
            throw ApiException::conflict('RECEIPT_NUMBER_ALREADY_USED', 'Nomor struk sudah digunakan.', [
                'receipt_number' => $receiptNumber,
            ]);
        }
        $order->loadMissing(['outlet', 'shift']);
        $this->receipts->registerExisting($receiptNumber, $order->outlet, (string) $device->terminal_code);

        $shiftId = $this->resolveTransactionShift(
            $payload['shift_uuid'] ?? $order->shift?->uuid,
            $device,
        )?->id ?? $order->shift_id;

        if ($shiftId) {
            $shift = Shift::query()->find($shiftId);
            if ($shift) {
                $this->shifts->markTransactionParticipant($shift, $device, $actor);
            }
        }

        $sale = Sale::create([
            'uuid' => $saleUuid,
            'business_id' => $order->business_id,
            'outlet_id' => $order->outlet_id,
            'shift_id' => $shiftId,
            'user_id' => $actor->id,
            'device_id' => $device->id,
            'source_order_id' => $order->id,
            'source_order_version' => (int) $order->version,
            'origin' => 'offline',
            'receipt_number' => $receiptNumber,
            'order_type' => $payload['order_type'] ?? $order->order_type,
            'table_number' => $payload['table_number'] ?? $order->table_number,
            'lifecycle_status' => Sale::LIFECYCLE_FINALIZED,
            'payment_status' => Sale::PAYMENT_UNPAID,
            'subtotal' => (int) $payload['subtotal'],
            'item_discount_total' => (int) ($payload['item_discount_total'] ?? 0),
            'transaction_discount_total' => (int) ($payload['transaction_discount_total'] ?? 0),
            'discount_total' => (int) ($payload['discount_total'] ?? 0),
            'service_charge' => (int) ($payload['service_charge'] ?? 0),
            'tax_total' => (int) ($payload['tax_total'] ?? 0),
            'total' => (int) $payload['total'],
            'confirmed_amount' => 0,
            'awaiting_verification_amount' => 0,
            'outstanding_amount' => (int) $payload['total'],
            'refunded_amount' => 0,
            'notes' => $payload['notes'] ?? $order->notes,
            'source_order_uuid' => $order->uuid,
            'pricing_snapshot' => $payload['pricing_snapshot'] ?? $order->pricing_snapshot,
            'transacted_at' => $this->date($payload['transacted_at'] ?? null) ?? now(),
            'client_created_at' => $this->date($payload['client_created_at'] ?? $payload['transacted_at'] ?? null),
        ]);

        $this->persistSaleItems($sale, $payload['items'] ?? null, $order, $actor->business_id);

        foreach ($payload['payments'] ?? [] as $payment) {
            $this->createOfflinePayment($sale, $payment, $actor, requireUuid: false, forceAwaiting: false);
            $sale = $this->aggregator->recalculate($sale);
        }

        $sale = $this->aggregator->recalculate($sale);

        return $this->result('accepted', $sale->uuid);
    }

    private function voidSale(array $payload, User $actor, Device $device): array
    {
        $sale = $this->findSale($payload, $actor, $device);
        $reason = trim((string) ($payload['reason'] ?? $payload['void_reason'] ?? ''));

        if ($sale->lifecycle_status === Sale::LIFECYCLE_VOIDED) {
            return $this->result('duplicate', $sale->uuid);
        }

        if ($sale->lifecycle_status !== Sale::LIFECYCLE_FINALIZED) {
            throw ApiException::conflict('SALE_NOT_FINAL', 'Sale tidak dalam status final.');
        }

        $sale = $this->aggregator->recalculate($sale);
        if ((int) $sale->confirmed_amount > 0) {
            throw ApiException::conflict('SALE_HAS_CONFIRMED_PAYMENT', 'Sale dengan pembayaran terkonfirmasi harus direfund, bukan di-void.');
        }
        if ((int) $sale->awaiting_verification_amount > 0) {
            throw ApiException::conflict('SALE_HAS_AWAITING_PAYMENT', 'Tolak pembayaran yang menunggu verifikasi terlebih dahulu.');
        }
        if ($reason === '') {
            throw new ApiException('VOID_REASON_REQUIRED', 'Alasan void wajib diisi.', 422);
        }

        $sale->forceFill([
            'lifecycle_status' => Sale::LIFECYCLE_VOIDED,
            'payment_status' => Sale::PAYMENT_CANCELLED,
            'voided_at' => $this->date($payload['voided_at'] ?? null) ?? now(),
            'voided_by' => $actor->id,
            'void_reason' => $reason,
        ])->save();

        return $this->result('accepted', $sale->uuid);
    }

    private function recordPayment(array $payload, User $actor, Device $device, bool $verificationRequested): array
    {
        $sale = $this->findSale($payload, $actor, $device);

        if ($sale->lifecycle_status !== Sale::LIFECYCLE_FINALIZED) {
            throw ApiException::conflict('SALE_VOIDED', 'Pembayaran tidak dapat dicatat pada sale yang di-void.');
        }

        if ($verificationRequested && ($payload['method'] ?? null) === SalePayment::METHOD_CASH) {
            throw new ApiException('VERIFICATION_NOT_APPLICABLE', 'Pembayaran tunai tidak memerlukan verifikasi.', 422);
        }

        $sale = $this->aggregator->recalculate($sale);
        $payment = $this->createOfflinePayment(
            $sale,
            $payload,
            $actor,
            requireUuid: true,
            forceAwaiting: $verificationRequested,
        );
        $sale = $this->aggregator->recalculate($sale);

        return $this->result('accepted', $payment->uuid ?? $sale->uuid);
    }

    private function openShift(array $payload, User $actor, Device $device): array
    {
        $uuid = $this->requireUuid($payload, 'shift_uuid');
        $existing = Shift::query()->where('uuid', $uuid)->first();
        if ($existing) {
            if ((int) $existing->business_id !== (int) $actor->business_id) {
                throw ApiException::conflict('SHIFT_UUID_COLLISION', 'Shift UUID sudah digunakan pada bisnis lain.');
            }

            return $this->result('duplicate', $existing->uuid);
        }

        Outlet::query()->whereKey($device->outlet_id)->lockForUpdate()->first();

        $active = Shift::query()
            ->where('business_id', $actor->business_id)
            ->where('outlet_id', $device->outlet_id)
            ->whereIn('status', [Shift::STATUS_OPEN, Shift::STATUS_CLOSING])
            ->lockForUpdate()
            ->first();

        if ($active) {
            throw ApiException::conflict(
                'SHIFT_ALREADY_OPEN',
                'Outlet ini masih memiliki shift aktif. Event shift.opened dari perangkat lain tidak dapat membuat shift kedua.',
                ['shift_uuid' => $active->uuid, 'status' => $active->status],
            );
        }

        $shift = Shift::create([
            'uuid' => $uuid,
            'business_id' => $actor->business_id,
            'outlet_id' => $device->outlet_id,
            'user_id' => $actor->id,
            'device_id' => $device->id,
            'status' => Shift::STATUS_OPEN,
            'open_slot' => 1,
            'close_epoch' => 0,
            'opening_cash' => (int) ($payload['opening_cash'] ?? 0),
            'expected_cash' => (int) ($payload['opening_cash'] ?? 0),
            'opening_notes' => $payload['opening_notes'] ?? null,
            'opened_at' => $this->date($payload['opened_at'] ?? null) ?? now(),
        ]);

        $this->shifts->registerParticipant($shift, $device, $actor, true);

        return $this->result('accepted', $shift->uuid);
    }

    private function recordCashMovement(array $payload, User $actor, Device $device): array
    {
        $shift = $this->findShift($payload, $actor, $device);
        $uuid = $this->requireUuid($payload, 'movement_uuid');

        if ($shift->cashMovements()->where('uuid', $uuid)->exists()) {
            return $this->result('duplicate', $uuid);
        }

        if (! in_array($shift->status, [Shift::STATUS_OPEN, Shift::STATUS_CLOSING], true)) {
            throw ApiException::conflict(
                'SHIFT_CLOSED_LATE_EVENT',
                'Kas masuk/keluar datang setelah shift ditutup. Event disimpan sebagai konflik untuk direkonsiliasi.',
                ['shift_uuid' => $shift->uuid, 'status' => $shift->status],
            );
        }

        $type = (string) ($payload['type'] ?? '');
        if (! in_array($type, ['in', 'out'], true)) {
            throw new ApiException('CASH_MOVEMENT_TYPE_INVALID', 'Tipe kas tidak valid.', 422);
        }

        $movement = $shift->cashMovements()->create([
            'uuid' => $uuid,
            'type' => $type,
            'amount' => (int) ($payload['amount'] ?? 0),
            'reason' => $payload['reason'] ?? null,
            'created_by' => $actor->id,
            'device_id' => $device->id,
            'occurred_at' => $this->date($payload['occurred_at'] ?? null) ?? now(),
        ]);

        $this->shifts->markTransactionParticipant($shift, $device, $actor);

        $totals = $this->shiftSummary->calculate($shift);
        $shift->forceFill([
            'cash_in' => $totals['cash_in'],
            'cash_out' => $totals['cash_out'],
            'expected_cash' => $totals['expected_cash'],
        ])->save();

        return $this->result('accepted', $movement->uuid);
    }

    private function closeShift(array $payload, User $actor, Device $device): array
    {
        $shift = $this->findShift($payload, $actor, $device);
        $actualCash = (int) ($payload['actual_cash'] ?? 0);

        if ($shift->status === Shift::STATUS_CLOSED_CONFIRMED || $shift->status === Shift::STATUS_CLOSED_SYNC_EXCEPTION) {
            $snapshot = $shift->closingSnapshot;
            if ($snapshot && (int) $snapshot->actual_cash === $actualCash) {
                return $this->result('duplicate', $shift->uuid);
            }

            throw ApiException::conflict(
                'SHIFT_ALREADY_CLOSED',
                'Closing snapshot shift sudah immutable dan tidak dapat diubah oleh event shift.closed yang terlambat.',
                ['shift_uuid' => $shift->uuid, 'status' => $shift->status],
            );
        }

        if ($shift->status === Shift::STATUS_CLOSING) {
            return $this->result('duplicate', $shift->uuid);
        }

        if ($shift->status !== Shift::STATUS_OPEN) {
            throw ApiException::conflict('SHIFT_NOT_OPEN', 'Shift tidak dalam status terbuka.', [
                'shift_uuid' => $shift->uuid,
                'status' => $shift->status,
            ]);
        }

        if (! isset($payload['actual_cash'])) {
            throw new ApiException('SHIFT_ACTUAL_CASH_REQUIRED', 'Nominal kas aktual wajib dikirim untuk menutup shift.', 422);
        }

        app(CloseShift::class)->handle($shift, [
            'actual_cash' => $actualCash,
            'closing_notes' => $payload['closing_notes'] ?? null,
            'pending_sync_count' => (int) ($payload['pending_sync_count'] ?? 0),
            'local_event_sequence' => isset($payload['local_event_sequence']) ? (int) $payload['local_event_sequence'] : null,
            'closed_at' => $payload['closed_at'] ?? null,
        ], $actor, $device);

        return $this->result('accepted', $shift->uuid);
    }

    private function createOfflinePayment(
        Sale $sale,
        array $payload,
        User $actor,
        bool $requireUuid,
        bool $forceAwaiting,
    ): SalePayment {
        $uuid = trim((string) ($payload['payment_uuid'] ?? ''));
        if ($uuid === '' && $requireUuid) {
            throw new ApiException('PAYMENT_UUID_REQUIRED', 'UUID pembayaran wajib dikirim.', 422);
        }
        $uuid = $uuid === '' ? (string) Str::uuid() : $uuid;

        $existing = SalePayment::query()->where('uuid', $uuid)->first();
        if ($existing) {
            if ((int) $existing->sale_id !== (int) $sale->id) {
                throw ApiException::conflict('PAYMENT_UUID_COLLISION', 'UUID pembayaran sudah digunakan pada sale lain.');
            }

            return $existing;
        }

        $method = (string) ($payload['method'] ?? '');
        if (! in_array($method, [
            SalePayment::METHOD_CASH,
            SalePayment::METHOD_QRIS,
            SalePayment::METHOD_TRANSFER,
            SalePayment::METHOD_EWALLET,
        ], true)) {
            throw new ApiException('PAYMENT_METHOD_INVALID', 'Metode pembayaran tidak valid.', 422);
        }

        $amount = (int) ($payload['amount'] ?? 0);
        $outstanding = (int) $sale->outstanding_amount;
        if ($amount <= 0 || $amount > $outstanding) {
            throw new ApiException('PAYMENT_EXCEEDS_OUTSTANDING', 'Nominal pembayaran tidak valid terhadap outstanding.', 422, [
                'outstanding_amount' => $outstanding,
            ]);
        }

        $isCash = $method === SalePayment::METHOD_CASH;
        $tendered = $isCash ? (int) ($payload['tendered_amount'] ?? $amount) : null;
        if ($isCash && $tendered < $amount) {
            throw new ApiException('CASH_TENDERED_INSUFFICIENT', 'Uang tunai diterima kurang dari nominal pembayaran.', 422);
        }

        $confirmed = ($isCash && ! $forceAwaiting) || (! $isCash && $actor->isOwner());
        $status = $confirmed
            ? SalePayment::STATUS_CONFIRMED
            : SalePayment::STATUS_AWAITING_VERIFICATION;
        $proofRequired = ! $isCash
            && ! $actor->isOwner()
            && (bool) $sale->business?->non_cash_proof_required;
        $occurredAt = $this->date($payload['recorded_at'] ?? null) ?? now();

        return $sale->payments()->create([
            'uuid' => $uuid,
            'idempotency_key' => $payload['idempotency_key'] ?? null,
            'method' => $method,
            'amount' => $amount,
            'tendered_amount' => $tendered,
            'change_amount' => $isCash ? $tendered - $amount : 0,
            'verified_amount' => $status === SalePayment::STATUS_CONFIRMED ? $amount : null,
            'status' => $status,
            'provider_reference' => $payload['provider_reference'] ?? null,
            'notes' => $payload['notes'] ?? null,
            'proof_required' => $proofRequired,
            'origin' => 'offline',
            'recorded_by' => $actor->id,
            'recorded_at' => $occurredAt,
            'verified_by' => $status === SalePayment::STATUS_CONFIRMED ? $actor->id : null,
            'verified_at' => $status === SalePayment::STATUS_CONFIRMED ? $occurredAt : null,
        ]);
    }

    private function persistSaleItems(Sale $sale, ?array $items, Order $order, int $businessId): void
    {
        $order->loadMissing('items.modifiers');

        if ($items === null) {
            $lines = $order->pricing_snapshot['lines'] ?? [];
            foreach ($order->items->values() as $index => $item) {
                $line = $lines[$index] ?? [];
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
                    'discount_amount' => (int) ($line['discount_amount'] ?? $item->item_discount),
                    'tax_rate_basis_points' => (int) $item->tax_rate_basis_points,
                    'tax_amount' => (int) ($line['tax_amount'] ?? 0),
                    'service_charge_amount' => (int) ($line['service_charge_amount'] ?? 0),
                    'subtotal' => (int) $item->line_subtotal,
                    'total' => (int) ($line['total'] ?? $item->line_total),
                    'snapshot' => $item->snapshot,
                ]);
            }

            return;
        }

        $productIds = Product::query()
            ->where('business_id', $businessId)
            ->whereIn('uuid', collect($items)->pluck('product_uuid')->filter()->unique()->values()->all())
            ->pluck('id', 'uuid');

        foreach ($items as $item) {
            $quantity = (int) ($item['quantity'] ?? 0);
            $unitPrice = (int) ($item['unit_price'] ?? 0);
            $subtotal = (int) ($item['subtotal'] ?? $item['line_subtotal'] ?? $unitPrice * $quantity);

            $sale->items()->create([
                'product_id' => $productIds[$item['product_uuid'] ?? ''] ?? null,
                'product_uuid' => $item['product_uuid'] ?? null,
                'sku' => $item['sku'] ?? null,
                'product_name' => (string) ($item['product_name'] ?? 'Produk'),
                'variant_uuid' => $item['variant_uuid'] ?? null,
                'variant_name' => $item['variant_name'] ?? null,
                'addon_summary' => $item['addon_summary'] ?? null,
                'unit_price' => $unitPrice,
                'quantity' => $quantity,
                'discount_amount' => (int) ($item['discount_amount'] ?? 0),
                'tax_rate_basis_points' => (int) ($item['tax_rate_basis_points'] ?? 0),
                'tax_amount' => (int) ($item['tax_amount'] ?? 0),
                'service_charge_amount' => (int) ($item['service_charge_amount'] ?? 0),
                'subtotal' => $subtotal,
                'total' => (int) ($item['total'] ?? $item['line_total'] ?? $subtotal),
                'snapshot' => $item['snapshot'] ?? null,
            ]);
        }
    }

    private function replaceOrderItems(Order $order, array $items, int $businessId): void
    {
        $order->items()->delete();
        $productIds = Product::query()
            ->where('business_id', $businessId)
            ->whereIn('uuid', collect($items)->pluck('product_uuid')->filter()->unique()->values()->all())
            ->pluck('id', 'uuid');

        foreach ($items as $item) {
            $quantity = (int) ($item['quantity'] ?? 0);
            $unitPrice = (int) ($item['unit_price'] ?? 0);
            $lineSubtotal = (int) ($item['line_subtotal'] ?? ($unitPrice * $quantity));

            $created = $order->items()->create([
                'uuid' => $item['item_uuid'] ?? $item['uuid'] ?? (string) Str::uuid(),
                'product_id' => $productIds[$item['product_uuid'] ?? ''] ?? null,
                'product_uuid' => $item['product_uuid'] ?? null,
                'sku' => $item['sku'] ?? null,
                'product_name' => (string) ($item['product_name'] ?? 'Produk'),
                'variant_uuid' => $item['variant_uuid'] ?? null,
                'variant_name' => $item['variant_name'] ?? null,
                'addons' => $item['addons'] ?? null,
                'unit_price' => $unitPrice,
                'quantity' => $quantity,
                'item_discount' => (int) ($item['item_discount'] ?? 0),
                'tax_rate_basis_points' => (int) ($item['tax_rate_basis_points'] ?? 0),
                'notes' => $item['notes'] ?? null,
                'line_subtotal' => $lineSubtotal,
                'line_total' => (int) ($item['line_total'] ?? $lineSubtotal),
                'snapshot' => $item['snapshot'] ?? null,
            ]);

            foreach ($item['modifiers'] ?? [] as $modifier) {
                $created->modifiers()->create([
                    'uuid' => $modifier['uuid'] ?? (string) Str::uuid(),
                    'type' => $modifier['type'] ?? 'addon',
                    'modifier_uuid' => $modifier['modifier_uuid'] ?? null,
                    'name' => (string) ($modifier['name'] ?? 'Modifier'),
                    'price' => (int) ($modifier['price'] ?? 0),
                    'quantity' => (int) ($modifier['quantity'] ?? 1),
                    'snapshot' => $modifier['snapshot'] ?? null,
                ]);
            }
        }
    }

    private function findOrder(array $payload, User $actor): Order
    {
        if (empty($payload['order_uuid']) && ! empty($payload['source_order_uuid'])) {
            $payload['order_uuid'] = $payload['source_order_uuid'];
        }

        $uuid = $this->requireUuid($payload, 'order_uuid');
        $order = Order::query()->with('shift')->where('uuid', $uuid)->first();

        if (! $order || (int) $order->business_id !== (int) $actor->business_id) {
            throw ApiException::blocked(
                'SYNC_DEPENDENCY_ORDER_MISSING',
                'Order referensi belum tersedia. Kirim event order terlebih dahulu.',
                ['order_uuid' => $uuid],
            );
        }

        return $order;
    }

    private function findSale(array $payload, User $actor, Device $device): Sale
    {
        $uuid = $this->requireUuid($payload, 'sale_uuid');
        $sale = Sale::query()
            ->where('uuid', $uuid)
            ->where('business_id', $actor->business_id)
            ->where('outlet_id', $device->outlet_id)
            ->first();

        if (! $sale) {
            throw ApiException::blocked(
                'SYNC_DEPENDENCY_SALE_MISSING',
                'Sale referensi belum tersedia. Kirim event sale.finalized terlebih dahulu.',
                ['sale_uuid' => $uuid],
            );
        }

        return $sale;
    }

    private function findShift(array $payload, User $actor, Device $device): Shift
    {
        $uuid = $this->requireUuid($payload, 'shift_uuid');
        $shift = Shift::query()
            ->where('uuid', $uuid)
            ->where('business_id', $actor->business_id)
            ->where('outlet_id', $device->outlet_id)
            ->lockForUpdate()
            ->first();

        if (! $shift) {
            throw ApiException::blocked(
                'SYNC_DEPENDENCY_SHIFT_MISSING',
                'Shift outlet belum tersedia di server. Pastikan shift dibuka Owner dan sudah tersinkron; event shift.opened lokal dari perangkat kasir tidak diperlukan.',
                ['shift_uuid' => $uuid],
            );
        }

        return $shift;
    }

    /**
     * Resolves the shared outlet shift for a transaction event. When an older
     * client omits shift_uuid, the active outlet shift is used so historical
     * payloads keep working without creating per-device shifts.
     */
    private function resolveTransactionShift(?string $uuid, Device $device): ?Shift
    {
        if ($uuid !== null && trim($uuid) !== '') {
            $shift = Shift::query()
                ->where('uuid', strtolower(trim($uuid)))
                ->where('business_id', $device->business_id)
                ->where('outlet_id', $device->outlet_id)
                ->lockForUpdate()
                ->first();

            if (! $shift) {
                throw ApiException::blocked(
                    'SYNC_DEPENDENCY_SHIFT_MISSING',
                    'Shift referensi belum tersedia pada outlet perangkat ini.',
                    ['shift_uuid' => $uuid],
                );
            }

            if (! in_array($shift->status, [Shift::STATUS_OPEN, Shift::STATUS_CLOSING], true)) {
                throw ApiException::conflict(
                    'SHIFT_CLOSED_LATE_EVENT',
                    'Event transaksi datang setelah shift ditutup. Event disimpan sebagai konflik dan tidak mengubah snapshot penutupan.',
                    ['shift_uuid' => $shift->uuid, 'status' => $shift->status],
                );
            }

            return $shift;
        }

        $active = Shift::query()
            ->where('business_id', $device->business_id)
            ->where('outlet_id', $device->outlet_id)
            ->whereIn('status', [Shift::STATUS_OPEN, Shift::STATUS_CLOSING])
            ->lockForUpdate()
            ->latest('opened_at')
            ->first();

        if (! $active) {
            throw ApiException::blocked(
                'SHIFT_REQUIRED',
                'Shift outlet belum aktif. Minta Owner membuka shift sebelum transaksi disinkronkan.',
            );
        }

        return $active;
    }

    private function orderNumber(array $payload, int $businessId, Device $device): string
    {
        $number = trim((string) ($payload['order_number'] ?? ''));
        if ($number === '') {
            $device->loadMissing('outlet');

            return $this->orderNumbers->next($businessId, $device->outlet);
        }

        if (Order::query()->where('business_id', $businessId)->where('order_number', $number)->exists()) {
            throw ApiException::conflict('ORDER_NUMBER_ALREADY_USED', 'Nomor order sudah digunakan.', [
                'order_number' => $number,
            ]);
        }

        return $number;
    }

    private function orderStatus(string $status): string
    {
        if (! in_array($status, [
            Order::STATUS_DRAFT,
            Order::STATUS_HELD,
            Order::STATUS_RESUMED,
            Order::STATUS_CONVERTED,
            Order::STATUS_CANCELLED,
        ], true)) {
            throw new ApiException('ORDER_STATUS_INVALID', 'Status order tidak valid.', 422);
        }

        return $status;
    }

    private function orderTotals(array $payload): array
    {
        return [
            'subtotal' => (int) ($payload['subtotal'] ?? 0),
            'item_discount_total' => (int) ($payload['item_discount_total'] ?? 0),
            'transaction_discount_total' => (int) ($payload['transaction_discount_total'] ?? 0),
            'discount_total' => (int) ($payload['discount_total'] ?? 0),
            'service_charge' => (int) ($payload['service_charge'] ?? 0),
            'tax_total' => (int) ($payload['tax_total'] ?? 0),
            'total' => (int) ($payload['total'] ?? 0),
        ];
    }

    private function assertTotals(array $payload): void
    {
        foreach (['subtotal', 'item_discount_total', 'transaction_discount_total', 'discount_total', 'service_charge', 'tax_total', 'total'] as $field) {
            if (isset($payload[$field]) && (int) $payload[$field] < 0) {
                throw new ApiException('INVALID_AMOUNT', "Nilai {$field} tidak boleh negatif.", 422);
            }
        }

        $calculated = (int) ($payload['subtotal'] ?? 0)
            - (int) ($payload['item_discount_total'] ?? 0)
            - (int) ($payload['transaction_discount_total'] ?? 0)
            + (int) ($payload['service_charge'] ?? 0)
            + (int) ($payload['tax_total'] ?? 0);

        if ($calculated !== (int) ($payload['total'] ?? 0)) {
            throw ApiException::conflict('TOTALS_MISMATCH', 'Total transaksi tidak konsisten dengan komponennya.', [
                'calculated_total' => $calculated,
                'claimed_total' => (int) ($payload['total'] ?? 0),
            ]);
        }

        $discountTotal = (int) ($payload['item_discount_total'] ?? 0) + (int) ($payload['transaction_discount_total'] ?? 0);
        if (isset($payload['discount_total']) && (int) $payload['discount_total'] !== $discountTotal) {
            throw ApiException::conflict('DISCOUNT_TOTAL_MISMATCH', 'Total diskon tidak konsisten.');
        }
    }

    private function recordHistory(
        Order $order,
        ?string $from,
        string $to,
        User $actor,
        int $version,
        ?string $reason = null,
    ): void {
        $order->statusHistories()->create([
            'from_status' => $from,
            'to_status' => $to,
            'actor_user_id' => $actor->id,
            'reason' => $reason,
            'version' => $version,
            'created_at' => now(),
        ]);
    }

    private function requireUuid(array $payload, string $key): string
    {
        $value = strtolower(trim((string) ($payload[$key] ?? '')));

        if (! Str::isUuid($value)) {
            throw new ApiException('UUID_INVALID', "{$key} wajib berupa UUID yang valid.", 422);
        }

        return $value;
    }

    private function date(mixed $value): ?Carbon
    {
        if ($value === null || $value === '') {
            return null;
        }

        try {
            return Carbon::parse($value);
        } catch (\Throwable) {
            throw new ApiException('DATETIME_INVALID', 'Format waktu tidak valid.', 422);
        }
    }

    private function result(string $status, ?string $recordId): array
    {
        return ['status' => $status, 'server_record_id' => $recordId];
    }
}
