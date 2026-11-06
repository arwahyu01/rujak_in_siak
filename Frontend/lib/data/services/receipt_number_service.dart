import 'package:drift/drift.dart';

import '../../core/database/app_database.dart';

class ReceiptNumberService {
  ReceiptNumberService(this._db);

  final AppDatabase _db;

  /// Offline receipts use a per-terminal counter that is never allowed to go
  /// backwards and never reuses a number after a restart. The server bumps its
  /// own sequence when an offline receipt is registered during sync.
  Future<String> nextOffline({
    required String outletCode,
    required String terminalCode,
    required String format,
  }) async {
    final terminal = _sanitize(terminalCode);
    final outlet = _sanitize(outletCode);

    return _db.transaction(() async {
      final row = await (_db.select(
        _db.receiptCounters,
      )..where((item) => item.terminalCode.equals(terminal))).getSingleOrNull();
      final last = row?.lastSequence ?? 0;
      final clockFloor = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final sequence = last + 1 > clockFloor ? last + 1 : clockFloor;

      await _db
          .into(_db.receiptCounters)
          .insertOnConflictUpdate(
            ReceiptCountersCompanion.insert(
              terminalCode: terminal,
              lastSequence: Value(sequence),
              updatedAt: DateTime.now(),
            ),
          );

      return _format(
        format: format,
        outletCode: outlet,
        terminalCode: terminal,
        sequence: sequence,
      );
    });
  }

  Future<void> alignFromServerReceipt(
    String receiptNumber,
    String terminalCode,
  ) async {
    final match = RegExp(r'-(\d{10})$').firstMatch(receiptNumber.trim());
    if (match == null) return;
    final sequence = int.tryParse(match.group(1)!);
    if (sequence == null) return;

    final terminal = _sanitize(terminalCode);
    final row = await (_db.select(
      _db.receiptCounters,
    )..where((item) => item.terminalCode.equals(terminal))).getSingleOrNull();
    if (row != null && row.lastSequence >= sequence) return;

    await _db
        .into(_db.receiptCounters)
        .insertOnConflictUpdate(
          ReceiptCountersCompanion.insert(
            terminalCode: terminal,
            lastSequence: Value(sequence),
            updatedAt: DateTime.now(),
          ),
        );
  }

  String _format({
    required String format,
    required String outletCode,
    required String terminalCode,
    required int sequence,
  }) {
    final padded = sequence.toString().padLeft(10, '0');
    var value = format.trim();
    if (!value.contains('{SEQUENCE}')) {
      value = 'RJS-{OUTLET}-{TERMINAL}-{SEQUENCE}';
    }
    return value
        .replaceAll('{OUTLET}', outletCode)
        .replaceAll('{TERMINAL}', terminalCode)
        .replaceAll('{SEQUENCE}', padded);
  }

  String _sanitize(String value) {
    final normalized = value.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    return normalized.isEmpty ? 'POS1' : normalized;
  }
}
