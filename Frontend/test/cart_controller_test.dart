import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rujak_pos/core/pricing/pricing_calculator.dart';
import 'package:rujak_pos/features/pos/state/cart_controller.dart';

void main() {
  late ProviderContainer container;
  late CartController notifier;

  setUp(() {
    container = ProviderContainer();
    notifier = container.read(cartProvider.notifier);
  });

  tearDown(() => container.dispose());

  group('discount guards', () {
    test('clamps item discount to the line gross', () {
      notifier.addLine(
        productUuid: 'p1',
        productName: 'Rujak Cingur',
        unitPrice: 25000,
      );
      final lineId = container.read(cartProvider).lines.single.id;

      notifier.setLineDiscount(lineId, 50000);

      final state = container.read(cartProvider);
      expect(state.lines.single.itemDiscount, 25000);
      final pricing = state.calculate(const PricingConfig());
      expect(pricing, isNotNull);
      expect(pricing!.total, 0);
    });

    test('clamps item discount when quantity is decreased', () {
      notifier.addLine(
        productUuid: 'p1',
        productName: 'Rujak Cingur',
        unitPrice: 25000,
        quantity: 2,
      );
      final lineId = container.read(cartProvider).lines.single.id;
      notifier.setLineDiscount(lineId, 50000);

      notifier.decrement(lineId);

      final state = container.read(cartProvider);
      expect(state.lines.single.quantity, 1);
      expect(state.lines.single.itemDiscount, 25000);
      expect(state.calculate(const PricingConfig())!.total, 0);
    });

    test('clamps transaction discount to the net subtotal', () {
      notifier.addLine(
        productUuid: 'p1',
        productName: 'Rujak Cingur',
        unitPrice: 25000,
      );

      notifier.setTransactionDiscount(999999);

      final state = container.read(cartProvider);
      expect(state.transactionDiscount, 25000);
      expect(state.calculate(const PricingConfig())!.total, 0);
    });

    test('removing the last line clears the stale transaction discount', () {
      notifier.addLine(
        productUuid: 'p1',
        productName: 'Rujak Cingur',
        unitPrice: 25000,
      );
      final lineId = container.read(cartProvider).lines.single.id;
      notifier.setTransactionDiscount(10000);

      notifier.removeLine(lineId);

      final state = container.read(cartProvider);
      expect(state.isEmpty, isTrue);
      expect(state.transactionDiscount, 0);
      expect(state.calculate(const PricingConfig()), isNull);
    });

    test('removing a line re-clamps the transaction discount', () {
      notifier.addLine(
        productUuid: 'p1',
        productName: 'Rujak Cingur',
        unitPrice: 25000,
      );
      notifier.addLine(
        productUuid: 'p2',
        productName: 'Es Teh',
        unitPrice: 10000,
      );
      notifier.setTransactionDiscount(35000);
      final teaId = container
          .read(cartProvider)
          .lines
          .firstWhere((line) => line.productUuid == 'p2')
          .id;

      notifier.removeLine(teaId);

      final state = container.read(cartProvider);
      expect(state.transactionDiscount, 25000);
      expect(state.calculate(const PricingConfig())!.total, 0);
    });

    test('restore normalizes discounts from persisted legacy data', () {
      notifier.restore(
        const CartState(
          lines: [
            CartLine(
              id: 'l1',
              productUuid: 'p1',
              productName: 'Rujak Cingur',
              unitPrice: 10000,
              quantity: 1,
              itemDiscount: 20000,
            ),
          ],
          transactionDiscount: 50000,
        ),
      );

      final state = container.read(cartProvider);
      expect(state.lines.single.itemDiscount, 10000);
      expect(state.transactionDiscount, 0);
      expect(state.calculate(const PricingConfig())!.total, 0);
    });
  });

  group('server order link', () {
    test('keeps the link while the cart is untouched', () {
      notifier.addLine(
        productUuid: 'p1',
        productName: 'Rujak Cingur',
        unitPrice: 25000,
      );
      notifier.linkServerOrder(uuid: 'order-1', version: 3);

      final state = container.read(cartProvider);
      expect(state.serverOrderUuid, 'order-1');
      expect(state.serverOrderVersion, 3);
    });

    test('is cleared when the cart lines change', () {
      notifier.addLine(
        productUuid: 'p1',
        productName: 'Rujak Cingur',
        unitPrice: 25000,
      );
      final lineId = container.read(cartProvider).lines.single.id;
      notifier.linkServerOrder(uuid: 'order-1', version: 3);

      notifier.increment(lineId);

      expect(container.read(cartProvider).serverOrderUuid, isNull);
      expect(container.read(cartProvider).serverOrderVersion, isNull);
    });

    test('is cleared when order metadata changes', () {
      notifier.addLine(
        productUuid: 'p1',
        productName: 'Rujak Cingur',
        unitPrice: 25000,
      );
      notifier.linkServerOrder(uuid: 'order-1', version: 3);

      notifier.setTableNumber('A1');

      expect(container.read(cartProvider).serverOrderUuid, isNull);
    });

    test('is cleared when the transaction discount changes', () {
      notifier.addLine(
        productUuid: 'p1',
        productName: 'Rujak Cingur',
        unitPrice: 25000,
      );
      notifier.linkServerOrder(uuid: 'order-1', version: 3);

      notifier.setTransactionDiscount(5000);

      expect(container.read(cartProvider).serverOrderUuid, isNull);
    });
  });

  group('insertLine', () {
    test('restores a removed line at its original position', () {
      notifier.addLine(
        productUuid: 'p1',
        productName: 'Rujak Cingur',
        unitPrice: 25000,
      );
      notifier.addLine(
        productUuid: 'p2',
        productName: 'Es Teh',
        unitPrice: 10000,
      );
      final removed = container.read(cartProvider).lines.first;
      notifier.removeLine(removed.id);

      notifier.insertLine(0, removed);

      final lines = container.read(cartProvider).lines;
      expect(lines, hasLength(2));
      expect(lines.first.id, removed.id);
      expect(lines.last.productUuid, 'p2');
    });
  });

  group('line notes', () {
    test(
      'keeps lines with different notes separate and targets the right line',
      () {
        notifier.addLine(
          productUuid: 'a',
          productName: 'Rujak A',
          unitPrice: 10000,
          notes: 'tanpa kacang',
        );
        notifier.addLine(
          productUuid: 'b',
          productName: 'Es Teh',
          unitPrice: 5000,
        );
        notifier.addLine(
          productUuid: 'a',
          productName: 'Rujak A',
          unitPrice: 10000,
          notes: 'pedas',
        );
        notifier.addLine(
          productUuid: 'a',
          productName: 'Rujak A',
          unitPrice: 10000,
          notes: '  tanpa kacang  ',
        );

        final lines = container.read(cartProvider).lines;
        expect(lines.length, 3);
        expect(
          lines.firstWhere((line) => line.notes == 'tanpa kacang').quantity,
          2,
        );
        expect(lines.firstWhere((line) => line.notes == 'pedas').quantity, 1);
        expect(
          lines.firstWhere((line) => line.productUuid == 'b').notes,
          isNull,
        );
      },
    );

    test('setLineNotes keeps the target line unchanged on other lines', () {
      notifier.addLine(
        productUuid: 'a',
        productName: 'Rujak A',
        unitPrice: 10000,
      );
      notifier.addLine(
        productUuid: 'b',
        productName: 'Es Teh',
        unitPrice: 5000,
      );
      final lines = container.read(cartProvider).lines;
      final tea = lines.firstWhere((line) => line.productUuid == 'b');

      notifier.setLineNotes(tea.id, ' sedikit gula ');

      final updated = container.read(cartProvider).lines;
      expect(
        updated.firstWhere((line) => line.productUuid == 'b').notes,
        'sedikit gula',
      );
      expect(
        updated.firstWhere((line) => line.productUuid == 'a').notes,
        isNull,
      );
    });
  });
}
