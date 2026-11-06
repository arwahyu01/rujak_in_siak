<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class DeviceResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'uuid' => $this->uuid,
            'name' => $this->name,
            'terminal_code' => $this->terminal_code,
            'platform' => $this->platform,
            'app_version' => $this->app_version,
            'status' => $this->status,
            'last_sequence' => (int) $this->last_sequence,
            'last_seen_at' => $this->last_seen_at?->toIso8601String(),
            'activated_at' => $this->activated_at?->toIso8601String(),
            'revoked_at' => $this->revoked_at?->toIso8601String(),
            'outlet' => $this->whenLoaded('outlet', fn () => [
                'uuid' => $this->outlet->uuid,
                'name' => $this->outlet->name,
                'code' => $this->outlet->code,
            ]),
        ];
    }
}
