<?php

namespace App\Services;

use App\Models\Order;

class OrderSnapshot
{
    public function payload(Order $order): array
    {
        $order->loadMissing(['items.modifiers']);

        return [
            'order_uuid' => $order->uuid,
            'order_number' => $order->order_number,
            'status' => $order->status,
            'version' => (int) $order->version,
            'order_type' => $order->order_type,
            'table_number' => $order->table_number,
            'table_conflict' => (bool) $order->table_conflict,
            'notes' => $order->notes,
            'shift_uuid' => $order->shift?->uuid,
            'device_uuid' => $order->device?->uuid,
            'user_uuid' => $order->cashier?->uuid,
            'subtotal' => (int) $order->subtotal,
            'item_discount_total' => (int) $order->item_discount_total,
            'transaction_discount_total' => (int) $order->transaction_discount_total,
            'discount_total' => (int) $order->discount_total,
            'service_charge' => (int) $order->service_charge,
            'tax_total' => (int) $order->tax_total,
            'total' => (int) $order->total,
            'pricing_snapshot' => $order->pricing_snapshot,
            'items' => $order->items->map(fn ($item) => [
                'item_uuid' => $item->uuid,
                'product_uuid' => $item->product_uuid,
                'sku' => $item->sku,
                'product_name' => $item->product_name,
                'variant_uuid' => $item->variant_uuid,
                'variant_name' => $item->variant_name,
                'addons' => $item->addons,
                'unit_price' => (int) $item->unit_price,
                'quantity' => (int) $item->quantity,
                'item_discount' => (int) $item->item_discount,
                'tax_rate_basis_points' => (int) $item->tax_rate_basis_points,
                'notes' => $item->notes,
                'line_subtotal' => (int) $item->line_subtotal,
                'line_total' => (int) $item->line_total,
                'snapshot' => $item->snapshot,
                'modifiers' => $item->modifiers->map(fn ($modifier) => [
                    'type' => $modifier->type,
                    'modifier_uuid' => $modifier->modifier_uuid,
                    'name' => $modifier->name,
                    'price' => (int) $modifier->price,
                    'quantity' => (int) $modifier->quantity,
                ])->all(),
            ])->all(),
            'created_at' => $order->created_at?->toIso8601String(),
            'updated_at' => $order->updated_at?->toIso8601String(),
            'converted_at' => $order->converted_at?->toIso8601String(),
        ];
    }
}
