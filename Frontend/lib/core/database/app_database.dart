import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    CatalogCategories,
    CatalogProducts,
    CatalogVariants,
    CatalogAddons,
    LocalOrders,
    OrderItems,
    LocalSales,
    SaleItems,
    SalePayments,
    OutboxEvents,
    LocalShifts,
    CashMovements,
    PrintJobs,
    Settings,
    SyncState,
    ReceiptCounters,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  static const String databaseFileName = 'rujak_pos.sqlite';

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(salePayments, salePayments.paymentUuid);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await into(
        syncState,
      ).insert(const SyncStateCompanion(), mode: InsertMode.insertOrIgnore);
    },
  );

  /// Opens the encrypted database. The key must be obtained from secure
  /// storage (Android Keystore backed) and must never be written to SQLite.
  static QueryExecutor openEncrypted(String key, {String? fileName}) {
    return LazyDatabase(() async {
      final directory = await getApplicationSupportDirectory();
      final file = File(p.join(directory.path, fileName ?? databaseFileName));
      await file.parent.create(recursive: true);

      return NativeDatabase.createInBackground(
        file,
        setup: (database) {
          database.execute('PRAGMA key = ${_quoteKey(key)}');
        },
        isolateSetup: () {
          // Runs before the database is opened on the worker isolate.
        },
      );
    });
  }

  static String _quoteKey(String key) {
    return "'${key.replaceAll("'", "''")}'";
  }

  Future<String?> setting(String key) async {
    final row = await (select(
      settings,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> putSetting(String key, String value) {
    return into(
      settings,
    ).insertOnConflictUpdate(SettingsCompanion.insert(key: key, value: value));
  }

  Future<void> removeSetting(String key) {
    return (delete(settings)..where((t) => t.key.equals(key))).go();
  }

  Future<void> clearBusinessData() async {
    await transaction(() async {
      await delete(outboxEvents).go();
      await delete(printJobs).go();
      await delete(cashMovements).go();
      await delete(salePayments).go();
      await delete(saleItems).go();
      await delete(localSales).go();
      await delete(orderItems).go();
      await delete(localOrders).go();
      await delete(localShifts).go();
      await delete(receiptCounters).go();
      await delete(catalogAddons).go();
      await delete(catalogVariants).go();
      await delete(catalogProducts).go();
      await delete(catalogCategories).go();
      await delete(settings).go();
      await delete(syncState).go();
    });
  }
}
