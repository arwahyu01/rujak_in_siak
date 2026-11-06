import 'package:drift/drift.dart';

import '../../core/database/app_database.dart';
import '../../core/errors/app_exception.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/app_uuid.dart';
import '../../core/utils/json_utils.dart';
import '../models/shift.dart';
import '../sync/outbox_writer.dart';

class ShiftRepository {
  ShiftRepository(this._db, this._api, this._outbox);

  final AppDatabase _db;
  final ApiClient _api;
  final OutboxWriter _outbox;

  Future<ShiftRecord?> activeShift() async {
    final row =
        await (_db.select(_db.localShifts)
              ..where((shift) => shift.status.equals('open'))
              ..orderBy([(shift) => OrderingTerm.desc(shift.openedAt)])
              ..limit(1))
            .getSingleOrNull();
    return row == null ? null : _toRecord(row);
  }

  Future<ShiftRecord?> byUuid(String uuid) async {
    final row = await (_db.select(
      _db.localShifts,
    )..where((shift) => shift.uuid.equals(uuid))).getSingleOrNull();
    return row == null ? null : _toRecord(row);
  }

  Future<ShiftSummary> summary(ShiftRecord shift) async {
    final paymentTotals = await _db
        .customSelect(
          '''
          SELECT
            COALESCE(SUM(CASE WHEN p.method = 'cash' AND p.status = 'confirmed'
              THEN COALESCE(p.tendered_amount, p.amount) ELSE 0 END), 0) AS tendered,
            COALESCE(SUM(CASE WHEN p.method = 'cash' AND p.status = 'confirmed'
              THEN COALESCE(p.change_amount, 0) ELSE 0 END), 0) AS change_total,
            COALESCE(SUM(CASE WHEN p.method != 'cash' AND p.status = 'confirmed'
              THEN COALESCE(p.verified_amount, p.amount) ELSE 0 END), 0) AS noncash,
            COALESCE(SUM(CASE WHEN p.status = 'awaiting_verification'
              THEN p.amount ELSE 0 END), 0) AS awaiting
          FROM sale_payments p
          INNER JOIN local_sales s ON s.uuid = p.sale_uuid
          WHERE s.shift_uuid = ? AND s.lifecycle_status = 'finalized'
          ''',
          variables: [Variable<String>(shift.uuid)],
          readsFrom: {_db.salePayments, _db.localSales},
        )
        .getSingle();

    final salesTotals = await _db
        .customSelect(
          '''
          SELECT COUNT(*) AS total_count, COALESCE(SUM(total), 0) AS total_amount
          FROM local_sales
          WHERE shift_uuid = ? AND lifecycle_status = 'finalized'
          ''',
          variables: [Variable<String>(shift.uuid)],
          readsFrom: {_db.localSales},
        )
        .getSingle();

    final cashIn = await _db
        .customSelect(
          "SELECT COALESCE(SUM(amount), 0) AS total FROM cash_movements WHERE shift_uuid = ? AND type = 'in'",
          variables: [Variable<String>(shift.uuid)],
          readsFrom: {_db.cashMovements},
        )
        .map((row) => row.read<int>('total'))
        .getSingle();
    final cashOut = await _db
        .customSelect(
          "SELECT COALESCE(SUM(amount), 0) AS total FROM cash_movements WHERE shift_uuid = ? AND type = 'out'",
          variables: [Variable<String>(shift.uuid)],
          readsFrom: {_db.cashMovements},
        )
        .map((row) => row.read<int>('total'))
        .getSingle();

    final cashTendered = paymentTotals.read<int>('tendered');
    final cashChange = paymentTotals.read<int>('change_total');
    final expected =
        shift.openingCash + cashTendered - cashChange + cashIn - cashOut;

    return ShiftSummary(
      shift: shift,
      cashTendered: cashTendered,
      cashChange: cashChange,
      cashIn: cashIn,
      cashOut: cashOut,
      cashRefund: 0,
      expectedCash: expected,
      confirmedNonCash: paymentTotals.read<int>('noncash'),
      awaitingVerification: paymentTotals.read<int>('awaiting'),
      transactionCount: salesTotals.read<int>('total_count'),
      saleTotal: salesTotals.read<int>('total_amount'),
    );
  }

