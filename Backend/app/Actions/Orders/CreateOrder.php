<?php

namespace App\Actions\Orders;

use App\Exceptions\ApiException;
use App\Models\Device;
use App\Models\Order;
use App\Models\Shift;
use App\Models\User;
use App\Services\AuditLogger;
use App\Services\OrderItemBuilder;
use App\Services\OrderNumberService;
use App\Services\OrderSnapshot;
use App\Services\PricingCalculator;
use App\Services\SyncRecorder;
use App\Services\TableConflictGuard;
use Illuminate\Support\Facades\DB;

class CreateOrder
{
    public function __construct(
        private readonly OrderItemBuilder $items,
        private readonly PricingCalculator $pricing,
        private readonly TableConflictGuard $tables,
        private readonly OrderNumberService $numbers,
        private readonly OrderSnapshot $snapshots,
        private readonly AuditLogger $audit,
        private readonly SyncRecorder $sync,
    ) {}

    public function handle(array $data, User $actor, Device $device): Order
    {
        return DB::transaction(function () use ($data, $actor, $device) {
            $outlet = $device->outlet;
            $business = $actor->business;

            $shift = Shift::query()
                ->where('business_id', $business->id)
                ->where('outlet_id', $outlet->id)
                ->where('device_id', $device->id)
                ->where('user_id', $actor->id)
                ->where('status', Shift::STATUS_OPEN)
                ->lockForUpdate()
                ->latest('opened_at')
                ->first();

            if (! $shift) {
                throw new ApiException('SHIFT_REQUIRED', 'Buka shift terlebih dahulu sebelum membuat order.', 422);
            }

            $builtItems = $this->items->build($data['items'], $business);
            $transactionDiscount = (int) ($data['transaction_discount'] ?? 0);
            $calculated = $this->pricing->calculate(
                collect($builtItems)->pluck('item')->all(),
                [
                    'tax_enabled' => $business->tax_enabled,
                    'tax_rate_basis_points' => $business->tax_rate_basis_points,
                    'service_charge_enabled' => $business->service_charge_enabled,
                    'service_charge_rate_basis_points' => $business->service_charge_rate_basis_points,
                    'tax_includes_service_charge' => $business->tax_includes_service_charge,
                ],
                $transactionDiscount,
            );

            $conflicts = $this->tables->check(
                $outlet->id,
                $data['table_number'] ?? null,
                null,
                (bool) ($data['table_override'] ?? false),
                $data['table_override_reason'] ?? null,
                $actor,
            );

            $order = Order::create([
                'business_id' => $business->id,
                'outlet_id' => $outlet->id,
                'device_id' => $device->id,
                'shift_id' => $shift->id,
                'user_id' => $actor->id,
                'order_number' => $this->numbers->next($business->id, $outlet),
                'status' => Order::STATUS_DRAFT,
                'version' => 1,
                'order_type' => $data['order_type'] ?? Order::TYPE_DINE_IN,
                'table_number' => $data['table_number'] ?? null,
                'table_conflict' => $conflicts !== [],
                'notes' => $data['notes'] ?? null,
                'subtotal' => $calculated['subtotal'],
                'item_discount_total' => $calculated['item_discount_total'],
                'transaction_discount_total' => $calculated['transaction_discount_total'],
                'discount_total' => $calculated['discount_total'],
                'service_charge' => $calculated['service_charge'],
                'tax_total' => $calculated['tax_total'],
                'total' => $calculated['total'],
                'pricing_snapshot' => [
                    'config' => $calculated['config'],
                    'calculated_at' => now()->toIso8601String(),
                ],
            ]);

            $this->persistItems($order, $builtItems, $calculated);

            $order->statusHistories()->create([
                'from_status' => null,
                'to_status' => Order::STATUS_DRAFT,
                'actor_user_id' => $actor->id,
                'version' => 1,
                'created_at' => now(),
            ]);

            $this->audit->record(
                'order.created',
                'orders',
                'Membuat order '.$order->order_number,
                $order,
                [],
                $order->only(['status', 'version', 'total', 'table_number']) + ['conflicts' => $conflicts],
                $actor,
                $business->id,
            );

            $this->sync->record(
                'order.created',
                'order',
                $order->uuid,
                $this->snapshots->payload($order->fresh(['items.modifiers', 'shift', 'device', 'cashier'])),
                $business->id,
                $outlet->id,
                $device->id,
                aggregateVersion: 1,
                baseVersion: null,
            );

            return $order->refresh()->load(['items.modifiers', 'shift', 'device', 'cashier']);
        });
    }

    private function persistItems(Order $order, array $builtItems, array $calculated): void
    {
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
    }
}
