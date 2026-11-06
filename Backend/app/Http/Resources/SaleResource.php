<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class SaleResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'uuid' => $this->uuid,
            'receipt_number' => $this->receipt_number,
            'source_order_uuid' => $this->source_order_uuid,
            'source_order_version' => $this->source_order_version ? (int) $this->source_order_version : null,
            'origin' => $this->origin,
            'order_type' => $this->order_type,
            'table_number' => $this->table_number,
            'lifecycle_status' => $this->lifecycle_status,
            'payment_status' => $this->payment_status,
            'subtotal' => (int) $this->subtotal,
            'item_discount_total' => (int) $this->item_discount_total,
            'transaction_discount_total' => (int) $this->transaction_discount_total,
            'discount_total' => (int) $this->discount_total,
            'service_charge' => (int) $this->service_charge,
            'tax_total' => (int) $this->tax_total,
            'total' => (int) $this->total,
            'confirmed_amount' => (int) $this->confirmed_amount,
            'awaiting_verification_amount' => (int) $this->awaiting_verification_amount,
            'outstanding_amount' => (int) $this->outstanding_amount,
            'refunded_amount' => (int) $this->refunded_amount,
            'notes' => $this->notes,
            'pricing_snapshot' => $this->pricing_snapshot,
            'shift' => $this->whenLoaded('shift', fn () => $this->shift ? [
                'uuid' => $this->shift->uuid,
                'status' => $this->shift->status,
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
                'addon_summary' => $item->addon_summary,
                'unit_price' => (int) $item->unit_price,
                'quantity' => (int) $item->quantity,
                'discount_amount' => (int) $item->discount_amount,
                'tax_rate_basis_points' => (int) $item->tax_rate_basis_points,
                'tax_amount' => (int) $item->tax_amount,
                'service_charge_amount' => (int) $item->service_charge_amount,
                'subtotal' => (int) $item->subtotal,
                'total' => (int) $item->total,
                'snapshot' => $item->snapshot,
            ])->all()),
            'payments' => $this->whenLoaded('payments', fn () => $this->payments->map(
                fn ($payment) => (new PaymentResource($payment))->resolve($request),
            )->all()),
            'refunds' => $this->whenLoaded('refunds', fn () => $this->refunds->map(fn ($refund) => [
                'uuid' => $refund->uuid,
                'method' => $refund->method,
                'amount' => (int) $refund->amount,
                'reason' => $refund->reason,
                'refunded_at' => $refund->refunded_at?->toIso8601String(),
                'created_by' => $refund->relationLoaded('createdBy') && $refund->createdBy ? [
                    'uuid' => $refund->createdBy->uuid,
                    'name' => $refund->createdBy->name,
                ] : null,
            ])->all()),
            'voided_at' => $this->voided_at?->toIso8601String(),
            'void_reason' => $this->void_reason,
            'voided_by' => $this->whenLoaded('voidedBy', fn () => $this->voidedBy ? [
                'uuid' => $this->voidedBy->uuid,
                'name' => $this->voidedBy->name,
            ] : null),
            'transacted_at' => $this->transacted_at?->toIso8601String(),
            'client_created_at' => $this->client_created_at?->toIso8601String(),
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
