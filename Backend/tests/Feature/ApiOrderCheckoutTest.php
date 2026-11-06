<?php

namespace Tests\Feature;

use App\Models\Order;
use App\Models\Sale;
use App\Models\SalePayment;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\CreatesApiContext;
use Tests\TestCase;

class ApiOrderCheckoutTest extends TestCase
{
    use CreatesApiContext, RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->createApiContext();
    }

    public function test_order_lifecycle_and_checkout_is_idempotent(): void
    {
        $this->openShift($this->owner);
        $product = $this->makeProduct(10000);
        Sanctum::actingAs($this->owner, ['api']);

        $created = $this->postJson('/api/v1/orders', [
            'order_type' => Order::TYPE_DINE_IN,
            'table_number' => 'A1',
            'items' => [
                ['product_uuid' => $product->uuid, 'quantity' => 2],
            ],
        ], $this->headers($this->owner));

        $created->assertCreated()
            ->assertJsonPath('data.status', Order::STATUS_DRAFT)
            ->assertJsonPath('data.version', 1)
            ->assertJsonPath('data.total', 20000);

        $orderUuid = $created->json('data.uuid');

        $this->putJson('/api/v1/orders/'.$orderUuid, [
            'base_version' => 1,
            'notes' => 'Tanpa bawang',
            'items' => [
                ['product_uuid' => $product->uuid, 'quantity' => 2],
            ],
        ], $this->headers($this->owner))
            ->assertOk()
            ->assertJsonPath('data.version', 2)
            ->assertJsonPath('data.notes', 'Tanpa bawang');

        $this->postJson('/api/v1/orders/'.$orderUuid.'/hold', ['base_version' => 2], $this->headers($this->owner))
            ->assertOk()
            ->assertJsonPath('data.status', Order::STATUS_HELD)
            ->assertJsonPath('data.version', 3);

        $this->postJson('/api/v1/orders/'.$orderUuid.'/resume', ['base_version' => 3], $this->headers($this->owner))
            ->assertOk()
            ->assertJsonPath('data.status', Order::STATUS_RESUMED)
            ->assertJsonPath('data.version', 4);

        $payload = [
            'order_uuid' => $orderUuid,
            'base_version' => 4,
            'payments' => [
                ['method' => SalePayment::METHOD_CASH, 'amount' => 20000, 'tendered_amount' => 25000],
            ],
        ];

        $checkout = $this->postJson('/api/v1/sales/checkout', $payload, $this->headers($this->owner) + [
            'Idempotency-Key' => 'checkout-1',
        ]);

        $checkout->assertCreated()
            ->assertJsonPath('data.lifecycle_status', Sale::LIFECYCLE_FINALIZED)
            ->assertJsonPath('data.payment_status', Sale::PAYMENT_PAID)
            ->assertJsonPath('data.confirmed_amount', 20000)
            ->assertJsonPath('data.payments.0.change_amount', 5000);

        $saleUuid = $checkout->json('data.uuid');
        $receipt = $checkout->json('data.receipt_number');

        $this->assertMatchesRegularExpression('/^RJS-PUSAT-T01-\d{10}$/', $receipt);

        $this->postJson('/api/v1/sales/checkout', $payload, $this->headers($this->owner) + [
            'Idempotency-Key' => 'checkout-1',
        ])
            ->assertCreated()
            ->assertJsonPath('data.uuid', $saleUuid);

        $this->assertSame(1, Sale::query()->count());
        $this->assertSame(1, SalePayment::query()->count());

        $order = Order::query()->where('uuid', $orderUuid)->firstOrFail();
        $this->assertSame(Order::STATUS_CONVERTED, $order->status);
        $this->assertSame(5, $order->version);
        $this->assertSame(
            Order::STATUS_RESUMED,
            $order->statusHistories()->orderByDesc('id')->value('from_status'),
        );
    }

    public function test_checkout_rejects_stale_base_version(): void
    {
        $this->openShift($this->owner);
        $product = $this->makeProduct(10000);
        Sanctum::actingAs($this->owner, ['api']);

        $orderUuid = $this->postJson('/api/v1/orders', [
            'items' => [['product_uuid' => $product->uuid, 'quantity' => 1]],
        ], $this->headers($this->owner))->json('data.uuid');

        $this->postJson('/api/v1/sales/checkout', [
            'order_uuid' => $orderUuid,
            'base_version' => 99,
        ], $this->headers($this->owner))
            ->assertStatus(409)
            ->assertJsonPath('error.code', 'ORDER_VERSION_MISMATCH');

        $this->assertSame(0, Sale::query()->count());
    }

    public function test_non_cash_payment_requires_a_different_verifier_and_blocks_void(): void
    {
        $this->openShift($this->owner);
        $product = $this->makeProduct(15000);
        $supervisor = $this->makeUser('supervisor@rujak.test', 'supervisor', 'supervisor');
        Sanctum::actingAs($this->owner, ['api']);

        $orderUuid = $this->postJson('/api/v1/orders', [
            'items' => [['product_uuid' => $product->uuid, 'quantity' => 1]],
        ], $this->headers($this->owner))->json('data.uuid');

        $checkout = $this->postJson('/api/v1/sales/checkout', [
            'order_uuid' => $orderUuid,
            'base_version' => 1,
            'payments' => [
                ['method' => SalePayment::METHOD_QRIS, 'amount' => 15000, 'provider_reference' => 'QR-1'],
            ],
        ], $this->headers($this->owner));

        $checkout->assertCreated()
            ->assertJsonPath('data.payment_status', Sale::PAYMENT_AWAITING_VERIFICATION)
            ->assertJsonPath('data.awaiting_verification_amount', 15000);

        $saleUuid = $checkout->json('data.uuid');
        $paymentUuid = $checkout->json('data.payments.0.uuid');

        $this->postJson('/api/v1/payments/'.$paymentUuid.'/verify', [
            'verified_amount' => 15000,
        ], $this->headers($this->owner))->assertForbidden();

        $this->assertTrue($supervisor->hasPermission('payments.verify'), 'Supervisor must hold payments.verify');

        Sanctum::actingAs($supervisor, ['api']);

        $verify = $this->postJson('/api/v1/payments/'.$paymentUuid.'/verify', [
            'verified_amount' => 15000,
            'provider_reference' => 'QR-1',
        ], $this->headers($supervisor));

        $this->assertSame(200, $verify->status(), $verify->getContent());
        $verify->assertJsonPath('data.status', SalePayment::STATUS_CONFIRMED);

        $sale = Sale::query()->where('uuid', $saleUuid)->firstOrFail();
        $this->assertSame(Sale::PAYMENT_PAID, $sale->payment_status);
        $this->assertSame(15000, $sale->confirmed_amount);
        $this->assertSame(0, $sale->outstanding_amount);

        Sanctum::actingAs($this->owner, ['api']);

        $this->postJson('/api/v1/sales/'.$saleUuid.'/void', [
            'reason' => 'Salah input',
        ], $this->headers($this->owner))
            ->assertStatus(422)
            ->assertJsonPath('error.code', 'VALIDATION_FAILED');

        $this->assertSame(Sale::LIFECYCLE_FINALIZED, $sale->refresh()->lifecycle_status);
    }

    public function test_refund_returns_money_without_recreating_debt(): void
    {
        $this->openShift($this->owner);
        $product = $this->makeProduct(10000);
        Sanctum::actingAs($this->owner, ['api']);

        $orderUuid = $this->postJson('/api/v1/orders', [
            'items' => [['product_uuid' => $product->uuid, 'quantity' => 1]],
        ], $this->headers($this->owner))->json('data.uuid');

        $saleUuid = $this->postJson('/api/v1/sales/checkout', [
            'order_uuid' => $orderUuid,
            'base_version' => 1,
            'payments' => [
                ['method' => SalePayment::METHOD_CASH, 'amount' => 10000, 'tendered_amount' => 10000],
            ],
        ], $this->headers($this->owner))->json('data.uuid');

        $this->postJson('/api/v1/sales/'.$saleUuid.'/refund', [
            'amount' => 4000,
            'reason' => 'Pelanggan membatalkan sebagian',
            'method' => 'cash',
        ], $this->headers($this->owner))
            ->assertOk()
            ->assertJsonPath('data.refunded_amount', 4000)
            ->assertJsonPath('data.outstanding_amount', 0)
            ->assertJsonPath('data.payment_status', Sale::PAYMENT_PARTIALLY_REFUNDED);

        $this->postJson('/api/v1/sales/'.$saleUuid.'/refund', [
            'amount' => 7000,
            'reason' => 'Melebihi dana terkonfirmasi',
        ], $this->headers($this->owner))->assertStatus(422);
    }
}
