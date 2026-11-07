import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rujak_pos/core/pricing/pricing_calculator.dart';
import 'package:rujak_pos/core/theme/app_theme.dart';
import 'package:rujak_pos/features/pos/presentation/cart_panel.dart';
import 'package:rujak_pos/features/pos/state/cart_controller.dart';

void main() {
  testWidgets('cart panel fits inside a short viewport without overflowing', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container
        .read(cartProvider.notifier)
        .addLine(
          productUuid: 'p1',
          productName: 'Rujak Cingur',
          unitPrice: 25000,
          taxRateBasisPoints: 0,
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.build(),
          home: Scaffold(
            body: SizedBox(
              width: 380,
              height: 300,
              child: CartPanel(
                config: const PricingConfig(),
                onCheckout: () {},
                onHold: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Pesanan'), findsOneWidget);
  });

  testWidgets('cart panel clamps oversized discounts instead of crashing', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(cartProvider.notifier);
    notifier.addLine(
      productUuid: 'p1',
      productName: 'Rujak Cingur',
      unitPrice: 25000,
    );
    final lineId = container.read(cartProvider).lines.single.id;
    notifier.setLineDiscount(lineId, 999999);
    notifier.setTransactionDiscount(999999);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.build(),
          home: Scaffold(
            body: SizedBox(
              width: 380,
              height: 600,
              child: CartPanel(
                config: const PricingConfig(),
                onCheckout: () {},
                onHold: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Pesanan'), findsOneWidget);
    expect(find.text('Perhitungan keranjang tidak valid'), findsNothing);
    expect(find.text('Rp0'), findsWidgets);
  });

  testWidgets('editing a line closes without reusing disposed controllers', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container
        .read(cartProvider.notifier)
        .addLine(
          productUuid: 'p1',
          productName: 'Rujak Cingur',
          unitPrice: 25000,
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.build(),
          home: Scaffold(
            body: SizedBox(
              width: 380,
              height: 600,
              child: CartPanel(
                config: const PricingConfig(),
                onCheckout: () {},
                onHold: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ubah item'));
    await tester.pumpAndSettle();
    expect(find.text('Simpan'), findsOneWidget);

    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Simpan'), findsNothing);
    expect(find.text('Rujak Cingur'), findsOneWidget);
  });

  testWidgets('discount dialog closes without reusing disposed controllers', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container
        .read(cartProvider.notifier)
        .addLine(
          productUuid: 'p1',
          productName: 'Rujak Cingur',
          unitPrice: 25000,
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.build(),
          home: Scaffold(
            body: SizedBox(
              width: 380,
              height: 600,
              child: CartPanel(
                config: const PricingConfig(),
                onCheckout: () {},
                onHold: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Atur'));
    await tester.pumpAndSettle();
    expect(find.text('Diskon transaksi'), findsOneWidget);

    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Diskon transaksi'), findsNothing);
  });
}
