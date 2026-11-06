<?php

namespace Tests\Feature;

use App\Models\SalePayment;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\CreatesApiContext;
use Tests\TestCase;

class ApiReportTest extends TestCase
{
    use CreatesApiContext;
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->createApiContext();
        Sanctum::actingAs($this->owner, ['api']);
        $this->openShift($this->owner);
    }

    public function test_sales_report_reflects_finalized_transactions_only(): void
    {
        $this->checkoutCashSale(15000);

        $today = now()->toDateString();
        $response = $this->getJson(
            '/api/v1/reports/sales?date_from='.$today.'&date_to='.$today,
            $this->headers($this->owner),
        )->assertOk();

        $response->assertJsonPath('data.summary.transactions', 1)
            ->assertJsonPath('data.summary.total', 15000)
            ->assertJsonPath('data.summary.voided_transactions', 0)
            ->assertJsonPath('data.daily.0.date', $today)
            ->assertJsonPath('data.daily.0.transactions', 1)
            ->assertJsonPath('meta.period.timezone', 'Asia/Jakarta');

        $this->assertSame($this->owner->name, $response->json('data.by_cashier.0.name'));

        $this->checkoutVoidedSale(10000);

        $afterVoid = $this->getJson(
            '/api/v1/reports/sales?date_from='.$today.'&date_to='.$today,
            $this->headers($this->owner),
        )->assertOk();

        $afterVoid->assertJsonPath('data.summary.transactions', 1)
            ->assertJsonPath('data.summary.total', 15000)
            ->assertJsonPath('data.summary.voided_transactions', 1)
            ->assertJsonPath('data.summary.voided_total', 10000);
    }

    public function test_reports_filter_by_business_timezone_and_validate_period(): void
    {
        $this->checkoutCashSale(15000);

        $yesterday = now()->subDay()->toDateString();
        $response = $this->getJson(
            '/api/v1/reports/sales?date_from='.$yesterday.'&date_to='.$yesterday,
            $this->headers($this->owner),
        )->assertOk();

        $response->assertJsonPath('data.summary.transactions', 0)
            ->assertJsonPath('data.daily', []);

        $this->getJson(
            '/api/v1/reports/sales?date_from='.now()->toDateString().'&date_to='.$yesterday,
            $this->headers($this->owner),
        )->assertStatus(422)->assertJsonPath('error.code', 'REPORT_PERIOD_INVALID');

        $this->getJson(
            '/api/v1/reports/sales?date_from=bukan-tanggal&date_to='.now()->toDateString(),
            $this->headers($this->owner),
        )->assertStatus(422)->assertJsonPath('error.code', 'REPORT_DATE_INVALID');
    }

    public function test_payment_and_product_reports_use_real_transaction_data(): void
    {
        $this->checkoutCashSale(15000);

        $today = now()->toDateString();
        $payments = $this->getJson(
            '/api/v1/reports/payments?date_from='.$today.'&date_to='.$today,
            $this->headers($this->owner),
        )->assertOk();

        $payments->assertJsonPath('data.by_method.0.method', SalePayment::METHOD_CASH)
            ->assertJsonPath('data.by_method.0.recorded', 15000)
            ->assertJsonPath('data.by_method.0.confirmed', 15000)
            ->assertJsonPath('data.by_status.0.status', SalePayment::STATUS_CONFIRMED);

        $products = $this->getJson(
            '/api/v1/reports/products?date_from='.$today.'&date_to='.$today,
            $this->headers($this->owner),
        )->assertOk();

        $products->assertJsonPath('data.summary.products_sold', 1)
            ->assertJsonPath('data.summary.revenue', 15000);

        $shifts = $this->getJson(
            '/api/v1/reports/shifts?date_from='.$today.'&date_to='.$today,
            $this->headers($this->owner),
        )->assertOk();

        $this->assertSame(1, $shifts->json('data.summary.shifts'));
    }

    public function test_reports_are_tenant_isolated(): void
    {
        $this->checkoutCashSale(15000);

        [, , $otherUser, $otherDevice] = $this->makeTenant('tenantf');

        Sanctum::actingAs($otherUser, ['api']);

        $this->postJson('/api/v1/shifts/open', [
            'opening_cash' => 0,
        ], $this->headers($otherUser, $otherDevice))->assertCreated();

        $otherProduct = $this->postJson('/api/v1/products', [
            'name' => 'Produk Tenant F',
            'sku' => 'TENANTF-1',
            'price' => 25000,
        ], $this->headers($otherUser, $otherDevice))->assertCreated();

        $otherOrder = $this->postJson('/api/v1/orders', [
            'items' => [['product_uuid' => $otherProduct->json('data.uuid'), 'quantity' => 2]],
        ], $this->headers($otherUser, $otherDevice))->assertCreated();

        $this->postJson('/api/v1/sales/checkout', [
            'order_uuid' => $otherOrder->json('data.uuid'),
            'base_version' => 1,
            'payments' => [[
                'method' => SalePayment::METHOD_CASH,
                'amount' => 50000,
                'tendered_amount' => 50000,
            ]],
        ], $this->headers($otherUser, $otherDevice))->assertCreated();

        $today = now()->toDateString();

        $otherReport = $this->getJson(
            '/api/v1/reports/sales?date_from='.$today.'&date_to='.$today,
            $this->headers($otherUser, $otherDevice),
        )->assertOk();
        $otherReport->assertJsonPath('data.summary.transactions', 1)
            ->assertJsonPath('data.summary.total', 50000);

        Sanctum::actingAs($this->owner, ['api']);

        $ownerReport = $this->getJson(
            '/api/v1/reports/sales?date_from='.$today.'&date_to='.$today,
            $this->headers($this->owner),
        )->assertOk();
        $ownerReport->assertJsonPath('data.summary.transactions', 1)
            ->assertJsonPath('data.summary.total', 15000);
    }

    private function checkoutCashSale(int $price): string
    {
        $product = $this->makeProduct($price);

        $orderUuid = $this->postJson('/api/v1/orders', [
            'items' => [['product_uuid' => $product->uuid, 'quantity' => 1]],
        ], $this->headers($this->owner))->assertCreated()->json('data.uuid');

        return $this->postJson('/api/v1/sales/checkout', [
            'order_uuid' => $orderUuid,
            'base_version' => 1,
            'payments' => [[
                'method' => SalePayment::METHOD_CASH,
                'amount' => $price,
                'tendered_amount' => $price,
            ]],
        ], $this->headers($this->owner))->assertCreated()->json('data.uuid');
    }

    private function checkoutVoidedSale(int $price): void
    {
        $product = $this->makeProduct($price);

        $orderUuid = $this->postJson('/api/v1/orders', [
            'items' => [['product_uuid' => $product->uuid, 'quantity' => 1]],
        ], $this->headers($this->owner))->assertCreated()->json('data.uuid');

        $saleUuid = $this->postJson('/api/v1/sales/checkout', [
            'order_uuid' => $orderUuid,
            'base_version' => 1,
        ], $this->headers($this->owner))->assertCreated()->json('data.uuid');

        $this->postJson('/api/v1/sales/'.$saleUuid.'/void', [
            'reason' => 'Salah input',
        ], $this->headers($this->owner))->assertOk();
    }
}
