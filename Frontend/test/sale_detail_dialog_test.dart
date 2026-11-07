import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:rujak_pos/core/database/app_database.dart';
import 'package:rujak_pos/core/network/api_client.dart';
import 'package:rujak_pos/core/providers.dart';
import 'package:rujak_pos/core/theme/app_theme.dart';
import 'package:rujak_pos/data/models/auth.dart';
import 'package:rujak_pos/data/models/sale.dart';
import 'package:rujak_pos/data/repositories/sale_repository.dart';
import 'package:rujak_pos/data/services/payment_proof_queue.dart';
import 'package:rujak_pos/data/services/proof_image_service.dart';
import 'package:rujak_pos/data/services/receipt_number_service.dart';
import 'package:rujak_pos/data/session/session_controller.dart';
import 'package:rujak_pos/data/sync/outbox_writer.dart';
import 'package:rujak_pos/features/history/presentation/sale_detail_screen.dart';
import 'package:rujak_pos/features/payments/data/payment_api.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  testWidgets(
    'void reason dialog closes without reusing a disposed controller',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final sale = SaleRecord(
        uuid: 'sale-1',
        receiptNumber: 'RJS-1',
        orderType: 'dine_in',
        lifecycleStatus: 'finalized',
        paymentStatus: 'unpaid',
        subtotal: 25000,
        itemDiscountTotal: 0,
        transactionDiscountTotal: 0,
        discountTotal: 0,
        serviceCharge: 0,
        taxTotal: 0,
        total: 25000,
        confirmedAmount: 0,
        awaitingAmount: 0,
        outstandingAmount: 25000,
        refundedAmount: 0,
        transactedAt: DateTime(2026, 11, 7, 10),
      );
      final repository = _FakeSaleRepository(db, sale);
      const session = AuthSession(
        token: 'token',
        sessionUuid: 'session-1',
        user: AppUser(
          uuid: 'user-1',
          name: 'Kasir',
          permissions: ['sales.void'],
        ),
      );

      final container = ProviderContainer(
        overrides: [
          saleRepositoryProvider.overrideWithValue(repository),
          sessionProvider.overrideWith(() => _FakeSessionController(session)),
          connectivityProvider.overrideWith((ref) => Stream.value(true)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.build(),
            home: const SaleDetailScreen(saleUuid: 'sale-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Void transaksi'));
      await tester.pumpAndSettle();
      expect(find.text('Alasan void'), findsOneWidget);

      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Alasan void'), findsNothing);
    },
  );
}

class _FakeSaleRepository extends SaleRepository {
  _FakeSaleRepository(AppDatabase db, this._sale)
    : super(
        db,
        ApiClient(),
        OutboxWriter(db),
        ReceiptNumberService(db),
        PaymentProofQueue(db, PaymentApi(ApiClient()), ProofImageService()),
      );

  final SaleRecord _sale;

  @override
  Future<SaleRecord?> byUuid(String uuid) async => _sale;

  @override
  Future<SaleRecord?> fetchRemote(String uuid) async => null;
}

class _FakeSessionController extends SessionController {
  _FakeSessionController(this._session);

  final AuthSession? _session;

  @override
  Future<AuthSession?> build() async => _session;
}
