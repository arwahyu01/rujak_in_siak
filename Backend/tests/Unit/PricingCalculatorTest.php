<?php

namespace Tests\Unit;

use App\Exceptions\ApiException;
use App\Services\PricingCalculator;
use PHPUnit\Framework\TestCase;

class PricingCalculatorTest extends TestCase
{
    private const CONFIG = [
        'tax_enabled' => true,
        'tax_rate_basis_points' => 1000,
        'service_charge_enabled' => true,
        'service_charge_rate_basis_points' => 500,
        'tax_includes_service_charge' => false,
    ];

    public function test_it_calculates_integer_totals_with_proportional_discounts(): void
    {
        $result = (new PricingCalculator)->calculate([
            [
                'unit_price' => 10000,
                'quantity' => 2,
                'item_discount' => 1000,
                'tax_rate_basis_points' => 1000,
            ],
        ], self::CONFIG, 500);

        $this->assertSame(20000, $result['subtotal']);
        $this->assertSame(1000, $result['item_discount_total']);
        $this->assertSame(500, $result['transaction_discount_total']);
        $this->assertSame(18500, $result['net_subtotal']);
        $this->assertSame(925, $result['service_charge']);
        $this->assertSame(1850, $result['tax_total']);
        $this->assertSame(21275, $result['total']);
        $this->assertSame(21275, $result['lines'][0]['total']);
    }

    public function test_discount_allocation_is_exact_largest_remainder(): void
    {
        $result = (new PricingCalculator)->calculate([
            ['unit_price' => 3333, 'quantity' => 1, 'tax_rate_basis_points' => 0],
            ['unit_price' => 3333, 'quantity' => 1, 'tax_rate_basis_points' => 0],
            ['unit_price' => 3334, 'quantity' => 1, 'tax_rate_basis_points' => 0],
        ], [
            'tax_enabled' => false,
            'service_charge_enabled' => false,
        ], 100);

        $allocated = array_sum(array_column($result['lines'], 'transaction_discount_allocation'));

        $this->assertSame(100, $allocated);
        $this->assertSame(10000 - 100, $result['total']);
    }

    public function test_it_rounds_half_up_to_rupiah(): void
    {
        $result = (new PricingCalculator)->calculate([
            ['unit_price' => 5, 'quantity' => 1, 'tax_rate_basis_points' => 1000],
        ], [
            'tax_enabled' => true,
            'tax_rate_basis_points' => 1000,
            'service_charge_enabled' => false,
        ]);

        // 5 * 10% = 0.5 rupiah, half-up to 1.
        $this->assertSame(1, $result['tax_total']);
        $this->assertSame(6, $result['total']);
    }

    public function test_transaction_discount_cannot_exceed_net_subtotal(): void
    {
        $this->expectException(ApiException::class);
        $this->expectExceptionMessage('Diskon transaksi melebihi subtotal');

        (new PricingCalculator)->calculate([
            ['unit_price' => 1000, 'quantity' => 1, 'tax_rate_basis_points' => 0],
        ], [
            'tax_enabled' => false,
            'service_charge_enabled' => false,
        ], 1001);
    }

    public function test_tax_includes_service_charge_when_configured(): void
    {
        $result = (new PricingCalculator)->calculate([
            ['unit_price' => 10000, 'quantity' => 1, 'tax_rate_basis_points' => 1000],
        ], [
            'tax_enabled' => true,
            'tax_rate_basis_points' => 1000,
            'service_charge_enabled' => true,
            'service_charge_rate_basis_points' => 1000,
            'tax_includes_service_charge' => true,
        ]);

        $this->assertSame(1000, $result['service_charge']);
        $this->assertSame(1100, $result['tax_total']);
        $this->assertSame(12100, $result['total']);
    }
}
