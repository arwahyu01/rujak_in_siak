<?php

namespace Tests\Feature;

use App\Models\AuditLog;
use App\Models\Outlet;
use App\Models\Sale;
use App\Models\SalePayment;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\CreatesApiContext;
use Tests\TestCase;

class ApiPaymentProofTest extends TestCase
{
    use CreatesApiContext, RefreshDatabase;

    private const PNG_BYTES = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Wl2nWQAAAAASUVORK5CYII=';

    protected function setUp(): void
    {
        parent::setUp();
        $this->createApiContext();
        Storage::fake('local');
    }

    public function test_cashier_uploads_optional_proof_and_it_is_audited(): void
    {
        $cashier = $this->makeUser('kasir@rujak.test', 'kasir');
        $payment = $this->makePayment(SalePayment::METHOD_QRIS, $cashier);
        Sanctum::actingAs($cashier, ['api']);

        $this->post('/api/v1/payments/'.$payment->uuid.'/proof', [
            'proof' => $this->pngUpload('proof.png'),
        ], $this->headers($cashier))
            ->assertCreated()
            ->assertJsonPath('data.has_proof', true);

        $payment->refresh();
        $this->assertNotNull($payment->proof_path);
        $this->assertStringStartsWith(
            'payment-proofs/'.$this->business->id.'/'.$this->outlet->id.'/'.$payment->sale->uuid.'/',
            $payment->proof_path,
        );
        Storage::disk('local')->assertExists($payment->proof_path);
        $this->assertSame($cashier->id, $payment->proof_uploaded_by);

        $this->assertSame(1, AuditLog::query()->where('action', 'payment.proof_uploaded')->count());
        $this->assertArrayNotHasKey('proof_path', $payment->toArray());
        $this->assertTrue($payment->toArray()['has_proof']);
    }

    public function test_replacing_proof_deletes_previous_file(): void
    {
        $cashier = $this->makeUser('kasir@rujak.test', 'kasir');
        $payment = $this->makePayment(SalePayment::METHOD_TRANSFER, $cashier);
        Sanctum::actingAs($cashier, ['api']);

        $oldPath = 'payment-proofs/'.$this->business->id.'/'.$this->outlet->id.'/'
            .$payment->sale->uuid.'/'.$payment->uuid.'.jpg';
        Storage::disk('local')->put($oldPath, 'legacy-proof');
        $payment->forceFill(['proof_path' => $oldPath])->save();

        $this->post('/api/v1/payments/'.$payment->uuid.'/proof', [
            'proof' => $this->pngUpload('proof.png'),
        ], $this->headers($cashier))
            ->assertOk()
            ->assertJsonPath('data.has_proof', true);

        $newPath = $payment->refresh()->proof_path;
        $this->assertNotSame($oldPath, $newPath);
        Storage::disk('local')->assertMissing($oldPath);
        Storage::disk('local')->assertExists($newPath);
    }

    public function test_identical_retry_is_idempotent_without_duplicate_audit(): void
    {
        $cashier = $this->makeUser('kasir@rujak.test', 'kasir');
        $payment = $this->makePayment(SalePayment::METHOD_QRIS, $cashier);
        Sanctum::actingAs($cashier, ['api']);

        $this->post('/api/v1/payments/'.$payment->uuid.'/proof', [
            'proof' => $this->pngUpload(),
        ], $this->headers($cashier))->assertCreated();

        $this->post('/api/v1/payments/'.$payment->uuid.'/proof', [
            'proof' => $this->pngUpload(),
        ], $this->headers($cashier))->assertOk();

        $this->assertSame(1, AuditLog::query()->where('action', 'payment.proof_uploaded')->count());
    }

    public function test_proof_is_rejected_for_cash_payment(): void
    {
        $cashier = $this->makeUser('kasir@rujak.test', 'kasir');
        $payment = $this->makePayment(SalePayment::METHOD_CASH, $cashier);
        Sanctum::actingAs($cashier, ['api']);

        $this->post('/api/v1/payments/'.$payment->uuid.'/proof', [
            'proof' => $this->pngUpload(),
        ], $this->headers($cashier))->assertStatus(422);

        $this->assertNull($payment->refresh()->proof_path);
    }

    public function test_non_image_upload_is_rejected(): void
    {
        $cashier = $this->makeUser('kasir@rujak.test', 'kasir');
        $payment = $this->makePayment(SalePayment::METHOD_EWALLET, $cashier);
        Sanctum::actingAs($cashier, ['api']);

        $this->post('/api/v1/payments/'.$payment->uuid.'/proof', [
            'proof' => UploadedFile::fake()->create('proof.pdf', 10, 'application/pdf'),
        ], $this->headers($cashier))
            ->assertStatus(422)
            ->assertJsonPath('error.code', 'VALIDATION_FAILED');
    }

