import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rujak_pos/core/pricing/pricing_calculator.dart';
import 'package:rujak_pos/core/theme/app_theme.dart';
import 'package:rujak_pos/data/bootstrap/bootstrap_controller.dart';
import 'package:rujak_pos/data/models/auth.dart';
import 'package:rujak_pos/data/models/catalog.dart';
import 'package:rujak_pos/data/models/shift.dart';
import 'package:rujak_pos/data/repositories/bootstrap_repository.dart';
import 'package:rujak_pos/data/session/session_controller.dart';
import 'package:rujak_pos/data/shifts/shift_controller.dart';
import 'package:rujak_pos/features/checkout/presentation/checkout_screen.dart';
import 'package:rujak_pos/features/pos/state/cart_controller.dart';

void main() {
  testWidgets('zero-total checkout skips payment drafts', (tester) async {
    final snapshot = CatalogSnapshot(
      data: const BootstrapData(
        business: AppBusiness(uuid: 'business-1', name: 'Rujak In Siak'),
        outlet: AppOutlet(uuid: 'outlet-1', name: 'Outlet', code: 'OUT'),
        user: AppUser(uuid: 'user-1', name: 'Kasir'),
        categories: [],
        products: [],
        pricingConfig: PricingConfig(),
      ),
      catalogSyncedAt: DateTime(2026, 11, 7, 10),
      freshness: CatalogFreshness.fresh,
    );
    const session = AuthSession(
      token: 'token',
      sessionUuid: 'session-1',
      user: AppUser(uuid: 'user-1', name: 'Kasir'),
    );
    final shift = ShiftRecord(
      uuid: 'shift-1',
      status: 'open',
      openingCash: 0,
      openedAt: DateTime(2026, 11, 7, 8),
      synced: true,
    );

    final container = ProviderContainer(
      overrides: [
        bootstrapProvider.overrideWith(
          () => _FakeBootstrapController(BootstrapState(snapshot: snapshot)),
        ),
        sessionProvider.overrideWith(() => _FakeSessionController(session)),
        shiftProvider.overrideWith(
          () => _FakeShiftController(ShiftViewState(shift: shift)),
        ),
      ],
    );
    addTearDown(container.dispose);

    final cart = container.read(cartProvider.notifier);
    cart.addLine(
      productUuid: 'product-1',
      productName: 'Rujak Cingur',
      unitPrice: 25000,
    );
    cart.setTransactionDiscount(25000);
    expect(
      container.read(cartProvider).calculate(const PricingConfig())!.total,
      0,
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.build(),
          home: const CheckoutScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Selesaikan transaksi'), findsOneWidget);
    expect(find.text('Tambah pembayaran'), findsNothing);
    expect(
      find.textContaining('Tidak ada pembayaran yang perlu'),
      findsOneWidget,
    );

    await tester.tap(find.text('Selesaikan transaksi'));
    await tester.pumpAndSettle();

    expect(find.text('Konfirmasi transaksi'), findsOneWidget);
    expect(
      find.textContaining('Tidak ada pembayaran karena total transaksi Rp0.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Periksa lagi'));
    await tester.pumpAndSettle();
  });
}

class _FakeBootstrapController extends BootstrapController {
  _FakeBootstrapController(this._state);

  final BootstrapState _state;

  @override
  Future<BootstrapState> build() async => _state;
}

class _FakeSessionController extends SessionController {
  _FakeSessionController(this._session);

  final AuthSession? _session;

  @override
  Future<AuthSession?> build() async => _session;
}

class _FakeShiftController extends ShiftController {
  _FakeShiftController(this._state);

  final ShiftViewState _state;

  @override
  Future<ShiftViewState> build() async => _state;
}