  Future<({ShiftRecord shift, bool storedOffline})> open({
    required int openingCash,
    required String openingNotes,
  }) async {
    final existing = await activeShift();
    if (existing != null) {
      return (shift: existing, storedOffline: !existing.synced);
    }

    try {
      final result = await _api.post(
        'shifts/open',
        body: {
          'opening_cash': openingCash,
          if (openingNotes.trim().isNotEmpty)
            'opening_notes': openingNotes.trim(),
        },
      );
      final remote = _recordFromServer(asMap(result.data));
      await _insertLocal(remote, synced: true);
      return (shift: remote, storedOffline: false);
    } on AppException catch (error) {
      if (!error.isNetwork) rethrow;
      return _openOffline(openingCash, openingNotes);
    }
  }

  Future<({ShiftRecord shift, bool storedOffline})> _openOffline(
    int openingCash,
    String openingNotes,
  ) async {
    final now = DateTime.now();
    final uuid = newUuid();
    final record = ShiftRecord(
      uuid: uuid,
      status: 'open',
      openingCash: openingCash,
      openingNotes: openingNotes.trim().isEmpty ? null : openingNotes.trim(),
      openedAt: now,
      synced: false,
    );

    await _db.transaction(() async {
      await _insertLocal(record, synced: false);
      await _outbox.append(
        eventId: newUuid(),
        eventType: 'shift.opened',
        aggregateType: 'shift',
        aggregateId: uuid,
        occurredAt: now,
        payload: {
          'shift_uuid': uuid,
          'status': 'open',
          'opening_cash': openingCash,
          'opening_notes': record.openingNotes,
          'opened_at': now.toIso8601String(),
        },
      );
    });

    return (shift: record, storedOffline: true);
  }

  Future<ShiftRecord> recordCashMovement({
    required ShiftRecord shift,
    required String type,
    required int amount,
    required String reason,
  }) async {
    if (shift.synced) {
      await _api.post(
        'shifts/${shift.uuid}/cash-movements',
        body: {'type': type, 'amount': amount, 'reason': reason},
      );
      await _insertMovement(
        uuid: newUuid(),
        shiftUuid: shift.uuid,
        type: type,
        amount: amount,
        reason: reason,
        occurredAt: DateTime.now(),
        synced: true,
      );
      return shift;
    }

    final now = DateTime.now();
    final uuid = newUuid();
    await _db.transaction(() async {
      await _insertMovement(
        uuid: uuid,
        shiftUuid: shift.uuid,
        type: type,
        amount: amount,
        reason: reason,
        occurredAt: now,
        synced: false,
      );
      await _outbox.append(
        eventId: newUuid(),
        eventType: 'shift.cash_movement',
        aggregateType: 'shift',
        aggregateId: shift.uuid,
        occurredAt: now,
        payload: {
          'shift_uuid': shift.uuid,
          'movement_uuid': uuid,
          'type': type,
          'amount': amount,
          'reason': reason,
          'occurred_at': now.toIso8601String(),
        },
      );
    });
    return shift;
  }

  Future<ShiftRecord> close({
    required ShiftSummary summary,
    required int actualCash,
    String? closingNotes,
  }) async {
    final shift = summary.shift;
    final pending = await _outbox.pendingCount();
    final sequence = await _outbox.maxSequence();

    if (shift.synced && pending == 0) {
      try {
        final result = await _api.post(
          'shifts/close',
          body: {
            'shift_uuid': shift.uuid,
            'actual_cash': actualCash,
            'closing_notes': closingNotes,
            'pending_sync_count': 0,
            'local_event_sequence': sequence,
            'closed_at': DateTime.now().toIso8601String(),
          },
        );
        final remote = _recordFromServer(asMap(result.data));
        await _updateClosed(
          remote: remote,
          actualCash: actualCash,
          closingNotes: closingNotes,
          expectedCash: summary.expectedCash,
          synced: true,
        );
        return remote;
      } on AppException catch (error) {
        if (error.code == 'SHIFT_NOT_OPEN') {
          final remote = await fetchRemoteShift(shift.uuid);
          if (remote != null) return remote;
        }
        rethrow;
      }
    }

    final now = DateTime.now();
    final status = 'closed_pending_sync';
    final record = shift.copyWith(
      status: status,
      closedAt: now,
      expectedCash: summary.expectedCash,
      actualCash: actualCash,
      difference: actualCash - summary.expectedCash,
      closingNotes: closingNotes,
      synced: false,
    );

    await _db.transaction(() async {
      await (_db.update(
        _db.localShifts,
      )..where((row) => row.uuid.equals(shift.uuid))).write(
        LocalShiftsCompanion(
          status: Value(status),
          closedAt: Value(now),
          expectedCash: Value(summary.expectedCash),
          actualCash: Value(actualCash),
          difference: Value(actualCash - summary.expectedCash),
          closingNotes: Value(closingNotes),
          synced: const Value(false),
        ),
      );
      await _outbox.append(
        eventId: newUuid(),
        eventType: 'shift.closed',
        aggregateType: 'shift',
        aggregateId: shift.uuid,
        occurredAt: now,
        payload: {
          'shift_uuid': shift.uuid,
          'opening_cash': summary.shift.openingCash,
          'cash_tendered': summary.cashTendered,
          'cash_change': summary.cashChange,
          'cash_in': summary.cashIn,
          'cash_out': summary.cashOut,
          'cash_refund': summary.cashRefund,
          'expected_cash': summary.expectedCash,
          'actual_cash': actualCash,
          'variance': actualCash - summary.expectedCash,
          'confirmed_noncash': summary.confirmedNonCash,
          'awaiting_verification_amount': summary.awaitingVerification,
          'local_transaction_count': summary.transactionCount,
          'pending_sync_count': pending + 1,
          'local_event_sequence': sequence,
          'closing_notes': closingNotes,
          'closed_at': now.toIso8601String(),
        },
      );
    });

    return record;
  }

