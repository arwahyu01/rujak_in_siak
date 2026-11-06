<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class OrderResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'uuid' => $this->uuid,
            'order_number' => $this->order_number,
            'status' => $this->status,
            'version' => (int) $this->version,
            'order_type' => $this->order_type,
            'table_number' => $this->table_number,
            'table_conflict' => (bool) $this->table_conflict,
            'notes' => $this->notes,
            'subtotal' => (int) $this->subtotal,
            'item_discount_total' => (int) $this->item_discount_total,
            'transaction_discount_total' => (int) $this->transaction_discount_total,
            'discount_total' => (int) $this->discount_total,
            'service_charge' => (int) $this->service_charge,
            'tax_total' => (int) $this->tax_total,
            'total' => (int) $this->total,
            'pricing_snapshot' => $this->pricing_snapshot,
            'shift' => $this->whenLoaded('shift', fn () => $this->shift ? [
                'uuid' => $this->shift->uuid,
                'status' => $this->shift->status,
                'opened_at' => $this->shift->opened_at?->toIso8601String(),
            ] : null),
            'device' => $this->whenLoaded('device', fn () => $this->device ? [
                'uuid' => $this->device->uuid,
                'terminal_code' => $this->device->terminal_code,
            ] : null),
            'cashier' => $this->whenLoaded('cashier', fn () => $this->cashier ? [
                'uuid' => $this->cashier->uuid,
                'name' => $this->cashier->name,
            ] : null),
            'items' => $this->whenLoaded('items', fn () => $this->items->map(fn ($item) => [
                'uuid' => $item->uuid,
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
                'modifiers' => $item->relationLoaded('modifiers')
                    ? $item->modifiers->map(fn ($modifier) => [
                        'type' => $modifier->type,
                        'modifier_uuid' => $modifier->modifier_uuid,
                        'name' => $modifier->name,
                        'price' => (int) $modifier->price,
                        'quantity' => (int) $modifier->quantity,
                    ])->all()
                    : [],
            ])->all()),
            'status_histories' => $this->whenLoaded('statusHistories', fn () => $this->statusHistories->map(fn ($history) => [
                'from_status' => $history->from_status,
                'to_status' => $history->to_status,
                'reason' => $history->reason,
                'version' => (int) $history->version,
                'actor_uuid' => $history->actor?->uuid,
                'created_at' => $history->created_at?->toIso8601String(),
            ])->all()),
            'sale_uuid' => $this->whenLoaded('sale', fn () => $this->sale?->uuid),
            'held_at' => $this->held_at?->toIso8601String(),
            'resumed_at' => $this->resumed_at?->toIso8601String(),
            'cancelled_at' => $this->cancelled_at?->toIso8601String(),
            'cancel_reason' => $this->cancel_reason,
            'converted_at' => $this->converted_at?->toIso8601String(),
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
