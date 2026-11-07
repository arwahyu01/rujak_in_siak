import 'dart:convert';

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
              ..where((shift) => shift.status.isIn(const ['open', 'closing']))
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

  /// Fetches the single outlet shift every device in this outlet shares.
  ///
  /// The server is authoritative while reachable. If the server reports no
  /// active shift, a previously synced local shift is marked `closed_remote`
  /// so POS refuses further transactions. A locally opened, still unsynced
  /// shift is kept as-is until it can be pushed.
  Future<ShiftRecord?> refreshActiveFromServer() async {
    final local = await activeShift();
    final ApiResult result;
    try {
      result = await _api.get('shifts/active');
    } on AppException catch (error) {
      if (error.isNetwork) return local;
      rethrow;
    }

    if (result.data == null) {
      if (local != null && local.synced) {
        await _writeRecord(
          local.copyWith(
            status: 'closed_remote',
            isClosing: false,
            canFinalize: false,
            pendingDevices: const [],
          ),
          synced: true,
        );
        return null;
      }
      return local;
    }

    final remote = _recordFromServer(asMap(result.data));
    if (remote.uuid.isEmpty) return local;

    await _db.transaction(() async {
      if (local != null && local.uuid != remote.uuid) {
        // Never merge two shifts silently. The local shift stays readable but
        // stops accepting transactions once the server has another active one.
        await _writeRecord(
          local.copyWith(
            status: local.synced ? 'closed_remote' : 'closed_sync_exception',
            isClosing: false,
            canFinalize: false,
            pendingDevices: const [],
          ),
          synced: local.synced,
        );
      }
      await _writeRecord(remote, synced: true);
    });
    return remote;
  }

  Future<ShiftSummary> summary(ShiftRecord shift) async {
    if (shift.serverSummary != null) {
      return ShiftSummary.fromServer(shift);
    }

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
    if (existing != null && existing.isActive) {
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
      await _writeRecord(remote, synced: true);
      return (shift: remote, storedOffline: false);
    } on AppException catch (error) {
      if (error.code == 'SHIFT_ALREADY_OPEN') {
        // Another device won the race. Adopt the outlet shift instead of
        // creating a second local one.
        final active = await refreshActiveFromServer();
        if (active != null) {
          return (shift: active, storedOffline: false);
        }
        rethrow;
      }
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
      await _writeRecord(record, synced: false);
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
    final movementType = switch (type) {
      'cash_in' || 'in' => 'in',
      'cash_out' || 'out' => 'out',
      _ => throw const AppException(
        'INVALID_CASH_MOVEMENT_TYPE',
        'Jenis pergerakan kas tidak valid.',
      ),
    };

    if (!shift.acceptsTransactions) {
      throw const AppException(
        'SHIFT_CLOSING',
        'Shift sedang ditutup atau sudah tutup. Kas masuk/keluar tidak dapat dicatat.',
        statusCode: 409,
      );
    }

    if (shift.synced) {
      final result = await _api.post(
        'shifts/${shift.uuid}/cash-movements',
        body: {'type': movementType, 'amount': amount, 'reason': reason},
      );
      final remote = _recordFromServer(asMap(result.data));
      await _insertMovement(
        uuid: newUuid(),
        shiftUuid: shift.uuid,
        type: movementType,
        amount: amount,
        reason: reason,
        occurredAt: DateTime.now(),
        synced: true,
      );
      await _writeRecord(remote, synced: true);
      return remote;
    }

    final now = DateTime.now();
    final uuid = newUuid();
    await _db.transaction(() async {
      await _insertMovement(
        uuid: uuid,
        shiftUuid: shift.uuid,
        type: movementType,
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
          'type': movementType,
          'amount': amount,
          'reason': reason,
          'occurred_at': now.toIso8601String(),
        },
      );
    });
    return shift;
  }

  /// Requests the close and returns the server state.
  ///
  /// The shift usually returns as `closing`; the server finalizes it only
  /// after every participating device has checkpointed for the close epoch.
  /// Closing is intentionally online-only: a local snapshot must never look
  /// complete while other devices still hold unsynced transactions.
  Future<ShiftRecord> close({
    required ShiftSummary summary,
    required int actualCash,
    String? closingNotes,
  }) async {
    final shift = summary.shift;
    if (!shift.isActive) {
      throw const AppException(
        'SHIFT_NOT_OPEN',
        'Shift sudah ditutup dan tidak dapat ditutup ulang.',
      );
    }

    final pending = await _outbox.pendingCount();
    if (pending > 0) {
      throw AppException(
        'SHIFT_DEVICE_OUTBOX_NOT_DRAINED',
        'Masih ada $pending event lokal yang belum terkirim. Sinkronkan '
            'perangkat ini sebelum menutup shift.',
        statusCode: 409,
        retryable: true,
      );
    }

    final sequence = await _outbox.maxSequence();
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
      await _writeRecord(remote, synced: true);
      return remote;
    } on AppException catch (error) {
      if (error.isNetwork) {
        throw const AppException(
          'SHIFT_CLOSE_REQUIRES_SYNC',
          'Penutupan shift memerlukan koneksi ke server agar transaksi semua '
              'perangkat dapat dipastikan lengkap. Sinkronkan lalu coba lagi.',
          retryable: true,
        );
      }
      rethrow;
    }
  }

  Future<ShiftRecord> checkpoint(ShiftRecord shift) async {
    final pending = await _outbox.pendingCount();
    if (pending > 0) {
      throw AppException(
        'SHIFT_DEVICE_OUTBOX_NOT_DRAINED',
        'Masih ada $pending event lokal yang belum terkirim. Sinkronkan '
            'perangkat ini terlebih dahulu.',
        statusCode: 409,
        retryable: true,
      );
    }

    final result = await _api.post(
      'shifts/${shift.uuid}/sync-checkpoint',
      body: {
        'close_epoch': shift.closeEpoch,
        'pending_outbox_count': 0,
        'last_sequence': await _outbox.maxSequence(),
      },
    );
    final remote = _recordFromServer(asMap(result.data));
    await _writeRecord(remote, synced: true);
    return remote;
  }

  Future<ShiftRecord?> fetchRemoteShift(String uuid) async {
    final result = await _api.get('shifts/$uuid');
    final remote = _recordFromServer(asMap(result.data));
    await _writeRecord(remote, synced: true);
    return remote;
  }

  Future<void> _writeRecord(ShiftRecord record, {required bool synced}) async {
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
            closeEpoch: Value(record.closeEpoch),
            isClosing: Value(record.status == 'closing' || record.isClosing),
            openedByName: Value(record.openedByName),
            openedDeviceName: Value(record.openedDeviceName),
            closeActualCash: Value(record.closeActualCash),
            closedByName: Value(record.closedByName),
            closedDeviceName: Value(record.closedDeviceName),
            canFinalize: Value(record.canFinalize),
            pendingDevicesJson: Value(
              jsonEncode(
                record.pendingDevices
                    .map((device) => device.toJson())
                    .toList(),
              ),
            ),
            serverSummaryJson: Value(
              record.serverSummary == null
                  ? null
                  : jsonEncode(record.serverSummary!.toJson()),
            ),
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
    final openedBy = asMapOrNull(json['opened_by']);
    final openedDevice = asMapOrNull(json['opened_device']);
    final closedBy = asMapOrNull(json['closed_by']);
    final closedDevice = asMapOrNull(json['closed_device']);
    final summary = asMapOrNull(json['summary']);
    final sync = asMapOrNull(json['sync']);
    final pending = asMapList(
      json['pending_devices'] ?? sync?['pending_devices'],
    ).map(ShiftPendingDevice.fromJson).toList(growable: false);

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
      closeEpoch: asIntOr(json['close_epoch'], 0),
      isClosing: asBool(json['is_closing'], false),
      openedByName: openedBy == null ? null : asStringOrNull(openedBy['name']),
      openedDeviceName: openedDevice == null
          ? null
          : asStringOrNull(openedDevice['name']),
      closeActualCash: asIntOrNull(json['close_actual_cash']),
      closedByName: closedBy == null ? null : asStringOrNull(closedBy['name']),
      closedDeviceName: closedDevice == null
          ? null
          : asStringOrNull(closedDevice['name']),
      canFinalize: asBool(json['can_finalize']),
      pendingDevices: pending,
      serverSummary: summary == null
          ? null
          : ShiftServerSummary.fromJson(summary),
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
      closeEpoch: row.closeEpoch,
      isClosing: row.isClosing,
      openedByName: row.openedByName,
      openedDeviceName: row.openedDeviceName,
      closeActualCash: row.closeActualCash,
      closedByName: row.closedByName,
      closedDeviceName: row.closedDeviceName,
      canFinalize: row.canFinalize,
      pendingDevices: _decodePending(row.pendingDevicesJson),
      serverSummary: _decodeSummary(row.serverSummaryJson),
    );
  }

  List<ShiftPendingDevice> _decodePending(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((item) => ShiftPendingDevice.fromJson(asMap(item)))
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  ShiftServerSummary? _decodeSummary(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return ShiftServerSummary.fromJson(asMap(decoded));
    } catch (_) {
      return null;
    }
  }
}
