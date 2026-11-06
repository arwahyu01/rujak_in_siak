import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database/app_database.dart';
import 'network/api_client.dart';
import 'storage/secure_store.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/bootstrap_repository.dart';
import '../data/repositories/order_repository.dart';
import '../data/repositories/sale_repository.dart';
import '../data/repositories/shift_repository.dart';
import '../features/payments/data/payment_api.dart';
import '../features/reports/data/reports_api.dart';
import '../features/sales/data/sales_api.dart';
import '../data/services/printer_service.dart';
import '../data/services/receipt_number_service.dart';
import '../data/sync/outbox_writer.dart';
import '../data/sync/sync_repository.dart';

final secureStoreProvider = Provider<SecureStore>((ref) {
  throw StateError('secureStoreProvider must be overridden at startup');
});

final databaseProvider = Provider<AppDatabase>((ref) {
  throw StateError('databaseProvider must be overridden at startup');
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiClientProvider));
});

final bootstrapRepositoryProvider = Provider<BootstrapRepository>((ref) {
  return BootstrapRepository(
    ref.watch(databaseProvider),
    ref.watch(apiClientProvider),
  );
});

final outboxWriterProvider = Provider<OutboxWriter>((ref) {
  return OutboxWriter(ref.watch(databaseProvider));
});

final receiptNumberServiceProvider = Provider<ReceiptNumberService>((ref) {
  return ReceiptNumberService(ref.watch(databaseProvider));
});

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(ref.watch(databaseProvider));
});

final shiftRepositoryProvider = Provider<ShiftRepository>((ref) {
  return ShiftRepository(
    ref.watch(databaseProvider),
    ref.watch(apiClientProvider),
    ref.watch(outboxWriterProvider),
  );
});

final saleRepositoryProvider = Provider<SaleRepository>((ref) {
  return SaleRepository(
    ref.watch(databaseProvider),
    ref.watch(apiClientProvider),
    ref.watch(outboxWriterProvider),
    ref.watch(receiptNumberServiceProvider),
  );
});

final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  return SyncRepository(
    ref.watch(databaseProvider),
    ref.watch(apiClientProvider),
    ref.watch(bootstrapRepositoryProvider),
  );
});

final printerServiceProvider = Provider<PrinterService>((ref) {
  return PrinterService(ref.watch(databaseProvider));
});

final salesApiProvider = Provider<SalesApi>((ref) {
  return SalesApi(
    ref.watch(apiClientProvider),
    ref.watch(saleRepositoryProvider),
  );
});

final paymentApiProvider = Provider<PaymentApi>((ref) {
  return PaymentApi(ref.watch(apiClientProvider));
});

final reportsApiProvider = Provider<ReportsApi>((ref) {
  return ReportsApi(ref.watch(apiClientProvider));
});

final connectivityProvider = StreamProvider<bool>((ref) {
  final connectivity = Connectivity();
  return connectivity.onConnectivityChanged
      .map(
        (results) => results.any(
          (result) =>
              result != ConnectivityResult.none &&
              result != ConnectivityResult.bluetooth,
        ),
      )
      .distinct();
});
