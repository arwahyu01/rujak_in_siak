import 'package:flutter_test/flutter_test.dart';
import 'package:rujak_pos/core/errors/app_exception.dart';
import 'package:rujak_pos/core/pricing/pricing_calculator.dart';
import 'package:rujak_pos/data/models/sale.dart';

void main() {
  const calculator = PricingCalculator();

  group('PricingCalculator', () {
    test('sums lines without tax or service charge', () {
      final result = calculator.calculate(
        items: const [
          PricingLineInput(unitPrice: 15000, quantity: 2),
          PricingLineInput(unitPrice: 8000, quantity: 1),
        ],
        config: const PricingConfig(),
      );

      expect(result.subtotal, 38000);
      expect(result.discountTotal, 0);
      expect(result.serviceCharge, 0);
      expect(result.taxTotal, 0);
      expect(result.total, 38000);
      expect(result.lines.map((line) => line.lineNet), [30000, 8000]);
    });

    test('allocates discounts, service charge and tax per line', () {
      final result = calculator.calculate(
        items: const [
          PricingLineInput(unitPrice: 15000, quantity: 2, itemDiscount: 2000),
          PricingLineInput(unitPrice: 8000, quantity: 1),
        ],
        config: const PricingConfig(
          taxEnabled: true,
          taxRateBasisPoints: 1000,
          serviceChargeEnabled: true,
          serviceChargeRateBasisPoints: 500,
        ),
        transactionDiscount: 3000,
      );

      expect(result.subtotal, 38000);
      expect(result.itemDiscountTotal, 2000);
      expect(result.transactionDiscountTotal, 3000);
      expect(result.netSubtotal, 33000);
      expect(result.serviceCharge, 1650);
      expect(result.taxTotal, 3300);
      expect(result.total, 37950);
      expect(
        result.lines.map((line) => line.total).reduce((a, b) => a + b),
        result.total,
      );
    });

    test('breaks allocation ties by line order like the backend', () {
      final result = calculator.calculate(
        items: const [
          PricingLineInput(unitPrice: 1000, quantity: 1),
          PricingLineInput(unitPrice: 1000, quantity: 1),
          PricingLineInput(unitPrice: 1000, quantity: 1),
        ],
        config: const PricingConfig(),
        transactionDiscount: 1,
      );

      expect(result.lines.map((line) => line.transactionDiscountAllocation), [
        1,
        0,
        0,
      ]);
    });

    test('rejects a transaction discount above the net subtotal', () {
      expect(
        () => calculator.calculate(
          items: const [PricingLineInput(unitPrice: 10000, quantity: 1)],
          config: const PricingConfig(),
          transactionDiscount: 10001,
        ),
        throwsA(
          isA<AppException>().having(
            (error) => error.code,
            'code',
            'DISCOUNT_EXCEEDS_SUBTOTAL',
          ),
        ),
      );
    });
  });

  group('LocalPaymentDraft', () {
    test('cash is confirmed immediately and includes change', () {
      const draft = LocalPaymentDraft(
        method: 'cash',
        amount: 20000,
        tenderedAmount: 50000,
      );

      expect(draft.status, 'confirmed');
      expect(draft.changeAmount, 30000);
      final json = draft.toCheckoutJson('key');
      expect(json['tendered_amount'], 50000);
      expect(json['method'], 'cash');
    });

    test('non-cash waits for verification and sends the reference', () {
      const draft = LocalPaymentDraft(
        method: 'qris',
        amount: 20000,
        providerReference: 'QR-REF-1',
      );

      expect(draft.status, 'awaiting_verification');
      expect(draft.changeAmount, 0);
      final json = draft.toCheckoutJson('key');
      expect(json['provider_reference'], 'QR-REF-1');
      expect(json.containsKey('tendered_amount'), isFalse);
    });
  });
}
