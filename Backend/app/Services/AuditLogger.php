<?php

namespace App\Services;

use App\Models\AuditLog;
use App\Models\User;
use Illuminate\Database\Eloquent\Model;

class AuditLogger
{
    public function record(
        string $action,
        string $module,
        string $description,
        ?Model $subject = null,
        array $oldValues = [],
        array $newValues = [],
        ?User $actor = null,
        ?int $businessId = null,
    ): AuditLog {
        $actor ??= auth()->user();
        $request = app()->runningInConsole() ? null : request();

        return AuditLog::create([
            'business_id' => $businessId ?? $actor?->business_id,
            'user_id' => $actor?->id,
            'action' => $action,
            'module' => $module,
            'auditable_type' => $subject ? $subject::class : null,
            'auditable_id' => $subject?->getKey(),
            'description' => $description,
            'old_values' => $oldValues ?: null,
            'new_values' => $newValues ?: null,
            'ip_address' => $request?->ip(),
            'user_agent' => $request?->userAgent(),
            'created_at' => now(),
        ]);
    }
}
