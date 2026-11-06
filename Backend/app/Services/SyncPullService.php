<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\Device;
use App\Models\SyncCursor;
use App\Models\SyncEvent;
use App\Models\User;
use Illuminate\Database\Eloquent\Builder;

class SyncPullService
{
    public const MAX_LIMIT = 500;

    /**
     * Event prefixes that may be delivered to a device, with the permission
     * required to observe them. Unknown types are never pulled.
     */
    private const VISIBILITY = [
        'order.' => 'orders.view',
        'sale.' => 'sales.view',
        'payment.' => 'sales.view',
        'shift.' => 'shifts.view',
        'product.' => 'products.view',
        'category.' => 'products.view',
        'user.' => 'users.view',
        'role.' => 'users.view',
        'permission.' => 'users.view',
    ];

    public function __construct(private readonly SyncCursorCodec $codec) {}

    public function pull(User $user, Device $device, ?string $cursor, ?int $limit): array
    {
        $businessId = (int) $device->business_id;
        $outletId = (int) $device->outlet_id;

        $storedCursor = SyncCursor::query()->where('device_id', $device->id)->value('last_event_id');
        $lastEventId = $cursor !== null && trim($cursor) !== ''
            ? $this->codec->decode($cursor, $businessId, $outletId)
            : (int) ($storedCursor ?? 0);

        $limit = max(1, min($limit ?? self::MAX_LIMIT, self::MAX_LIMIT));

        $rows = $this->visibleEvents($user, $businessId, $outletId)
            ->where('id', '>', $lastEventId)
            ->orderBy('id')
            ->limit($limit + 1)
            ->get();

        $hasMore = $rows->count() > $limit;
        $page = $rows->take($limit);
        $nextEventId = $page->isNotEmpty()
            ? (int) $page->last()->id
            : $lastEventId;

        SyncCursor::query()->updateOrCreate(
            ['device_id' => $device->id],
            [
                'user_id' => $user->id,
                'last_event_id' => $nextEventId,
                'last_pulled_at' => now(),
            ],
        );

        return [
            'changes' => $page->map(fn (SyncEvent $event) => [
                'event_id' => $event->event_id,
                'event_type' => $event->event_type,
                'aggregate_type' => $event->aggregate_type,
                'aggregate_id' => $event->aggregate_id,
                'aggregate_version' => $event->aggregate_version,
                'base_version' => $event->base_version,
                'schema_version' => (int) $event->schema_version,
                'source' => $event->source,
                'occurred_at' => $event->occurred_at?->toIso8601String(),
                'payload' => $event->payload ?? [],
            ])->values()->all(),
            'next_cursor' => $this->codec->encode($businessId, $outletId, $nextEventId),
            'has_more' => $hasMore,
            'limit' => $limit,
            'server_time' => now()->toIso8601String(),
        ];
    }

    public function currentCursor(Device $device): string
    {
        $lastEventId = (int) (SyncCursor::query()->where('device_id', $device->id)->value('last_event_id') ?? 0);

        return $this->codec->encode((int) $device->business_id, (int) $device->outlet_id, $lastEventId);
    }

    public function markCursor(User $user, Device $device, int $eventId): string
    {
        SyncCursor::query()->updateOrCreate(
            ['device_id' => $device->id],
            [
                'user_id' => $user->id,
                'last_event_id' => max(0, $eventId),
                'last_pulled_at' => now(),
            ],
        );

        return $this->codec->encode((int) $device->business_id, (int) $device->outlet_id, max(0, $eventId));
    }

    private function visibleEvents(User $user, int $businessId, int $outletId): Builder
    {
        $allowed = array_filter(
            self::VISIBILITY,
            fn (string $permission) => $user->hasPermission($permission),
        );

        if ($allowed === []) {
            throw new ApiException('SYNC_NOT_PERMITTED', 'Pengguna tidak memiliki izin sinkronisasi data.', 403);
        }

        return SyncEvent::query()
            ->where('business_id', $businessId)
            ->where('outlet_id', $outletId)
            ->where('status', 'accepted')
            ->whereNotNull('processed_at')
            ->where(function (Builder $query) use ($allowed) {
                foreach (array_keys($allowed) as $prefix) {
                    $query->orWhere('event_type', 'like', $prefix.'%');
                }
            });
    }
}
