<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\CreatesApiContext;
use Tests\TestCase;

class ApiShiftTest extends TestCase
{
    use CreatesApiContext;
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->createApiContext();
        Sanctum::actingAs($this->owner, ['api']);
    }

    public function test_shift_lifecycle_tracks_cash_and_persists_immutable_snapshot(): void
    {
        $opened = $this->postJson('/api/v1/shifts/open', [
            'opening_cash' => 100000,
        ], $this->headers($this->owner))->assertCreated();

        $shiftUuid = $opened->json('data.uuid');
        $this->assertSame(100000, $opened->json('data.expected_cash'));

        $this->postJson('/api/v1/shifts/open', [
            'opening_cash' => 50000,
        ], $this->headers($this->owner))
            ->assertStatus(409)
            ->assertJsonPath('error.code', 'SHIFT_ALREADY_OPEN');

        $this->postJson('/api/v1/shifts/'.$shiftUuid.'/cash-movements', [
            'type' => 'in',
            'amount' => 25000,
            'reason' => 'Tambahan modal',
        ], $this->headers($this->owner))
            ->assertCreated()
            ->assertJsonPath('data.expected_cash', 125000);

        $this->postJson('/api/v1/shifts/'.$shiftUuid.'/cash-movements', [
            'type' => 'out',
            'amount' => 5000,
            'reason' => 'Beli es batu',
        ], $this->headers($this->owner))
            ->assertCreated()
            ->assertJsonPath('data.expected_cash', 120000);

        $closed = $this->postJson('/api/v1/shifts/close', [
            'shift_uuid' => $shiftUuid,
            'actual_cash' => 118000,
            'closing_notes' => 'Tutup malam',
        ], $this->headers($this->owner))->assertOk();

        $closed->assertJsonPath('data.status', 'closed_confirmed')
            ->assertJsonPath('data.expected_cash', 120000)
            ->assertJsonPath('data.variance', -2000)
            ->assertJsonPath('data.closing_snapshot.expected_cash', 120000)
            ->assertJsonPath('data.closing_snapshot.actual_cash', 118000);

        $this->assertDatabaseCount('shift_closing_snapshots', 1);

        $this->postJson('/api/v1/shifts/close', [
            'shift_uuid' => $shiftUuid,
            'actual_cash' => 118000,
        ], $this->headers($this->owner))
            ->assertStatus(409)
            ->assertJsonPath('error.code', 'SHIFT_NOT_OPEN');

        $this->postJson('/api/v1/shifts/'.$shiftUuid.'/cash-movements', [
            'type' => 'in',
            'amount' => 1000,
            'reason' => 'Setelah tutup',
        ], $this->headers($this->owner))
            ->assertStatus(409)
            ->assertJsonPath('error.code', 'SHIFT_NOT_OPEN');

        $this->assertDatabaseCount('shift_closing_snapshots', 1);
    }

    public function test_held_orders_block_shift_close(): void
    {
        $shiftUuid = $this->postJson('/api/v1/shifts/open', [
            'opening_cash' => 100000,
        ], $this->headers($this->owner))->assertCreated()->json('data.uuid');

        $product = $this->makeProduct(10000);

        $orderUuid = $this->postJson('/api/v1/orders', [
            'items' => [['product_uuid' => $product->uuid, 'quantity' => 1]],
        ], $this->headers($this->owner))->assertCreated()->json('data.uuid');

        $this->postJson('/api/v1/orders/'.$orderUuid.'/hold', [
            'base_version' => 1,
        ], $this->headers($this->owner))->assertOk();

        $this->postJson('/api/v1/shifts/close', [
            'shift_uuid' => $shiftUuid,
            'actual_cash' => 100000,
        ], $this->headers($this->owner))
            ->assertStatus(409)
            ->assertJsonPath('error.code', 'SHIFT_HAS_HELD_ORDERS');
    }

    public function test_pending_sync_shift_requires_reconciliation(): void
    {
        $shiftUuid = $this->postJson('/api/v1/shifts/open', [
            'opening_cash' => 100000,
        ], $this->headers($this->owner))->assertCreated()->json('data.uuid');

        $this->postJson('/api/v1/shifts/close', [
            'shift_uuid' => $shiftUuid,
            'actual_cash' => 100000,
            'pending_sync_count' => 2,
            'local_event_sequence' => 42,
        ], $this->headers($this->owner))
            ->assertOk()
            ->assertJsonPath('data.status', 'closed_pending_sync')
            ->assertJsonPath('data.pending_sync_count', 2);

        $this->postJson('/api/v1/shifts/'.$shiftUuid.'/reconcile', [
            'resolution_note' => 'Seluruh event sudah tersinkron',
        ], $this->headers($this->owner))
            ->assertOk()
            ->assertJsonPath('data.status', 'closed_confirmed')
            ->assertJsonPath('data.pending_sync_count', 0);

        $this->postJson('/api/v1/shifts/'.$shiftUuid.'/reconcile', [
            'resolution_note' => 'Rekonsiliasi ulang',
        ], $this->headers($this->owner))
            ->assertStatus(409)
            ->assertJsonPath('error.code', 'SHIFT_ALREADY_RECONCILED');
    }

    public function test_shift_endpoints_are_tenant_scoped(): void
    {
        $shiftUuid = $this->postJson('/api/v1/shifts/open', [
            'opening_cash' => 100000,
        ], $this->headers($this->owner))->assertCreated()->json('data.uuid');

        [, , $otherUser, $otherDevice] = $this->makeTenant('tenantd');

        Sanctum::actingAs($otherUser, ['api']);

        $this->getJson('/api/v1/shifts/'.$shiftUuid, $this->headers($otherUser, $otherDevice))
            ->assertStatus(404);

        $this->postJson('/api/v1/shifts/close', [
            'shift_uuid' => $shiftUuid,
            'actual_cash' => 100000,
        ], $this->headers($otherUser, $otherDevice))
            ->assertStatus(404);
    }
}
