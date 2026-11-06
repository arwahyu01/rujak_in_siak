<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'uuid' => $this->uuid,
            'name' => $this->name,
            'email' => $this->email,
            'username' => $this->username,
            'phone' => $this->phone,
            'is_active' => $this->is_active,
            'business_id' => $this->business?->uuid,
            'outlet_id' => $this->outlet?->uuid,
            'roles' => $this->roleSlugs(),
            'permissions' => $this->permissionSlugs(),
            'has_pin' => $this->pin_hash !== null,
            'authentication_version' => (int) $this->auth_version,
            'last_login_at' => $this->last_login_at?->toIso8601String(),
        ];
    }
}
