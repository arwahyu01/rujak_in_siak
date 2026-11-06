<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\Order;
use App\Models\User;

class TableConflictGuard
{
    /**
     * Returns IDs of conflicting active orders. Override requires a supervisor
     * permission and a recorded reason; neither transaction is ever deleted.
     */
    public function check(
        int $outletId,
        ?string $tableNumber,
        ?int $excludeOrderId,
        bool $override,
        ?string $reason,
        User $actor,
    ): array {
        if ($tableNumber === null || trim($tableNumber) === '') {
            return [];
        }

        $conflicts = Order::query()
            ->active()
            ->where('outlet_id', $outletId)
            ->where('table_number', $tableNumber)
            ->when($excludeOrderId, fn ($query) => $query->whereKeyNot($excludeOrderId))
            ->get(['id', 'uuid', 'order_number', 'status']);

        if ($conflicts->isEmpty()) {
            return [];
        }

        if (! $override) {
            throw ApiException::conflict(
                'TABLE_CONFLICT',
                'Meja sedang dipakai order aktif lain. Pilih meja lain atau minta override supervisor.',
                ['orders' => $conflicts->map->only(['uuid', 'order_number', 'status'])->all()],
            );
        }

        if (! $actor->hasPermission('orders.override_table_conflict')) {
            throw ApiException::forbidden('Override konflik meja memerlukan izin supervisor.');
        }

        if (! $reason || trim($reason) === '') {
            throw new ApiException('TABLE_OVERRIDE_REASON_REQUIRED', 'Alasan override konflik meja wajib diisi.', 422);
        }

        return $conflicts->pluck('id')->all();
    }
}
