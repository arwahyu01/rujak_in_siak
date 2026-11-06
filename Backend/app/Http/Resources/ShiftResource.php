<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ShiftResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'uuid' => $this->uuid,
            'status' => $this->status,
            'opening_cash' => (int) $this->opening_cash,
            'cash_tendered' => (int) $this->cash_tendered,
            'cash_change' => (int) $this->cash_change,
            'cash_in' => (int) $this->cash_in,
            'cash_out' => (int) $this->cash_out,
            'cash_refund' => (int) $this->cash_refund,
            'expected_cash' => (int) $this->expected_cash,
            'actual_cash' => $this->actual_cash !== null ? (int) $this->actual_cash : null,
            'variance' => $this->variance !== null ? (int) $this->variance : null,
            'confirmed_noncash' => (int) $this->confirmed_noncash,
            'awaiting_verification_amount' => (int) $this->awaiting_verification_amount,
            'local_transaction_count' => (int) $this->local_transaction_count,
            'pending_sync_count' => (int) $this->pending_sync_count,
            'local_event_sequence' => $this->local_event_sequence !== null ? (int) $this->local_event_sequence : null,
            'opening_notes' => $this->opening_notes,
            'closing_notes' => $this->closing_notes,
            'opened_at' => $this->opened_at?->toIso8601String(),
            'closed_at' => $this->closed_at?->toIso8601String(),
            'approved_at' => $this->approved_at?->toIso8601String(),
            'cashier' => $this->whenLoaded('cashier', fn () => $this->cashier ? [
                'uuid' => $this->cashier->uuid,
                'name' => $this->cashier->name,
            ] : null),
            'device' => $this->whenLoaded('device', fn () => $this->device ? [
                'uuid' => $this->device->uuid,
                'terminal_code' => $this->device->terminal_code,
                'name' => $this->device->name,
            ] : null),
            'outlet' => $this->whenLoaded('outlet', fn () => $this->outlet ? [
                'uuid' => $this->outlet->uuid,
                'name' => $this->outlet->name,
                'code' => $this->outlet->code,
            ] : null),
            'cash_movements' => $this->whenLoaded('cashMovements', fn () => $this->cashMovements->map(fn ($movement) => [
                'uuid' => $movement->uuid,
                'type' => $movement->type,
                'amount' => (int) $movement->amount,
                'reason' => $movement->reason,
                'created_by' => $movement->relationLoaded('createdBy') && $movement->createdBy
                    ? $movement->createdBy->name
                    : null,
                'occurred_at' => $movement->occurred_at?->toIso8601String(),
            ])->all()),
            'closing_snapshot' => $this->whenLoaded('closingSnapshot', fn () => $this->closingSnapshot ? [
                'uuid' => $this->closingSnapshot->uuid,
                'opening_cash' => (int) $this->closingSnapshot->opening_cash,
                'cash_tendered' => (int) $this->closingSnapshot->cash_tendered,
                'cash_change' => (int) $this->closingSnapshot->cash_change,
                'cash_in' => (int) $this->closingSnapshot->cash_in,
                'cash_out' => (int) $this->closingSnapshot->cash_out,
                'cash_refund' => (int) $this->closingSnapshot->cash_refund,
                'expected_cash' => (int) $this->closingSnapshot->expected_cash,
                'actual_cash' => (int) $this->closingSnapshot->actual_cash,
                'variance' => (int) $this->closingSnapshot->variance,
                'confirmed_noncash' => (int) $this->closingSnapshot->confirmed_noncash,
                'awaiting_verification_amount' => (int) $this->closingSnapshot->awaiting_verification_amount,
                'local_transaction_count' => (int) $this->closingSnapshot->local_transaction_count,
                'pending_sync_count' => (int) $this->closingSnapshot->pending_sync_count,
                'local_event_sequence' => $this->closingSnapshot->local_event_sequence !== null
                    ? (int) $this->closingSnapshot->local_event_sequence
                    : null,
                'closing_notes' => $this->closingSnapshot->closing_notes,
                'snapshot' => $this->closingSnapshot->snapshot,
                'closed_at' => $this->closingSnapshot->closed_at?->toIso8601String(),
            ] : null),
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
