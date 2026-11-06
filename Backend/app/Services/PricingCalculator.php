<?php

namespace App\Services;

use App\Exceptions\ApiException;

/**
 * Deterministic integer-rupiah pricing shared by order preview, checkout and
 * offline event validation. No monetary value is ever stored as float.
 */
class PricingCalculator
{
    public function calculate(array $items, array $config, int $transactionDiscount = 0): array
    {
        if ($items === []) {
            throw new ApiException('ORDER_EMPTY', 'Order harus memiliki minimal satu item.', 422);
        }

        $serviceEnabled = (bool) ($config['service_charge_enabled'] ?? false);
        $serviceRate = max(0, (int) ($config['service_charge_rate_basis_points'] ?? 0));
        $taxEnabled = (bool) ($config['tax_enabled'] ?? false);
        $defaultTaxRate = max(0, (int) ($config['tax_rate_basis_points'] ?? 0));
        $taxIncludesService = (bool) ($config['tax_includes_service_charge'] ?? false);

        $lines = [];
        $subtotal = 0;
        $itemDiscountTotal = 0;

        foreach ($items as $index => $item) {
            $unitPrice = (int) ($item['unit_price'] ?? 0);
            $quantity = (int) ($item['quantity'] ?? 0);
            $itemDiscount = max(0, (int) ($item['item_discount'] ?? 0));
            $taxRate = $taxEnabled
                ? max(0, (int) ($item['tax_rate_basis_points'] ?? $defaultTaxRate))
                : 0;

            if ($unitPrice < 0) {
                throw new ApiException('PRICE_INVALID', "Harga item #{$index} tidak valid.", 422);
            }
            if ($quantity < 1 || $quantity > 100) {
                throw new ApiException('QUANTITY_INVALID', "Kuantitas item #{$index} harus antara 1 dan 100.", 422);
            }

            $gross = $unitPrice * $quantity;
            if ($itemDiscount > $gross) {
                throw new ApiException('ITEM_DISCOUNT_EXCEEDS_LINE', 'Diskon item tidak boleh melebihi nilai baris.', 422);
            }

            $subtotal += $gross;
            $itemDiscountTotal += $itemDiscount;
            $lines[] = [
                'index' => $index,
                'unit_price' => $unitPrice,
                'quantity' => $quantity,
                'gross' => $gross,
                'item_discount' => $itemDiscount,
                'after_item_discount' => $gross - $itemDiscount,
                'tax_rate_basis_points' => $taxRate,
            ];
        }

        $netAfterItemDiscount = $subtotal - $itemDiscountTotal;
        if ($transactionDiscount < 0) {
            throw new ApiException('TRANSACTION_DISCOUNT_INVALID', 'Diskon transaksi tidak valid.', 422);
        }
        if ($transactionDiscount > $netAfterItemDiscount) {
            throw new ApiException('DISCOUNT_EXCEEDS_SUBTOTAL', 'Diskon transaksi melebihi subtotal setelah diskon item.', 422);
        }

        $transactionAllocations = $this->allocate(
            $transactionDiscount,
            array_map(fn ($line) => $line['after_item_discount'], $lines),
        );

        $netSubtotal = $netAfterItemDiscount - $transactionDiscount;
        $serviceTotal = $serviceEnabled ? $this->applyRate($netSubtotal, $serviceRate) : 0;

        $serviceWeights = [];
        foreach ($lines as $i => $line) {
            $serviceWeights[] = $line['after_item_discount'] - $transactionAllocations[$i];
        }
        $serviceAllocations = $this->allocate($serviceTotal, $serviceWeights);

        $taxTotal = 0;
        $resultLines = [];
        foreach ($lines as $i => $line) {
            $lineNet = $line['after_item_discount'] - $transactionAllocations[$i];
            $lineService = $serviceAllocations[$i];
            $taxableBase = $lineNet + ($taxIncludesService ? $lineService : 0);
            $lineTax = $line['tax_rate_basis_points'] > 0
                ? $this->applyRate($taxableBase, $line['tax_rate_basis_points'])
                : 0;

            $taxTotal += $lineTax;
            $resultLines[] = [
                ...$line,
                'transaction_discount_allocation' => $transactionAllocations[$i],
                'discount_amount' => $line['item_discount'] + $transactionAllocations[$i],
                'service_charge_amount' => $lineService,
                'taxable_base' => $taxableBase,
                'tax_amount' => $lineTax,
                'line_net' => $lineNet,
                'total' => $lineNet + $lineService + $lineTax,
            ];
        }

        return [
            'subtotal' => $subtotal,
            'item_discount_total' => $itemDiscountTotal,
            'transaction_discount_total' => $transactionDiscount,
            'discount_total' => $itemDiscountTotal + $transactionDiscount,
            'net_subtotal' => $netSubtotal,
            'service_charge' => $serviceTotal,
            'tax_total' => $taxTotal,
            'total' => $netSubtotal + $serviceTotal + $taxTotal,
            'lines' => $resultLines,
            'config' => [
                'tax_enabled' => $taxEnabled,
                'tax_rate_basis_points' => $defaultTaxRate,
                'service_charge_enabled' => $serviceEnabled,
                'service_charge_rate_basis_points' => $serviceRate,
                'tax_includes_service_charge' => $taxIncludesService,
                'rounding' => 'half_up_to_rupiah',
                'transaction_discount_allocation' => 'proportional_largest_remainder',
            ],
        ];
    }

    /**
     * Allocate an integer amount proportionally using the largest remainder
     * method, so the sum of allocations always equals the amount exactly.
     */
    private function allocate(int $amount, array $weights): array
    {
        $count = count($weights);
        $result = array_fill(0, $count, 0);

        if ($amount === 0 || $count === 0) {
            return $result;
        }

        $totalWeight = array_sum($weights);
        if ($totalWeight <= 0) {
            return $result;
        }

        $remainders = [];
        $allocated = 0;
        foreach ($weights as $i => $weight) {
            $numerator = $amount * max(0, $weight);
            $result[$i] = intdiv($numerator, $totalWeight);
            $remainders[$i] = $numerator % $totalWeight;
            $allocated += $result[$i];
        }

        $remaining = $amount - $allocated;
        arsort($remainders, SORT_NUMERIC);
        foreach (array_keys($remainders) as $index) {
            if ($remaining <= 0) {
                break;
            }
            $result[$index]++;
            $remaining--;
        }

        return $result;
    }

    private function applyRate(int $base, int $basisPoints): int
    {
        return intdiv(($base * $basisPoints) + 5000, 10000);
    }
}
