<?php

namespace Tests\Feature;

use App\Models\Device;
use App\Models\Order;
use App\Models\Outlet;
use App\Models\Role;
use App\Models\Sale;
use App\Models\SalePayment;
use App\Models\Shift;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
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
        $this->assertTrue($opened->json('data.is_active'));
        $this->assertSame($this->owner->uuid, $opened->json('data.opened_by.uuid'));

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
            ->assertJsonPath('data.closing_snapshot.actual_cash', 118000)
            ->assertJsonPath('data.closing_snapshot.device_count', 1)
            ->assertJsonPath('data.closing_snapshot.synced_device_count', 1)
            ->assertJsonPath('data.closing_snapshot.closed_by.uuid', $this->owner->uuid);

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

    public function test_outlet_has_only_one_active_shift_regardless_of_user_or_device(): void
    {
        $this->postJson('/api/v1/shifts/open', [
            'opening_cash' => 100000,
        ], $this->headers($this->owner))->assertCreated();

        $admin = $this->makeUser('admin2@rujak.test', 'admin2', 'admin');
        $adminDevice = $this->makeDevice('T02');

        Sanctum::actingAs($admin, ['api']);

        $this->postJson('/api/v1/shifts/open', [
            'opening_cash' => 20000,
        ], $this->headers($admin, $adminDevice))
            ->assertStatus(409)
            ->assertJsonPath('error.code', 'SHIFT_ALREADY_OPEN');

        $cashier = $this->makeUser('kasir2@rujak.test', 'kasir2', 'kasir');
        $cashierDevice = $this->makeDevice('T03');

        Sanctum::actingAs($cashier, ['api']);

        $this->postJson('/api/v1/shifts/open', [
            'opening_cash' => 10000,
        ], $this->headers($cashier, $cashierDevice))
            ->assertStatus(403);

        $this->assertSame(1, Shift::query()->where('status', Shift::STATUS_OPEN)->count());
    }

    public function test_cashiers_share_one_outlet_shift_and_sales_keep_actual_cashier(): void
    {
        $shiftUuid = $this->postJson('/api/v1/shifts/open', [
            'opening_cash' => 100000,
        ], $this->headers($this->owner))->assertCreated()->json('data.uuid');

        $shift = Shift::query()->where('uuid', $shiftUuid)->firstOrFail();
        $product = $this->makeProduct(10000);

        $cashierA = $this->makeUser('kasir.a@rujak.test', 'kasira', 'kasir');
        $deviceA = $this->makeDevice('T02');
        $cashierB = $this->makeUser('kasir.b@rujak.test', 'kasirb', 'kasir');
        $deviceB = $this->makeDevice('T03');

        Sanctum::actingAs($cashierA, ['api']);
        $this->getJson('/api/v1/shifts/active', $this->headers($cashierA, $deviceA))
            ->assertOk()
            ->assertJsonPath('data.uuid', $shiftUuid)
            ->assertJsonPath('data.opened_by.name', $this->owner->name);

        Sanctum::actingAs($cashierB, ['api']);
        $this->getJson('/api/v1/shifts/active', $this->headers($cashierB, $deviceB))
            ->assertOk()
            ->assertJsonPath('data.uuid', $shiftUuid);

        Sanctum::actingAs($cashierA, ['api']);
        $this->checkoutCashierOrder($cashierA, $deviceA, $product->uuid, 10000);

        Sanctum::actingAs($cashierB, ['api']);
        $this->checkoutCashierOrder($cashierB, $deviceB, $product->uuid, 10000);

        $sales = Sale::query()->orderBy('device_id')->get();
        $this->assertCount(2, $sales);
        $this->assertSame([$shift->id], $sales->pluck('shift_id')->unique()->values()->all());
        $this->assertEqualsCanonicalizing(
            [$cashierA->id, $cashierB->id],
            $sales->pluck('user_id')->unique()->values()->all(),
        );
        $this->assertEqualsCanonicalizing(
            [$deviceA->id, $deviceB->id],
            $sales->pluck('device_id')->unique()->values()->all(),
        );

        Sanctum::actingAs($this->owner, ['api']);

        $closing = $this->postJson('/api/v1/shifts/close', [
            'shift_uuid' => $shiftUuid,
            'actual_cash' => 120000,
        ], $this->headers($this->owner))->assertOk();

        $closing->assertJsonPath('data.status', 'closing')
            ->assertJsonPath('data.sync.pending_device_count', 2)
            ->assertJsonPath('data.closing_snapshot', null);
        $this->assertDatabaseCount('shift_closing_snapshots', 0);

        Sanctum::actingAs($cashierA, ['api']);
        $this->postJson('/api/v1/shifts/'.$shiftUuid.'/sync-checkpoint', [
            'close_epoch' => $closing->json('data.close_epoch'),
            'pending_outbox_count' => 0,
        ], $this->headers($cashierA, $deviceA))
            ->assertOk()
            ->assertJsonPath('data.status', 'closing')
            ->assertJsonPath('data.sync.pending_device_count', 1);

        Sanctum::actingAs($cashierB, ['api']);
        $this->postJson('/api/v1/shifts/'.$shiftUuid.'/sync-checkpoint', [
            'close_epoch' => $closing->json('data.close_epoch'),
            'pending_outbox_count' => 0,
        ], $this->headers($cashierB, $deviceB))
            ->assertOk()
            ->assertJsonPath('data.status', 'closed_confirmed')
            ->assertJsonPath('data.closing_snapshot.expected_cash', 120000)
            ->assertJsonPath('data.closing_snapshot.device_count', 3)
            ->assertJsonPath('data.closing_snapshot.synced_device_count', 3);

        $this->assertDatabaseCount('shift_closing_snapshots', 1);
        $this->assertSame(3, (int) $shift->closingSnapshot()->firstOrFail()->device_count);
    }

    public function test_close_from_another_device_keeps_opener_and_closer_identity_separate(): void
    {
        $shiftUuid = $this->postJson('/api/v1/shifts/open', [
            'opening_cash' => 100000,
        ], $this->headers($this->owner))->assertCreated()->json('data.uuid');

        $admin = $this->makeUser('admin.close@rujak.test', 'adminclose', 'admin');
        $adminDevice = $this->makeDevice('T04');
        $cashier = $this->makeUser('kasir.c@rujak.test', 'kasirc', 'kasir');
        $cashierDevice = $this->makeDevice('T05');

        Sanctum::actingAs($cashier, ['api']);
        $this->getJson('/api/v1/shifts/active', $this->headers($cashier, $cashierDevice))
            ->assertOk()
            ->assertJsonPath('data.uuid', $shiftUuid);

        $this->postJson('/api/v1/shifts/close', [
            'shift_uuid' => $shiftUuid,
            'actual_cash' => 100000,
        ], $this->headers($cashier, $cashierDevice))
            ->assertStatus(403);

        Sanctum::actingAs($admin, ['api']);
        $closing = $this->postJson('/api/v1/shifts/close', [
            'shift_uuid' => $shiftUuid,
            'actual_cash' => 100000,
        ], $this->headers($admin, $adminDevice))->assertOk();

        $closing->assertJsonPath('data.status', 'closing')
            ->assertJsonPath('data.sync.pending_device_count', 2)
            ->assertJsonPath('data.closing_requested_by.uuid', $admin->uuid)
            ->assertJsonPath('data.closing_requested_device.uuid', $adminDevice->uuid);

        Sanctum::actingAs($this->owner, ['api']);
        $this->postJson('/api/v1/shifts/'.$shiftUuid.'/sync-checkpoint', [
            'pending_outbox_count' => 0,
        ], $this->headers($this->owner))->assertOk();

        Sanctum::actingAs($cashier, ['api']);
        $confirmed = $this->postJson('/api/v1/shifts/'.$shiftUuid.'/sync-checkpoint', [
            'pending_outbox_count' => 0,
        ], $this->headers($cashier, $cashierDevice))->assertOk();

        $confirmed->assertJsonPath('data.status', 'closed_confirmed')
            ->assertJsonPath('data.opened_by.uuid', $this->owner->uuid)
            ->assertJsonPath('data.opened_device.uuid', $this->device->uuid)
            ->assertJsonPath('data.closed_by.uuid', $admin->uuid)
            ->assertJsonPath('data.closed_device.uuid', $adminDevice->uuid)
            ->assertJsonPath('data.closing_snapshot.closed_by.uuid', $admin->uuid)
            ->assertJsonPath('data.closing_snapshot.closed_device.uuid', $adminDevice->uuid);

        $this->assertDatabaseHas('shift_closing_snapshots', [
            'shift_id' => Shift::query()->where('uuid', $shiftUuid)->value('id'),
            'user_id' => $this->owner->id,
            'device_id' => $this->device->id,
            'closed_by_user_id' => $admin->id,
            'closed_device_id' => $adminDevice->id,
        ]);
    }

    public function test_close_waits_for_every_participant_and_ignores_owner_pending_count_as_proof(): void
    {
        $shiftUuid = $this->postJson('/api/v1/shifts/open', [
            'opening_cash' => 100000,
        ], $this->headers($this->owner))->assertCreated()->json('data.uuid');

        $cashier = $this->makeUser('kasir.d@rujak.test', 'kasird', 'kasir');
        $cashierDevice = $this->makeDevice('T06');

        Sanctum::actingAs($cashier, ['api']);
        $this->getJson('/api/v1/shifts/active', $this->headers($cashier, $cashierDevice))->assertOk();

        Sanctum::actingAs($this->owner, ['api']);
        $closing = $this->postJson('/api/v1/shifts/close', [
            'shift_uuid' => $shiftUuid,
            'actual_cash' => 100000,
            'pending_sync_count' => 2,
        ], $this->headers($this->owner))->assertOk();

        $closing->assertJsonPath('data.status', 'closing')
            ->assertJsonPath('data.sync.pending_device_count', 2);

        $this->postJson('/api/v1/shifts/'.$shiftUuid.'/sync-checkpoint', [
            'pending_outbox_count' => 0,
        ], $this->headers($this->owner))
            ->assertOk()
            ->assertJsonPath('data.status', 'closing')
            ->assertJsonPath('data.sync.pending_device_count', 1);

        Sanctum::actingAs($cashier, ['api']);
        $this->postJson('/api/v1/shifts/'.$shiftUuid.'/sync-checkpoint', [
            'pending_outbox_count' => 0,
        ], $this->headers($cashier, $cashierDevice))
            ->assertOk()
            ->assertJsonPath('data.status', 'closed_confirmed');

        $this->assertDatabaseCount('shift_closing_snapshots', 1);
    }

    public function test_shift_endpoints_are_tenant_and_outlet_scoped(): void
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

        $otherOutlet = Outlet::create([
            'uuid' => (string) Str::uuid(),
            'business_id' => $this->business->id,
            'name' => 'Outlet Lain',
            'code' => 'LAIN',
            'is_active' => true,
        ]);

        $sameBusinessOtherOutlet = User::create([
            'uuid' => (string) Str::uuid(),
            'name' => 'Kasir Outlet Lain',
            'email' => 'outlet.lain@rujak.test',
            'username' => 'outletlain',
            'password' => 'password',
            'business_id' => $this->business->id,
            'outlet_id' => $otherOutlet->id,
            'is_active' => true,
            'email_verified_at' => now(),
        ]);
        $sameBusinessOtherOutlet->roles()->attach(Role::query()->where('slug', 'owner')->firstOrFail());
        $otherOutletDevice = $this->makeDevice('T07', $otherOutlet->id);

        Sanctum::actingAs($sameBusinessOtherOutlet, ['api']);

        $this->getJson('/api/v1/shifts/'.$shiftUuid, $this->headers($sameBusinessOtherOutlet, $otherOutletDevice))
            ->assertStatus(404);

        $this->getJson('/api/v1/shifts/active', $this->headers($sameBusinessOtherOutlet, $otherOutletDevice))
            ->assertOk()
            ->assertJsonPath('data', null);
    }

    public function test_closed_shift_remains_readable_and_history_is_not_rewritten(): void
    {
        $shiftUuid = $this->postJson('/api/v1/shifts/open', [
            'opening_cash' => 100000,
        ], $this->headers($this->owner))->assertCreated()->json('data.uuid');

        $this->postJson('/api/v1/shifts/close', [
            'shift_uuid' => $shiftUuid,
            'actual_cash' => 100000,
        ], $this->headers($this->owner))->assertOk()->assertJsonPath('data.status', 'closed_confirmed');

        $this->getJson('/api/v1/shifts/'.$shiftUuid, $this->headers($this->owner))
            ->assertOk()
            ->assertJsonPath('data.uuid', $shiftUuid)
            ->assertJsonPath('data.status', 'closed_confirmed')
            ->assertJsonPath('data.opening_cash', 100000)
            ->assertJsonPath('data.closing_snapshot.actual_cash', 100000);

        $this->getJson('/api/v1/shifts?active_only=1', $this->headers($this->owner))
            ->assertOk()
            ->assertJsonCount(0, 'data');
    }

    private function checkoutCashierOrder(User $cashier, Device $device, string $productUuid, int $amount): void
    {
        $orderUuid = $this->postJson('/api/v1/orders', [
            'order_type' => Order::TYPE_DINE_IN,
            'items' => [['product_uuid' => $productUuid, 'quantity' => 1]],
        ], $this->headers($cashier, $device))->assertCreated()->json('data.uuid');

        $this->postJson('/api/v1/sales/checkout', [
            'order_uuid' => $orderUuid,
            'base_version' => 1,
            'payments' => [[
                'method' => SalePayment::METHOD_CASH,
                'amount' => $amount,
                'tendered_amount' => $amount,
            ]],
        ], $this->headers($cashier, $device))->assertCreated();
    }
}