  Future<ShiftRecord?> fetchRemoteShift(String uuid) async {
    final result = await _api.get('shifts/$uuid');
    final remote = _recordFromServer(asMap(result.data));
    await _insertLocal(remote, synced: true);
    return remote;
  }

  Future<void> _updateClosed({
    required ShiftRecord remote,
    required int actualCash,
    required String? closingNotes,
    required int expectedCash,
    required bool synced,
  }) async {
    await (_db.update(
      _db.localShifts,
    )..where((row) => row.uuid.equals(remote.uuid))).write(
      LocalShiftsCompanion(
        status: Value(remote.status),
        closedAt: Value(remote.closedAt ?? DateTime.now()),
        expectedCash: Value(remote.expectedCash ?? expectedCash),
        actualCash: Value(actualCash),
        difference: Value(actualCash - (remote.expectedCash ?? expectedCash)),
        closingNotes: Value(closingNotes),
        synced: Value(synced),
      ),
    );
  }

  Future<void> _insertLocal(ShiftRecord record, {required bool synced}) async {
    await _db
        .into(_db.localShifts)
        .insertOnConflictUpdate(
          LocalShiftsCompanion(
            uuid: Value(record.uuid),
            status: Value(record.status),
            openingCash: Value(record.openingCash),
            openingNotes: Value(record.openingNotes),
            openedAt: Value(record.openedAt),
            closedAt: Value(record.closedAt),
            expectedCash: Value(record.expectedCash),
            actualCash: Value(record.actualCash),
            difference: Value(record.difference),
            closingNotes: Value(record.closingNotes),
            synced: Value(synced),
          ),
        );
  }

  Future<void> _insertMovement({
    required String uuid,
    required String shiftUuid,
    required String type,
    required int amount,
    required String reason,
    required DateTime occurredAt,
    required bool synced,
  }) async {
    await _db
        .into(_db.cashMovements)
        .insertOnConflictUpdate(
          CashMovementsCompanion.insert(
            uuid: uuid,
            shiftUuid: shiftUuid,
            type: type,
            amount: amount,
            reason: reason,
            createdAt: occurredAt,
            synced: Value(synced),
          ),
        );
  }

  ShiftRecord _recordFromServer(Map<String, dynamic> json) {
    return ShiftRecord(
      uuid: asStringOr(json['uuid'], ''),
      status: asStringOr(json['status'], 'open'),
      openingCash: asIntOr(json['opening_cash'], 0),
      openingNotes: asStringOrNull(json['opening_notes']),
      openedAt: asDate(json['opened_at']) ?? DateTime.now(),
      closedAt: asDate(json['closed_at']),
      expectedCash: asIntOrNull(json['expected_cash']),
      actualCash: asIntOrNull(json['actual_cash']),
      difference: asIntOrNull(json['variance']),
      closingNotes: asStringOrNull(json['closing_notes']),
      synced: true,
    );
  }

  ShiftRecord _toRecord(LocalShift row) {
    return ShiftRecord(
      uuid: row.uuid,
      status: row.status,
      openingCash: row.openingCash,
      openingNotes: row.openingNotes,
      openedAt: row.openedAt,
      closedAt: row.closedAt,
      expectedCash: row.expectedCash,
      actualCash: row.actualCash,
      difference: row.difference,
      closingNotes: row.closingNotes,
      synced: row.synced,
    );
  }
}
