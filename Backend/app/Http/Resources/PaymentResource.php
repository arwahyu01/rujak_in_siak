<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class PaymentResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'uuid' => $this->uuid,
            'sale_uuid' => $this->whenLoaded('sale', fn () => $this->sale?->uuid),
            'receipt_number' => $this->whenLoaded('sale', fn () => $this->sale?->receipt_number),
            'method' => $this->method,
            'amount' => (int) $this->amount,
            'tendered_amount' => $this->tendered_amount !== null ? (int) $this->tendered_amount : null,
            'change_amount' => (int) $this->change_amount,
            'verified_amount' => $this->verified_amount !== null ? (int) $this->verified_amount : null,
            'status' => $this->status,
            'origin' => $this->origin,
            'provider_reference' => $this->provider_reference,
            'notes' => $this->notes,
            'idempotency_key' => $this->idempotency_key,
            'has_proof' => $this->proof_path !== null,
            'proof_required' => (bool) $this->proof_required,
            'proof_uploaded_at' => $this->proof_uploaded_at?->toIso8601String(),
            'recorded_by' => $this->whenLoaded('recordedBy', fn () => $this->recordedBy ? [
                'uuid' => $this->recordedBy->uuid,
                'name' => $this->recordedBy->name,
            ] : null),
            'verified_by' => $this->whenLoaded('verifiedBy', fn () => $this->verifiedBy ? [
                'uuid' => $this->verifiedBy->uuid,
                'name' => $this->verifiedBy->name,
            ] : null),
            'rejected_by' => $this->whenLoaded('rejectedBy', fn () => $this->rejectedBy ? [
                'uuid' => $this->rejectedBy->uuid,
                'name' => $this->rejectedBy->name,
            ] : null),
            'rejection_reason' => $this->rejection_reason,
            'verification_logs' => $this->whenLoaded('verificationLogs', fn () => $this->verificationLogs->map(fn ($log) => [
                'action' => $log->action,
                'recorded_amount' => (int) $log->recorded_amount,
                'verified_amount' => $log->verified_amount !== null ? (int) $log->verified_amount : null,
                'reason' => $log->reason,
                'notes' => $log->notes,
                'actor' => $log->relationLoaded('actor') && $log->actor ? [
                    'uuid' => $log->actor->uuid,
                    'name' => $log->actor->name,
                ] : null,
                'created_at' => $log->created_at?->toIso8601String(),
            ])->all()),
            'recorded_at' => $this->recorded_at?->toIso8601String(),
            'verified_at' => $this->verified_at?->toIso8601String(),
            'rejected_at' => $this->rejected_at?->toIso8601String(),
        ];
    }
}
