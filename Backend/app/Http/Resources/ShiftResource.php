<?php

namespace App\Http\Resources;

use App\Models\Shift;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ShiftResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $sync = $this->shift_sync ?? null;
        $summary = $this->server_summary ?? null;

        return [
            'uuid' => $this->uuid,
            'status' => $this->status,
            'is_active' => $this->isActive(),
            'is_closing' => $this->status === Shift::STATUS_CLOSING,
            'opening_cash' => (int) $this->opening_cash,
            'cash_tendered' => (int) $this->cash_tendered,
            'cash_change' => (int) $this->cash_change,
            'cash_in' => (int) $this->cash_in,
            'cash_out' => (int) $this->cash_out,
            'cash_refund' => (int) $this->cash_refund,
            'expected_cash' => (int) $this->expected_cash,
            'actual_cash' => $this->actual_cash !== null ? (int) $this->actual_cash : null,
            'variance' => $this->variance !== null ? (int) $this->variance : null,
            'close_actual_cash' => $this->close_actual_cash !== null ? (int) $this->close_actual_cash : null,
            'confirmed_noncash' => (int) $this->confirmed_noncash,
            'awaiting_verification_amount' => (int) $this->awaiting_verification_amount,
            'local_transaction_count' => (int) $this->local_transaction_count,
            'pending_sync_count' => (int) $this->pending_sync_count,
            'local_event_sequence' => $this->local_event_sequence !== null ? (int) $this->local_event_sequence : null,
            'close_epoch' => (int) $this->close_epoch,
            'opening_notes' => $this->opening_notes,
            'closing_notes' => $this->closing_notes,
            'opened_at' => $this->opened_at?->toIso8601String(),
            'closing_started_at' => $this->closing_started_at?->toIso8601String(),
            'closed_at' => $this->closed_at?->toIso8601String(),
            'approved_at' => $this->approved_at?->toIso8601String(),
            'cashier' => $this->whenLoaded('cashier', fn () => $this->cashier ? [
                'uuid' => $this->cashier->uuid,
                'name' => $this->cashier->name,
            ] : null),
            'opened_by' => $this->whenLoaded('cashier', fn () => $this->cashier ? [
                'uuid' => $this->cashier->uuid,
                'name' => $this->cashier->name,
            ] : null),
            'device' => $this->whenLoaded('device', fn () => $this->device ? [
                'uuid' => $this->device->uuid,
                'terminal_code' => $this->device->terminal_code,
                'name' => $this->device->name,
            ] : null),
            'opened_device' => $this->whenLoaded('device', fn () => $this->device ? [
                'uuid' => $this->device->uuid,
                'terminal_code' => $this->device->terminal_code,
                'name' => $this->device->name,
            ] : null),
            'outlet' => $this->whenLoaded('outlet', fn () => $this->outlet ? [
                'uuid' => $this->outlet->uuid,
                'name' => $this->outlet->name,
                'code' => $this->outlet->code,
            ] : null),
            'closing_requested_by' => $this->whenLoaded('closingRequestedBy', fn () => $this->closingRequestedBy ? [
                'uuid' => $this->closingRequestedBy->uuid,
                'name' => $this->closingRequestedBy->name,
            ] : null),
            'closing_requested_device' => $this->whenLoaded('closingRequestedDevice', fn () => $this->closingRequestedDevice ? [
                'uuid' => $this->closingRequestedDevice->uuid,
                'terminal_code' => $this->closingRequestedDevice->terminal_code,
                'name' => $this->closingRequestedDevice->name,
            ] : null),
            'closed_by' => $this->whenLoaded('closedBy', fn () => $this->closedBy ? [
                'uuid' => $this->closedBy->uuid,
                'name' => $this->closedBy->name,
            ] : null),
            'closed_device' => $this->whenLoaded('closedDevice', fn () => $this->closedDevice ? [
                'uuid' => $this->closedDevice->uuid,
                'terminal_code' => $this->closedDevice->terminal_code,
                'name' => $this->closedDevice->name,
            ] : null),
            'cash_movements' => $this->whenLoaded('cashMovements', fn () => $this->cashMovements->map(fn ($movement) => [
                'uuid' => $movement->uuid,
                'type' => $movement->type,
                'amount' => (int) $movement->amount,
                'reason' => $movement->reason,
                'created_by' => $movement->relationLoaded('createdBy') && $movement->createdBy
                    ? $movement->createdBy->name
                    : null,
                'device_uuid' => $movement->relationLoaded('device') ? $movement->device?->uuid : null,
                'occurred_at' => $movement->occurred_at?->toIso8601String(),
            ])->all()),
            'summary' => $summary,
            'sync' => $sync,
            'pending_devices' => $sync['pending_devices'] ?? [],
            'can_finalize' => (bool) ($sync['can_finalize'] ?? false),
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
                'device_count' => (int) $this->closingSnapshot->device_count,
                'synced_device_count' => (int) $this->closingSnapshot->synced_device_count,
                'checkpoint_epoch' => (int) $this->closingSnapshot->checkpoint_epoch,
                'local_event_sequence' => $this->closingSnapshot->local_event_sequence !== null
                    ? (int) $this->closingSnapshot->local_event_sequence
                    : null,
                'closing_notes' => $this->closingSnapshot->closing_notes,
                'closed_by' => $this->closingSnapshot->relationLoaded('closedBy') && $this->closingSnapshot->closedBy
                    ? ['uuid' => $this->closingSnapshot->closedBy->uuid, 'name' => $this->closingSnapshot->closedBy->name]
                    : null,
                'closed_device' => $this->closingSnapshot->relationLoaded('closedDevice') && $this->closingSnapshot->closedDevice
                    ? [
                        'uuid' => $this->closingSnapshot->closedDevice->uuid,
                        'terminal_code' => $this->closingSnapshot->closedDevice->terminal_code,
                        'name' => $this->closingSnapshot->closedDevice->name,
                    ]
                    : null,
                'snapshot' => $this->closingSnapshot->snapshot,
                'closed_at' => $this->closingSnapshot->closed_at?->toIso8601String(),
                'finalized_at' => $this->closingSnapshot->finalized_at?->toIso8601String(),
            ] : null),
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
