<?php

namespace App\Actions\Orders;

use App\Exceptions\ApiException;
use App\Models\Order;
use App\Models\User;
use App\Services\AuditLogger;
use App\Services\OrderItemBuilder;
use App\Services\OrderSnapshot;
use App\Services\PricingCalculator;
use App\Services\SyncRecorder;
use App\Services\TableConflictGuard;
use Illuminate\Support\Facades\DB;

class UpdateOrder
{
    public function __construct(
        private readonly OrderItemBuilder $items,
        private readonly PricingCalculator $pricing,
        private readonly TableConflictGuard $tables,
        private readonly OrderSnapshot $snapshots,
        private readonly AuditLogger $audit,
        private readonly SyncRecorder $sync,
    ) {}

    public function handle(Order $order, array $data, User $actor): Order
    {
        return DB::transaction(function () use ($order, $data, $actor) {
            $order = Order::query()->with(['business', 'outlet', 'device'])->lockForUpdate()->findOrFail($order->id);

            if ((int) $order->business_id !== (int) $actor->business_id) {
                throw ApiException::notFound();
            }

            if (! $order->isEditable()) {
                throw ApiException::conflict('ORDER_NOT_EDITABLE', 'Order yang sudah converted/cancelled tidak dapat diubah.');
            }

            $baseVersion = (int) $data['base_version'];
            if ($baseVersion !== (int) $order->version) {
                throw ApiException::conflict(
                    'ORDER_VERSION_MISMATCH',
                    'Order telah diubah pada perangkat lain. Muat ulang order sebelum mengubah.',
                    ['current_version' => (int) $order->version, 'base_version' => $baseVersion],
                );
            }

            $builtItems = $this->items->build($data['items'], $order->business);
            $transactionDiscount = (int) ($data['transaction_discount'] ?? 0);
            $calculated = $this->pricing->calculate(
                collect($builtItems)->pluck('item')->all(),
                $order->pricing_snapshot['config'] ?? [
                    'tax_enabled' => $order->business->tax_enabled,
                    'tax_rate_basis_points' => $order->business->tax_rate_basis_points,
                    'service_charge_enabled' => $order->business->service_charge_enabled,
                    'service_charge_rate_basis_points' => $order->business->service_charge_rate_basis_points,
                    'tax_includes_service_charge' => $order->business->tax_includes_service_charge,
                ],
                $transactionDiscount,
            );

            $conflicts = $this->tables->check(
                $order->outlet_id,
                $data['table_number'] ?? null,
                $order->id,
                (bool) ($data['table_override'] ?? false),
                $data['table_override_reason'] ?? null,
                $actor,
            );

            $old = $order->only(['version', 'status', 'table_number', 'subtotal', 'total', 'notes']);
            $version = ((int) $order->version) + 1;

            $order->update([
                'version' => $version,
                'order_type' => $data['order_type'] ?? $order->order_type,
                'table_number' => $data['table_number'] ?? $order->table_number,
                'table_conflict' => $conflicts !== [],
                'notes' => $data['notes'] ?? $order->notes,
                'subtotal' => $calculated['subtotal'],
                'item_discount_total' => $calculated['item_discount_total'],
                'transaction_discount_total' => $calculated['transaction_discount_total'],
                'discount_total' => $calculated['discount_total'],
                'service_charge' => $calculated['service_charge'],
                'tax_total' => $calculated['tax_total'],
                'total' => $calculated['total'],
                'pricing_snapshot' => [
                    ...($order->pricing_snapshot ?? []),
                    'config' => $calculated['config'],
                    'updated_at' => now()->toIso8601String(),
                ],
            ]);

            $order->items()->delete();
            foreach ($builtItems as $index => $entry) {
                $line = $calculated['lines'][$index];
                $item = $order->items()->create([
                    ...$entry['item'],
                    'line_total' => $line['total'],
                    'snapshot' => [
                        ...$entry['item']['snapshot'],
                        'transaction_discount_allocation' => $line['transaction_discount_allocation'],
                        'service_charge_amount' => $line['service_charge_amount'],
                        'tax_amount' => $line['tax_amount'],
                        'taxable_base' => $line['taxable_base'],
                    ],
                ]);

                foreach ($entry['modifiers'] as $modifier) {
                    $item->modifiers()->create($modifier);
                }
            }

            $this->audit->record(
                'order.updated',
                'orders',
                'Memperbarui order '.$order->order_number,
                $order,
                $old,
                $order->only(['version', 'status', 'table_number', 'subtotal', 'total', 'notes']) + ['conflicts' => $conflicts],
                $actor,
                $order->business_id,
            );

            $this->sync->record(
                'order.updated',
                'order',
                $order->uuid,
                $this->snapshots->payload($order->fresh(['items.modifiers', 'shift', 'device', 'cashier'])),
                $order->business_id,
                $order->outlet_id,
                $order->device_id,
                aggregateVersion: $version,
                baseVersion: $baseVersion,
            );

            return $order->refresh()->load(['items.modifiers', 'shift', 'device', 'cashier']);
        });
    }
}
