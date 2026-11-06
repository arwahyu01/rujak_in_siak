<?php

namespace App\Actions\Orders;

use App\Exceptions\ApiException;
use App\Models\Order;
use App\Models\User;
use App\Services\AuditLogger;
use App\Services\OrderSnapshot;
use App\Services\SyncRecorder;
use Illuminate\Support\Facades\DB;

class TransitionOrder
{
    public function __construct(
        private readonly OrderSnapshot $snapshots,
        private readonly AuditLogger $audit,
        private readonly SyncRecorder $sync,
    ) {}

    public function hold(Order $order, int $baseVersion, User $actor): Order
    {
        return $this->transition($order, $baseVersion, $actor, Order::STATUS_HELD);
    }

    public function resume(Order $order, int $baseVersion, User $actor): Order
    {
        return $this->transition($order, $baseVersion, $actor, Order::STATUS_RESUMED);
    }

    public function cancel(Order $order, int $baseVersion, User $actor, string $reason): Order
    {
        return $this->transition($order, $baseVersion, $actor, Order::STATUS_CANCELLED, $reason);
    }

    private function transition(Order $order, int $baseVersion, User $actor, string $target, ?string $reason = null): Order
    {
        return DB::transaction(function () use ($order, $baseVersion, $actor, $target, $reason) {
            $order = Order::query()->lockForUpdate()->findOrFail($order->id);

            if ((int) $order->business_id !== (int) $actor->business_id) {
                throw ApiException::notFound();
            }

            if ($baseVersion !== (int) $order->version) {
                throw ApiException::conflict(
                    'ORDER_VERSION_MISMATCH',
                    'Order telah diubah pada perangkat lain. Muat ulang order.',
                    ['current_version' => (int) $order->version, 'base_version' => $baseVersion],
                );
            }

            $allowed = match ($target) {
                Order::STATUS_HELD => in_array($order->status, [Order::STATUS_DRAFT, Order::STATUS_RESUMED], true),
                Order::STATUS_RESUMED => $order->status === Order::STATUS_HELD,
                Order::STATUS_CANCELLED => $order->isEditable(),
                default => false,
            };

            if (! $allowed) {
                throw ApiException::conflict(
                    'ORDER_STATUS_INVALID',
                    "Order berstatus {$order->status} tidak dapat dipindahkan ke {$target}.",
                );
            }

            if ($target === Order::STATUS_CANCELLED && trim((string) $reason) === '') {
                throw new ApiException('CANCEL_REASON_REQUIRED', 'Alasan pembatalan order wajib diisi.', 422);
            }

            $from = $order->status;
            $version = ((int) $order->version) + 1;
            $updates = ['status' => $target, 'version' => $version];

            if ($target === Order::STATUS_HELD) {
                $updates['held_at'] = now();
            } elseif ($target === Order::STATUS_RESUMED) {
                $updates['resumed_at'] = now();
            } elseif ($target === Order::STATUS_CANCELLED) {
                $updates['cancelled_at'] = now();
                $updates['cancel_reason'] = $reason;
            }

            $order->update($updates);
            $order->statusHistories()->create([
                'from_status' => $from,
                'to_status' => $target,
                'actor_user_id' => $actor->id,
                'reason' => $reason,
                'version' => $version,
                'created_at' => now(),
            ]);

            $eventType = match ($target) {
                Order::STATUS_HELD => 'order.held',
                Order::STATUS_RESUMED => 'order.resumed',
                Order::STATUS_CANCELLED => 'order.cancelled',
            };

            $this->audit->record(
                'order.'.$target,
                'orders',
                ucfirst($target).' order '.$order->order_number,
                $order,
                ['status' => $from, 'version' => $baseVersion],
                ['status' => $target, 'version' => $version, 'reason' => $reason],
                $actor,
                $order->business_id,
            );

            $this->sync->record(
                $eventType,
                'order',
                $order->uuid,
                $this->snapshots->payload($order->fresh(['items.modifiers', 'shift', 'device', 'cashier'])),
                $order->business_id,
                $order->outlet_id,
                $order->device_id,
                aggregateVersion: $version,
                baseVersion: $baseVersion,
            );

            return $order->refresh()->load(['items.modifiers', 'shift', 'device', 'cashier']);
        });
    }
}
