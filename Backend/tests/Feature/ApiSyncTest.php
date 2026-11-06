<?php

namespace Tests\Feature;

use App\Models\AuthorizationLease;
use App\Models\Order;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use Illuminate\Testing\TestResponse;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\CreatesApiContext;
use Tests\TestCase;

class ApiSyncTest extends TestCase
{
    use CreatesApiContext;
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->createApiContext();
        Sanctum::actingAs($this->owner, ['api']);
    }

    public function test_push_accepts_order_and_handles_duplicate_and_idempotency_conflicts(): void
    {
        $orderUuid = (string) Str::uuid();
        $event = $this->event('order.created', $this->orderPayload($orderUuid), 1);

        $first = $this->push([$event])->assertOk();
        $first->assertJsonPath('data.results.0.status', 'accepted')
            ->assertJsonPath('data.results.0.server_record_id', $orderUuid);

        $order = Order::query()->where('uuid', $orderUuid)->firstOrFail();
        $this->assertSame(1, (int) $order->version);
        $this->assertSame(10000, (int) $order->total);

        $this->push([$event])->assertOk()
            ->assertJsonPath('data.results.0.status', 'duplicate');

        $changed = $event;
        $changed['payload'] = $this->orderPayload($orderUuid, 12000);

        $this->push([$changed])->assertOk()
            ->assertJsonPath('data.results.0.status', 'conflict')
            ->assertJsonPath('data.results.0.error_code', 'IDEMPOTENCY_KEY_REUSED');

        $reusedSequence = $this->event(
            'order.created',
            $this->orderPayload((string) Str::uuid()),
            1,
        );

        $this->push([$reusedSequence])->assertOk()
            ->assertJsonPath('data.results.0.status', 'conflict')
            ->assertJsonPath('data.results.0.error_code', 'SEQUENCE_ALREADY_USED');
    }

    public function test_offline_events_require_lease_and_can_be_retried_after_lease_issue(): void
    {
        $firstEvent = $this->event(
            'order.created',
            $this->orderPayload((string) Str::uuid()),
            1,
        );

        $this->push([$firstEvent], 'offline')->assertOk()
            ->assertJsonPath('data.results.0.status', 'rejected')
            ->assertJsonPath('data.results.0.error_code', 'LEASE_REQUIRED');

        $leaseToken = $this->postJson('/api/v1/auth/offline-lease', [], $this->headers($this->owner))
            ->assertOk()
            ->json('data.token');

        $firstEvent['occurred_at'] = now()->addSecond()->toIso8601String();

        $this->push([$firstEvent], 'offline', $leaseToken)->assertOk()
            ->assertJsonPath('data.results.0.status', 'accepted');

        $expiredEvent = $this->event(
            'order.created',
            $this->orderPayload((string) Str::uuid()),
            2,
        );
        $expiredEvent['occurred_at'] = now()->addMinute()->toIso8601String();

        AuthorizationLease::query()
            ->where('device_id', $this->device->id)
            ->latest('id')
            ->firstOrFail()
            ->forceFill(['expires_at' => now()->addSeconds(10)])
            ->save();

        $this->push([$expiredEvent], 'offline', $leaseToken)->assertOk()
            ->assertJsonPath('data.results.0.status', 'rejected')
            ->assertJsonPath('data.results.0.error_code', 'LEASE_EXPIRED_AT_EVENT');
    }

    public function test_push_rejects_protocol_and_device_mismatches(): void
    {
        $payload = $this->batch([$this->event('order.created', $this->orderPayload((string) Str::uuid()), 1)]);

        $this->postJson('/api/v1/sync/push', ['protocol_version' => 2] + $payload, $this->headers($this->owner))
            ->assertStatus(426)
            ->assertJsonPath('error.code', 'PROTOCOL_UPGRADE_REQUIRED');

        $this->postJson(
            '/api/v1/sync/push',
            ['device_id' => (string) Str::uuid()] + $payload,
            $this->headers($this->owner),
        )->assertStatus(403)->assertJsonPath('error.code', 'DEVICE_MISMATCH');

        $this->postJson(
            '/api/v1/sync/push',
            ['outlet_id' => (string) Str::uuid()] + $payload,
            $this->headers($this->owner),
        )->assertStatus(403)->assertJsonPath('error.code', 'OUTLET_MISMATCH');
    }

    public function test_pull_paginates_with_stable_cursor_and_rejects_invalid_cursor(): void
    {
        $this->push([
            $this->event('order.created', $this->orderPayload((string) Str::uuid()), 1),
            $this->event('order.created', $this->orderPayload((string) Str::uuid()), 2),
        ])->assertOk();

        $first = $this->getJson('/api/v1/sync/pull?limit=1', $this->headers($this->owner))->assertOk();
        $this->assertCount(1, $first->json('data.changes'));
        $this->assertTrue($first->json('data.has_more'));
        $cursor = (string) $first->json('data.next_cursor');
        $this->assertNotSame('', $cursor);

        $second = $this->getJson(
            '/api/v1/sync/pull?limit=1&cursor='.urlencode($cursor),
            $this->headers($this->owner),
        )->assertOk();
        $this->assertCount(1, $second->json('data.changes'));
        $this->assertFalse($second->json('data.has_more'));

        $third = $this->getJson(
            '/api/v1/sync/pull?cursor='.urlencode((string) $second->json('data.next_cursor')),
            $this->headers($this->owner),
        )->assertOk();
        $this->assertCount(0, $third->json('data.changes'));

        $this->getJson('/api/v1/sync/pull?cursor=not-a-cursor', $this->headers($this->owner))
            ->assertStatus(400)
            ->assertJsonPath('error.code', 'SYNC_CURSOR_INVALID');
    }

    public function test_bootstrap_returns_device_config_catalog_and_open_shift(): void
    {
        $product = $this->makeProduct(8000);
        $shiftUuid = $this->postJson('/api/v1/shifts/open', [
            'opening_cash' => 50000,
        ], $this->headers($this->owner))->assertCreated()->json('data.uuid');

        $response = $this->getJson('/api/v1/sync/bootstrap', $this->headers($this->owner))->assertOk();

        $response->assertJsonPath('data.device.uuid', $this->device->uuid)
            ->assertJsonPath('data.outlet.uuid', $this->outlet->uuid)
            ->assertJsonPath('data.user.uuid', $this->owner->uuid)
            ->assertJsonPath('data.user.has_pin', false)
            ->assertJsonPath('data.config.receipt_number_format', 'RJS-{OUTLET}-{TERMINAL}-{SEQUENCE}')
            ->assertJsonPath('data.config.offline_lease_max_hours', 72)
            ->assertJsonPath('data.config.sync.max_batch_events', 50)
            ->assertJsonPath('data.catalog.offline_catalog_max_age_hours', 72)
            ->assertJsonPath('data.open_shift.uuid', $shiftUuid);

        $this->assertContains(
            $product->uuid,
            collect($response->json('data.catalog.products'))->pluck('uuid')->all(),
        );

        $this->assertNotEmpty($response->json('data.sync.cursor'));
    }

    public function test_status_reports_device_and_event_counters(): void
    {
        $this->push([$this->event('order.created', $this->orderPayload((string) Str::uuid()), 1)])
            ->assertOk();

        $this->push([$this->event('order.created', $this->orderPayload((string) Str::uuid()), 1)])
            ->assertOk();

        $status = $this->getJson('/api/v1/sync/status', $this->headers($this->owner))->assertOk();

        $status->assertJsonPath('data.device.uuid', $this->device->uuid)
            ->assertJsonPath('data.sync.protocol_version', 1)
            ->assertJsonPath('data.sync.conflicts', 1)
            ->assertJsonPath('data.sync.rejected', 0);

        $this->assertGreaterThanOrEqual(1, $status->json('data.device.last_sequence'));
    }

    private function push(array $events, string $origin = 'online', ?string $leaseToken = null): TestResponse
    {
        return $this->postJson(
            '/api/v1/sync/push',
            $this->batch($events, $origin, $leaseToken),
            $this->headers($this->owner),
        );
    }

    private function batch(array $events, string $origin = 'online', ?string $leaseToken = null): array
    {
        return [
            'protocol_version' => 1,
            'batch_id' => (string) Str::uuid(),
            'device_id' => $this->device->uuid,
            'outlet_id' => $this->outlet->uuid,
            'origin' => $origin,
            'lease_token' => $leaseToken,
            'events' => $events,
        ];
    }

    private function event(string $type, array $payload, int $sequence, ?string $eventId = null): array
    {
        return [
            'event_id' => $eventId ?? (string) Str::uuid(),
            'event_type' => $type,
            'aggregate_type' => 'order',
            'aggregate_id' => (string) ($payload['order_uuid'] ?? Str::uuid()),
            'sequence' => $sequence,
            'schema_version' => 1,
            'occurred_at' => now()->toIso8601String(),
            'payload' => $payload,
        ];
    }

    private function orderPayload(string $uuid, int $total = 10000): array
    {
        return [
            'order_uuid' => $uuid,
            'status' => Order::STATUS_DRAFT,
            'version' => 1,
            'order_type' => Order::TYPE_DINE_IN,
            'subtotal' => $total,
            'item_discount_total' => 0,
            'transaction_discount_total' => 0,
            'discount_total' => 0,
            'service_charge' => 0,
            'tax_total' => 0,
            'total' => $total,
            'pricing_snapshot' => ['lines' => []],
            'created_at' => now()->toIso8601String(),
            'items' => [[
                'item_uuid' => (string) Str::uuid(),
                'product_uuid' => (string) Str::uuid(),
                'quantity' => 1,
                'unit_price' => $total,
                'line_subtotal' => $total,
                'line_total' => $total,
            ]],
        ];
    }
}
