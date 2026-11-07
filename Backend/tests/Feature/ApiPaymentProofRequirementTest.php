<?php

namespace Tests\Feature;

use App\Models\Product;
use App\Models\Sale;
use App\Models\SalePayment;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\CreatesApiContext;
use Tests\TestCase;

class ApiPaymentProofRequirementTest extends TestCase
{
    use CreatesApiContext, RefreshDatabase;

    private const PNG_BYTES = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Wl2nWQAAAAASUVORK5CYII=';

    protected function setUp(): void
    {
        parent::setUp();
        $this->createApiContext();
        Storage::fake('local');
    }

    public function test_non_cash_checkout_does_not_require_a_reference(): void
    {
        $admin = $this->makeUser('admin@rujak.test', 'admin', 'admin');
        $this->openShift($admin);
        $product = $this->makeProduct(15000);
        Sanctum::actingAs($admin, ['api']);

        $payment = $this->checkoutQris($product, $admin);

        $this->assertSame(SalePayment::STATUS_AWAITING_VERIFICATION, $payment->status);
        $this->assertNull($payment->provider_reference);
        $this->assertFalse((bool) $payment->proof_required);
    }

    public function test_business_can_require_proof_and_verification_waits_for_upload(): void
    {
        $this->business->update(['non_cash_proof_required' => true]);

        $admin = $this->makeUser('admin@rujak.test', 'admin', 'admin');
        $this->openShift($admin);
        $product = $this->makeProduct(15000);
        Sanctum::actingAs($admin, ['api']);

        $payment = $this->checkoutQris($product, $admin);
        $this->assertTrue((bool) $payment->proof_required);
        $this->assertNull($payment->proof_path);

        $supervisor = $this->makeUser('supervisor@rujak.test', 'supervisor', 'supervisor');
        Sanctum::actingAs($supervisor, ['api']);

        $blocked = $this->postJson('/api/v1/payments/'.$payment->uuid.'/verify', [
            'verified_amount' => 15000,
        ], $this->headers($supervisor));

        $blocked->assertStatus(422)
            ->assertJsonPath('error.code', 'VALIDATION_FAILED');

        Sanctum::actingAs($admin, ['api']);
        $this->post('/api/v1/payments/'.$payment->uuid.'/proof', [
            'proof' => $this->pngUpload(),
        ], $this->headers($admin))->assertCreated();

        Sanctum::actingAs($supervisor, ['api']);
        $this->postJson('/api/v1/payments/'.$payment->uuid.'/verify', [
            'verified_amount' => 15000,
        ], $this->headers($supervisor))
            ->assertOk()
            ->assertJsonPath('data.status', SalePayment::STATUS_CONFIRMED);

        $sale = Sale::query()->findOrFail($payment->sale_id);
        $this->assertSame(Sale::PAYMENT_PAID, $sale->payment_status);
    }

    public function test_owner_is_exempt_from_required_proof(): void
    {
        $this->business->update(['non_cash_proof_required' => true]);

        $this->openShift($this->owner);
        $product = $this->makeProduct(15000);
        Sanctum::actingAs($this->owner, ['api']);

        $payment = $this->checkoutQris($product, $this->owner);

        $this->assertFalse((bool) $payment->proof_required);
        $this->assertSame(SalePayment::STATUS_CONFIRMED, $payment->status);
        $this->assertSame($this->owner->id, (int) $payment->verified_by);
    }

    private function checkoutQris(Product $product, User $actor): SalePayment
    {
        $orderUuid = $this->postJson('/api/v1/orders', [
            'items' => [['product_uuid' => $product->uuid, 'quantity' => 1]],
        ], $this->headers($actor))->json('data.uuid');

        $response = $this->postJson('/api/v1/sales/checkout', [
            'order_uuid' => $orderUuid,
            'base_version' => 1,
            'payments' => [
                ['method' => SalePayment::METHOD_QRIS, 'amount' => 15000],
            ],
        ], $this->headers($actor));

        $response->assertCreated();

        return SalePayment::query()
            ->where('uuid', $response->json('data.payments.0.uuid'))
            ->firstOrFail();
    }

    private function pngUpload(string $name = 'proof.png'): UploadedFile
    {
        $path = tempnam(sys_get_temp_dir(), 'proof').'.png';
        file_put_contents($path, base64_decode(self::PNG_BYTES));

        return new UploadedFile($path, $name, 'image/png', null, true);
    }
}