    public function test_only_verifiers_can_fetch_proof(): void
    {
        $cashier = $this->makeUser('kasir@rujak.test', 'kasir');
        $supervisor = $this->makeUser('supervisor@rujak.test', 'supervisor', 'supervisor');
        $payment = $this->makePayment(SalePayment::METHOD_QRIS, $cashier);
        $this->attachProof($payment);

        Sanctum::actingAs($cashier, ['api']);
        $this->get('/api/v1/payments/'.$payment->uuid.'/proof', $this->headers($cashier))
            ->assertForbidden();

        Sanctum::actingAs($supervisor, ['api']);
        $response = $this->get('/api/v1/payments/'.$payment->uuid.'/proof', $this->headers($supervisor));
        $response->assertOk()->assertHeader('content-type', 'image/png');
        $this->assertSame(base64_decode(self::PNG_BYTES), $response->streamedContent());
    }

    public function test_fetch_without_proof_returns_not_found(): void
    {
        $cashier = $this->makeUser('kasir@rujak.test', 'kasir');
        $supervisor = $this->makeUser('supervisor@rujak.test', 'supervisor', 'supervisor');
        $payment = $this->makePayment(SalePayment::METHOD_QRIS, $cashier);

        Sanctum::actingAs($supervisor, ['api']);
        $this->get('/api/v1/payments/'.$payment->uuid.'/proof', $this->headers($supervisor))
            ->assertNotFound();
    }

    public function test_cross_tenant_and_cross_outlet_proof_access_is_not_found(): void
    {
        $cashier = $this->makeUser('kasir@rujak.test', 'kasir');
        $payment = $this->makePayment(SalePayment::METHOD_QRIS, $cashier);
        $this->attachProof($payment);

        [, , $otherUser, $otherDevice] = $this->makeTenant('lain');
        Sanctum::actingAs($otherUser, ['api']);
        $this->get('/api/v1/payments/'.$payment->uuid.'/proof', $this->headers($otherUser, $otherDevice))
            ->assertNotFound();

        $otherOutlet = Outlet::create([
            'uuid' => (string) Str::uuid(),
            'business_id' => $this->business->id,
            'name' => 'Cabang',
            'code' => 'CBG',
            'is_active' => true,
        ]);
        $outletUser = $this->makeUser('cabang@rujak.test', 'cabang', 'owner');
        $outletUser->forceFill(['outlet_id' => $otherOutlet->id])->save();
        $outletDevice = $this->makeDevice('T02', $otherOutlet->id);

        Sanctum::actingAs($outletUser, ['api']);
        $this->get('/api/v1/payments/'.$payment->uuid.'/proof', $this->headers($outletUser, $outletDevice))
            ->assertNotFound();
    }

    private function makePayment(string $method, User $recordedBy): SalePayment
    {
        $sale = Sale::create([
            'business_id' => $this->business->id,
            'outlet_id' => $this->outlet->id,
            'shift_id' => $this->openShift($recordedBy)->id,
            'user_id' => $recordedBy->id,
            'device_id' => $this->device->id,
            'receipt_number' => 'RJS-PUSAT-T01-'.str_pad((string) random_int(1, 9999999999), 10, '0', STR_PAD_LEFT),
            'order_type' => 'dine_in',
            'lifecycle_status' => Sale::LIFECYCLE_FINALIZED,
            'payment_status' => $method === SalePayment::METHOD_CASH ? Sale::PAYMENT_PAID : Sale::PAYMENT_AWAITING_VERIFICATION,
            'subtotal' => 10000,
            'total' => 10000,
            'confirmed_amount' => $method === SalePayment::METHOD_CASH ? 10000 : 0,
            'awaiting_verification_amount' => $method === SalePayment::METHOD_CASH ? 0 : 10000,
            'outstanding_amount' => $method === SalePayment::METHOD_CASH ? 0 : 10000,
            'transacted_at' => now(),
        ]);

        return $sale->payments()->create([
            'uuid' => (string) Str::uuid(),
            'method' => $method,
            'amount' => 10000,
            'status' => $method === SalePayment::METHOD_CASH
                ? SalePayment::STATUS_CONFIRMED
                : SalePayment::STATUS_AWAITING_VERIFICATION,
            'provider_reference' => $method === SalePayment::METHOD_CASH ? null : 'REF-123',
            'origin' => 'online',
            'recorded_by' => $recordedBy->id,
            'recorded_at' => now(),
        ]);
    }

    private function attachProof(SalePayment $payment): void
    {
        $path = 'payment-proofs/'.$this->business->id.'/'.$this->outlet->id.'/'
            .$payment->sale->uuid.'/'.$payment->uuid.'.png';
        Storage::disk('local')->put($path, base64_decode(self::PNG_BYTES));
        $payment->forceFill(['proof_path' => $path, 'proof_uploaded_at' => now()])->save();
    }

    private function pngUpload(string $name = 'proof.png'): UploadedFile
    {
        $path = tempnam(sys_get_temp_dir(), 'proof').'.png';
        file_put_contents($path, base64_decode(self::PNG_BYTES));

        return new UploadedFile($path, $name, 'image/png', null, true);
    }
}
