<?php

namespace Tests\Feature;

use App\Models\PaymentVerificationLog;
use App\Models\Product;
use App\Models\Sale;
use App\Models\SalePayment;
use App\Models\SyncEvent;
use App\Models\User;
use App\Services\SalePaymentAggregator;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Artisan;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\CreatesApiContext;
use Tests\TestCase;

class OwnerPaymentBackfillTest extends TestCase
{
    use CreatesApiContext, RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->createApiContext();
    }

    public function test_command_confirms_only_historical_owner_non_cash_payments(): void
    {
        $admin = $this->makeUser('admin@rujak.test', 'admin', 'admin');
        $this->openShift($admin);
        $product = $this->makeProduct(15000);
        Sanctum::actingAs($admin, ['api']);

        $ownerPayment = $this->checkoutQris($product, $admin, 'QR-OWNER');
        $ownerPayment->forceFill([
            'recorded_by' => $this->owner->id,
            'status' => SalePayment::STATUS_AWAITING_VERIFICATION,
            'verified_amount' => null,
            'verified_by' => null,
            'verified_at' => null,
        ])->save();

        app(SalePaymentAggregator::class)->recalculate($ownerPayment->sale);

        $adminPayment = $this->checkoutQris($product, $admin, 'QR-ADMIN');

        Artisan::call('payments:confirm-owner-pending', ['--dry-run' => true]);
        $this->assertSame(
            SalePayment::STATUS_AWAITING_VERIFICATION,
            $ownerPayment->refresh()->status,
            'Dry run tidak boleh mengubah status.',
        );

        $exitCode = Artisan::call('payments:confirm-owner-pending');
        $this->assertSame(0, $exitCode);

        $ownerPayment->refresh();
        $this->assertSame(SalePayment::STATUS_CONFIRMED, $ownerPayment->status);
        $this->assertSame($this->owner->id, (int) $ownerPayment->verified_by);
        $this->assertSame(15000, (int) $ownerPayment->verified_amount);
        $this->assertNotNull($ownerPayment->verified_at);

        $this->assertSame(
            SalePayment::STATUS_AWAITING_VERIFICATION,
            $adminPayment->refresh()->status,
            'Pembayaran non-Owner harus tetap menunggu verifikasi.',
        );

        $sale = Sale::query()->findOrFail($ownerPayment->sale_id);
        $this->assertSame(Sale::PAYMENT_PAID, $sale->payment_status);
        $this->assertSame(15000, (int) $sale->confirmed_amount);
        $this->assertSame(0, (int) $sale->awaiting_verification_amount);
        $this->assertSame(0, (int) $sale->outstanding_amount);

        $this->assertDatabaseHas('payment_verification_logs', [
            'sale_payment_id' => $ownerPayment->id,
            'action' => 'auto_confirmed',
            'actor_id' => $this->owner->id,
            'recorded_amount' => 15000,
            'verified_amount' => 15000,
        ]);

        $this->assertTrue(
            SyncEvent::query()
                ->where('event_type', 'payment.verified')
                ->where('aggregate_id', $ownerPayment->uuid)
                ->exists(),
        );

        $logsBefore = PaymentVerificationLog::query()
            ->where('sale_payment_id', $ownerPayment->id)
            ->count();

        Artisan::call('payments:confirm-owner-pending');

        $this->assertSame(
            $logsBefore,
            PaymentVerificationLog::query()
                ->where('sale_payment_id', $ownerPayment->id)
                ->count(),
            'Command harus idempoten.',
        );
    }

    private function checkoutQris(Product $product, User $actor, string $reference): SalePayment
    {
        $orderUuid = $this->postJson('/api/v1/orders', [
            'items' => [['product_uuid' => $product->uuid, 'quantity' => 1]],
        ], $this->headers($actor))->json('data.uuid');

        $response = $this->postJson('/api/v1/sales/checkout', [
            'order_uuid' => $orderUuid,
            'base_version' => 1,
            'payments' => [
                ['method' => SalePayment::METHOD_QRIS, 'amount' => 15000, 'provider_reference' => $reference],
            ],
        ], $this->headers($actor));

        $response->assertCreated();

        return SalePayment::query()
            ->where('uuid', $response->json('data.payments.0.uuid'))
            ->firstOrFail();
    }
}
