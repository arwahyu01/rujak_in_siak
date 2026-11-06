import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/database/app_database.dart';
import '../../core/errors/app_exception.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/app_uuid.dart';
import '../../core/utils/json_utils.dart';
import '../models/auth.dart';
import '../repositories/bootstrap_repository.dart';

class SyncStatusSnapshot {
  const SyncStatusSnapshot({
    required this.pending,
    required this.blocked,
    required this.conflicts,
    required this.rejected,
    this.cursor,
    this.lastPushedAt,
    this.lastPulledAt,
    this.catalogSyncedAt,
  });

  final int pending;
  final int blocked;
  final int conflicts;
  final int rejected;
  final String? cursor;
  final DateTime? lastPushedAt;
  final DateTime? lastPulledAt;
  final DateTime? catalogSyncedAt;

  int get total => pending + conflicts + rejected;

  bool get isClean => pending == 0 && conflicts == 0 && rejected == 0;
}

class PushOutcome {
  const PushOutcome({
    required this.sent,
    required this.accepted,
    required this.blocked,
    required this.conflicts,
    required this.rejected,
    required this.pendingRemaining,
  });

  final int sent;
  final int accepted;
  final int blocked;
  final int conflicts;
  final int rejected;
  final int pendingRemaining;

  bool get hasMore => pendingRemaining > 0;
}

class PullOutcome {
  const PullOutcome({
    required this.applied,
    required this.catalogChanged,
    required this.hasMore,
    this.permissionsChanged = false,
    this.cursor,
    this.serverTime,
  });

  final int applied;
  final bool catalogChanged;
  final bool permissionsChanged;
  final bool hasMore;
  final String? cursor;
  final DateTime? serverTime;
}

class OutboxIssue {
  const OutboxIssue({
    required this.eventId,
    required this.eventType,
    required this.aggregateId,
    required this.sequence,
    required this.status,
    required this.attempts,
    required this.occurredAt,
    this.lastError,
  });

  final String eventId;
  final String eventType;
  final String aggregateId;
  final int sequence;
  final String status;
  final int attempts;
  final DateTime occurredAt;
  final String? lastError;
}

class SyncRepository {
  SyncRepository(this._db, this._api, this._bootstrap);

  static const _batchSize = 25;
  static const clockAnchorKey = 'clock_anchor_device_at';
  static const clockUntrustedKey = 'clock_untrusted';
  static const _clockTolerance = Duration(minutes: 5);

  final AppDatabase _db;
  final ApiClient _api;
  final BootstrapRepository _bootstrap;

  Future<SyncStatusSnapshot> status() async {
    final sync = await (_db.select(
      _db.syncState,
    )..where((row) => row.id.equals(1))).getSingleOrNull();
    final pending = await _countOutbox(
      "status IN ('pending', 'blocked_dependency') OR (status = 'rejected' AND retryable = 1)",
    );
    final blocked = await _countOutbox("status = 'blocked_dependency'");
    final conflicts = await _countOutbox("status = 'conflict'");
    final rejected = await _countOutbox(
      "status IN ('rejected', 'upgrade_required') AND retryable = 0",
    );

    return SyncStatusSnapshot(
      pending: pending,
      blocked: blocked,
      conflicts: conflicts,
      rejected: rejected,
      cursor: sync?.cursor,
      lastPushedAt: sync?.lastPushedAt,
      lastPulledAt: sync?.lastPulledAt,
      catalogSyncedAt: sync?.catalogSyncedAt,
    );
  }

  Future<PushOutcome> pushOnce({
    required AuthSession session,
    required String outletUuid,
  }) async {
    final events =
        await (_db.select(_db.outboxEvents)
              ..where(
                (row) =>
                    row.status.equals('pending') |
                    row.status.equals('blocked_dependency') |
                    (row.status.equals('rejected') &
                        row.retryable.equals(true)),
              )
              ..orderBy([(row) => OrderingTerm.asc(row.sequence)])
              ..limit(_batchSize))
            .get();
    if (events.isEmpty) {
      return const PushOutcome(
        sent: 0,
        accepted: 0,
        blocked: 0,
        conflicts: 0,
        rejected: 0,
        pendingRemaining: 0,
      );
    }

    final device = session.device;
    if (device == null || device.uuid.isEmpty) {
      throw const AppException(
        'DEVICE_REQUIRED',
        'Perangkat belum terdaftar untuk sinkronisasi.',
      );
    }
    final leaseToken = session.lease?.token ?? '';
    if (leaseToken.isEmpty || !session.leaseValid) {
      throw const AppException(
        'OFFLINE_LEASE_EXPIRED',
        'Lisensi offline tidak valid. Perbarui lisensi sebelum sinkronisasi.',
      );
    }

    final batchId = newUuid();
    final result = await _api.post(
      'sync/push',
      body: {
        'protocol_version': 1,
        'batch_id': batchId,
        'device_id': device.uuid,
        'outlet_id': outletUuid,
        'origin': 'offline',
        'lease_token': leaseToken,
        'events': events.map(_eventJson).toList(growable: false),
      },
    );

    final data = asMap(result.data);
    final results = asMapList(data['results']);
    final byEvent = {
      for (final item in results) asStringOr(item['event_id'], ''): item,
    };

    var accepted = 0;
    var blocked = 0;
    var conflicts = 0;
    var rejected = 0;

    await _db.transaction(() async {
      for (final event in events) {
        final outcome = byEvent[event.eventId];
        if (outcome == null) continue;
        final status = asStringOr(outcome['status'], 'rejected');
        final errorCode = asStringOrNull(outcome['error_code']);
        final retryable = asBool(outcome['retryable']);

        String storedStatus;
        switch (status) {
          case 'accepted':
            storedStatus = 'synced';
            accepted++;
            await _markAggregateSynced(event);
          case 'duplicate':
            storedStatus = 'synced';
            accepted++;
            await _markAggregateSynced(event);
          case 'blocked_dependency':
            storedStatus = 'blocked_dependency';
            blocked++;
          case 'conflict':
            storedStatus = 'conflict';
            conflicts++;
          case 'upgrade_required':
            storedStatus = 'upgrade_required';
            rejected++;
          default:
            storedStatus = 'rejected';
            rejected++;
        }

        await (_db.update(
          _db.outboxEvents,
        )..where((row) => row.eventId.equals(event.eventId))).write(
          OutboxEventsCompanion(
            status: Value(storedStatus),
            retryable: Value(storedStatus == 'blocked_dependency' || retryable),
            lastError: Value(errorCode),
            attempts: Value(event.attempts + 1),
            lastAttemptAt: Value(DateTime.now()),
          ),
        );
      }

      await (_db.update(_db.syncState)..where((row) => row.id.equals(1))).write(
        SyncStateCompanion(lastPushedAt: Value(DateTime.now())),
      );
    });

    final pendingRemaining = await _countOutbox(
      "status IN ('pending', 'blocked_dependency') OR (status = 'rejected' AND retryable = 1)",
    );

    return PushOutcome(
      sent: events.length,
      accepted: accepted,
      blocked: blocked,
      conflicts: conflicts,
      rejected: rejected,
      pendingRemaining: pendingRemaining,
    );
  }

  Future<PullOutcome> pullOnce({required String cursor}) async {
    final result = await _api.get(
      'sync/pull',
      query: {'cursor': cursor, 'limit': 200},
    );
    final data = asMap(result.data);
    final changes = asMapList(data['changes']);
    final nextCursor = asStringOrNull(data['next_cursor']);
    final serverTime = asDate(data['server_time']);
    var catalogChanged = false;
    var permissionsChanged = false;

    await _db.transaction(() async {
      for (final change in changes) {
        final type = asStringOr(change['event_type'], '');
        final payload = asMap(change['payload']);
        if (type.startsWith('product.') || type.startsWith('category.')) {
          catalogChanged = true;
        }
        if (type.startsWith('permission.')) {
          permissionsChanged = true;
        }
        await _applyChange(type, payload);
      }

      await (_db.update(_db.syncState)..where((row) => row.id.equals(1))).write(
        SyncStateCompanion(
          cursor: Value(nextCursor),
          lastPulledAt: Value(DateTime.now()),
          lastServerTime: Value(serverTime?.toIso8601String()),
          catalogSyncedAt: catalogChanged
              ? Value(DateTime.now())
              : const Value.absent(),
        ),
      );
      await _recordClockAnchor(serverTime);
    });

    return PullOutcome(
      applied: changes.length,
      catalogChanged: catalogChanged,
      permissionsChanged: permissionsChanged,
      hasMore: asBool(data['has_more']),
      cursor: nextCursor,
      serverTime: serverTime,
    );
  }

  Future<void> _recordClockAnchor(DateTime? serverTime) async {
    if (serverTime == null) return;
    final now = DateTime.now();
    final skew = now.difference(serverTime).abs();
    await _db.putSetting(clockAnchorKey, now.toUtc().toIso8601String());
    await _db.putSetting(clockUntrustedKey, skew > _clockTolerance ? '1' : '0');
  }

  Future<void> _applyChange(String type, Map<String, dynamic> payload) async {
    if (type == 'product.created' ||
        type == 'product.updated' ||
        type == 'product.availability_changed') {
      await _bootstrap.importProduct(payload);
      return;
    }
    if (type == 'category.created' || type == 'category.updated') {
      await _bootstrap.importCategory(payload);
      return;
    }
    if (type == 'sale.finalized') {
      await _applySaleFinalized(payload);
      return;
    }
    if (type == 'sale.voided') {
      await _applySaleVoided(payload);
      return;
    }
    if (type == 'sale.refunded') {
      await _applySaleRefunded(payload);
      return;
    }
    if (type == 'payment.recorded') {
      await _applyPaymentRecorded(payload);
      return;
    }
    if (type == 'payment.verified' || type == 'payment.amount_corrected') {
      await _applyPaymentVerified(payload);
      return;
    }
    if (type == 'payment.rejected') {
      await _applyPaymentRejected(payload);
      return;
    }
    if (type == 'shift.opened') {
      await _applyShiftOpened(payload);
      return;
    }
    if (type == 'shift.closed' || type == 'shift.reconciled') {
      await _applyShiftClosed(payload);
    }
  }

  Future<void> _applySaleFinalized(Map<String, dynamic> payload) async {
    final uuid = asStringOrNull(payload['sale_uuid']);
    if (uuid == null || uuid.isEmpty) return;
    final existing = await _saleRow(uuid);
    final transactedAt = asDate(payload['transacted_at']) ?? DateTime.now();
    final total = asIntOr(payload['total'], 0);
    final confirmed = asIntOr(payload['confirmed_amount'], 0);
    final awaiting = asIntOr(payload['awaiting_verification_amount'], 0);

    if (existing == null) {
      await _db
          .into(_db.localSales)
          .insert(
            LocalSalesCompanion.insert(
              uuid: uuid,
              receiptNumber: asStringOr(payload['receipt_number'], uuid),
              serverOrderUuid: Value(
                asStringOrNull(payload['source_order_uuid']),
              ),
              origin: const Value('online'),
              orderType: asStringOr(payload['order_type'], 'dine_in'),
              tableNumber: Value(asStringOrNull(payload['table_number'])),
              lifecycleStatus: Value(
                asStringOr(payload['lifecycle_status'], 'finalized'),
              ),
              paymentStatus: Value(
                asStringOr(payload['payment_status'], 'unpaid'),
              ),
              subtotal: asIntOr(payload['subtotal'], total),
              discountTotal: Value(asIntOr(payload['discount_total'], 0)),
              serviceCharge: Value(asIntOr(payload['service_charge'], 0)),
              taxTotal: Value(asIntOr(payload['tax_total'], 0)),
              total: total,
              confirmedAmount: Value(confirmed),
              awaitingAmount: Value(awaiting),
              refundedAmount: Value(asIntOr(payload['refunded_amount'], 0)),
              shiftUuid: Value(asStringOrNull(payload['shift_uuid'])),
              synced: const Value(true),
              transactedAt: transactedAt,
              createdAt: transactedAt,
            ),
          );
      await _insertEventPayments(uuid, asMapList(payload['payments']));
      return;
    }

    await (_db.update(
      _db.localSales,
    )..where((row) => row.uuid.equals(uuid))).write(
      LocalSalesCompanion(
        paymentStatus: Value(
          asStringOr(payload['payment_status'], existing.paymentStatus),
        ),
        confirmedAmount: Value(confirmed),
        awaitingAmount: Value(awaiting),
        refundedAmount: Value(
          asIntOr(payload['refunded_amount'], existing.refundedAmount),
        ),
        synced: const Value(true),
      ),
    );
  }

  Future<void> _applySaleVoided(Map<String, dynamic> payload) async {
    final uuid = asStringOrNull(payload['sale_uuid']);
    if (uuid == null) return;
    await (_db.update(
      _db.localSales,
    )..where((row) => row.uuid.equals(uuid))).write(
      LocalSalesCompanion(
        lifecycleStatus: Value(
          asStringOr(payload['lifecycle_status'], 'voided'),
        ),
        paymentStatus: Value(
          asStringOr(payload['payment_status'], 'cancelled'),
        ),
        synced: const Value(true),
      ),
    );
  }

  Future<void> _applySaleRefunded(Map<String, dynamic> payload) async {
    final uuid = asStringOrNull(payload['sale_uuid']);
    if (uuid == null) return;
    await (_db.update(
      _db.localSales,
    )..where((row) => row.uuid.equals(uuid))).write(
      LocalSalesCompanion(
        paymentStatus: Value(
          asStringOr(payload['payment_status'], 'partially_refunded'),
        ),
        refundedAmount: Value(asIntOr(payload['refunded_amount'], 0)),
        synced: const Value(true),
      ),
    );
  }

  Future<void> _applyPaymentRecorded(Map<String, dynamic> payload) async {
    final saleUuid = asStringOrNull(payload['sale_uuid']);
    final paymentUuid = asStringOrNull(payload['payment_uuid']);
    if (saleUuid == null || paymentUuid == null) return;
    final sale = await _saleRow(saleUuid);
    if (sale == null) return;

    final exists =
        await (_db.select(_db.salePayments)..where(
              (row) =>
                  row.saleUuid.equals(saleUuid) &
                  row.paymentUuid.equals(paymentUuid),
            ))
            .getSingleOrNull();
    if (exists == null) {
      final status = asStringOr(payload['status'], 'awaiting_verification');
      final amount = asIntOr(payload['amount'], 0);
      await _db
          .into(_db.salePayments)
          .insert(
            SalePaymentsCompanion.insert(
              saleUuid: saleUuid,
              paymentUuid: Value(paymentUuid),
              method: asStringOr(payload['method'], 'cash'),
              amount: amount,
              tenderedAmount: Value(asIntOrNull(payload['tendered_amount'])),
              changeAmount: Value(asIntOr(payload['change_amount'], 0)),
              verifiedAmount: Value(status == 'confirmed' ? amount : null),
              status: status,
              providerReference: Value(
                asStringOrNull(payload['provider_reference']),
              ),
              createdAt: DateTime.now(),
              confirmedAt: Value(status == 'confirmed' ? DateTime.now() : null),
            ),
          );
    }

    await (_db.update(
      _db.localSales,
    )..where((row) => row.uuid.equals(saleUuid))).write(
      LocalSalesCompanion(
        paymentStatus: Value(
          asStringOr(payload['payment_status'], sale.paymentStatus),
        ),
        synced: const Value(true),
      ),
    );
  }

  Future<void> _applyPaymentVerified(Map<String, dynamic> payload) async {
    final saleUuid = asStringOrNull(payload['sale_uuid']);
    final paymentUuid = asStringOrNull(payload['payment_uuid']);
    if (saleUuid == null) return;

    if (paymentUuid != null) {
      final payment =
          await (_db.select(_db.salePayments)..where(
                (row) =>
                    row.saleUuid.equals(saleUuid) &
                    row.paymentUuid.equals(paymentUuid),
              ))
              .getSingleOrNull();
      if (payment != null) {
        final verified = asIntOr(payload['verified_amount'], payment.amount);
        await (_db.update(
          _db.salePayments,
        )..where((row) => row.id.equals(payment.id))).write(
          SalePaymentsCompanion(
            status: Value(asStringOr(payload['status'], 'confirmed')),
            verifiedAmount: Value(verified),
            confirmedAt: Value(DateTime.now()),
          ),
        );
      }
    }

    final sale = await _saleRow(saleUuid);
    if (sale == null) return;

    await (_db.update(
      _db.localSales,
    )..where((row) => row.uuid.equals(saleUuid))).write(
      LocalSalesCompanion(
        paymentStatus: Value(
          asStringOr(payload['payment_status'], sale.paymentStatus),
        ),
        confirmedAmount: Value(
          asIntOr(payload['confirmed_amount'], sale.confirmedAmount),
        ),
        awaitingAmount: Value(
          asIntOr(payload['awaiting_verification_amount'], sale.awaitingAmount),
        ),
        synced: const Value(true),
      ),
    );
  }

  Future<void> _applyPaymentRejected(Map<String, dynamic> payload) async {
    final saleUuid = asStringOrNull(payload['sale_uuid']);
    final paymentUuid = asStringOrNull(payload['payment_uuid']);
    if (saleUuid == null) return;
    if (paymentUuid != null) {
      await (_db.update(_db.salePayments)..where(
            (row) =>
                row.saleUuid.equals(saleUuid) &
                row.paymentUuid.equals(paymentUuid),
          ))
          .write(
            const SalePaymentsCompanion(
              status: Value('rejected'),
              verifiedAmount: Value(null),
            ),
          );
    }
    await (_db.update(
      _db.localSales,
    )..where((row) => row.uuid.equals(saleUuid))).write(
      LocalSalesCompanion(
        paymentStatus: Value(asStringOr(payload['payment_status'], 'unpaid')),
        synced: const Value(true),
      ),
    );
  }

  Future<void> _applyShiftOpened(Map<String, dynamic> payload) async {
    final uuid = asStringOrNull(payload['shift_uuid']);
    if (uuid == null || uuid.isEmpty) return;
    final existing = await (_db.select(
      _db.localShifts,
    )..where((row) => row.uuid.equals(uuid))).getSingleOrNull();
    if (existing != null) {
      await (_db.update(
        _db.localShifts,
      )..where((row) => row.uuid.equals(uuid))).write(
        const LocalShiftsCompanion(status: Value('open'), synced: Value(true)),
      );
      return;
    }
    await _db
        .into(_db.localShifts)
        .insert(
          LocalShiftsCompanion.insert(
            uuid: uuid,
            status: Value(asStringOr(payload['status'], 'open')),
            openingCash: Value(asIntOr(payload['opening_cash'], 0)),
            openingNotes: Value(asStringOrNull(payload['opening_notes'])),
            openedAt: asDate(payload['opened_at']) ?? DateTime.now(),
            expectedCash: Value(asIntOrNull(payload['expected_cash'])),
            synced: const Value(true),
          ),
        );
  }

  Future<void> _applyShiftClosed(Map<String, dynamic> payload) async {
    final shift = asMapOrNull(payload['shift']);
    final totals = asMapOrNull(payload['totals']);
    final uuid =
        asStringOrNull(shift?['uuid']) ?? asStringOrNull(payload['shift_uuid']);
    if (uuid == null || uuid.isEmpty) return;
    final existing = await (_db.select(
      _db.localShifts,
    )..where((row) => row.uuid.equals(uuid))).getSingleOrNull();
    if (existing == null) return;

    final status = asStringOr(
      shift?['status'] ?? payload['status'],
      'closed_confirmed',
    );
    await (_db.update(
      _db.localShifts,
    )..where((row) => row.uuid.equals(uuid))).write(
      LocalShiftsCompanion(
        status: Value(status),
        closedAt: Value(
          asDate(shift?['closed_at'] ?? payload['closed_at']) ?? DateTime.now(),
        ),
        expectedCash: Value(
          asIntOrNull(totals?['expected_cash'] ?? payload['expected_cash']),
        ),
        actualCash: Value(
          asIntOrNull(totals?['actual_cash'] ?? payload['actual_cash']),
        ),
        difference: Value(
          asIntOrNull(totals?['variance'] ?? payload['variance']),
        ),
        closingNotes: Value(asStringOrNull(payload['closing_notes'])),
        synced: const Value(true),
      ),
    );
  }

  Future<void> _insertEventPayments(
    String saleUuid,
    List<Map<String, dynamic>> payments,
  ) async {
    for (final payment in payments) {
      final status = asStringOr(payment['status'], 'confirmed');
      final amount = asIntOr(payment['amount'], 0);
      await _db
          .into(_db.salePayments)
          .insert(
            SalePaymentsCompanion.insert(
              saleUuid: saleUuid,
              paymentUuid: Value(asStringOrNull(payment['payment_uuid'])),
              method: asStringOr(payment['method'], 'cash'),
              amount: amount,
              tenderedAmount: Value(asIntOrNull(payment['tendered_amount'])),
              changeAmount: Value(asIntOr(payment['change_amount'], 0)),
              verifiedAmount: Value(status == 'confirmed' ? amount : null),
              status: status,
              providerReference: Value(
                asStringOrNull(payment['provider_reference']),
              ),
              createdAt: DateTime.now(),
              confirmedAt: Value(status == 'confirmed' ? DateTime.now() : null),
            ),
          );
    }
  }

  Future<List<OutboxIssue>> issues({int limit = 100}) async {
    final rows =
        await (_db.select(_db.outboxEvents)
              ..where((row) => row.status.equals('synced').not())
              ..orderBy([(row) => OrderingTerm.asc(row.sequence)])
              ..limit(limit))
            .get();
    return rows
        .map(
          (row) => OutboxIssue(
            eventId: row.eventId,
            eventType: row.eventType,
            aggregateId: row.aggregateId,
            sequence: row.sequence,
            status: row.status,
            attempts: row.attempts,
            occurredAt: row.occurredAt,
            lastError: row.lastError,
          ),
        )
        .toList(growable: false);
  }

  Future<LocalSale?> _saleRow(String uuid) {
    return (_db.select(
      _db.localSales,
    )..where((row) => row.uuid.equals(uuid))).getSingleOrNull();
  }

  Future<int> _countOutbox(String where) {
    return _db
        .customSelect(
          'SELECT COUNT(*) AS total FROM outbox_events WHERE $where',
          readsFrom: {_db.outboxEvents},
        )
        .map((row) => row.read<int>('total'))
        .getSingle();
  }

  Map<String, dynamic> _eventJson(OutboxEvent event) {
    return {
      'event_id': event.eventId,
      'event_type': event.eventType,
      'aggregate_type': event.aggregateType,
      'aggregate_id': event.aggregateId,
      'sequence': event.sequence,
      'schema_version': event.schemaVersion,
      'occurred_at': event.occurredAt.toIso8601String(),
      'payload': _decodePayload(event.payloadJson),
    };
  }

  Map<String, dynamic> _decodePayload(String value) {
    try {
      return asMap(jsonDecode(value));
    } catch (_) {
      return const {};
    }
  }

  Future<void> _markAggregateSynced(OutboxEvent event) async {
    switch (event.eventType) {
      case 'sale.finalized':
        await (_db.update(_db.localSales)
              ..where((row) => row.uuid.equals(event.aggregateId)))
            .write(const LocalSalesCompanion(synced: Value(true)));
        break;
      case 'order.created':
      case 'order.updated':
      case 'order.held':
      case 'order.resumed':
      case 'order.cancelled':
      case 'order.converted':
        await (_db.update(_db.localOrders)
              ..where((row) => row.uuid.equals(event.aggregateId)))
            .write(const LocalOrdersCompanion(synced: Value(true)));
        break;
      case 'shift.opened':
        await (_db.update(_db.localShifts)
              ..where((row) => row.uuid.equals(event.aggregateId)))
            .write(const LocalShiftsCompanion(synced: Value(true)));
        break;
      case 'shift.cash_movement':
        final movementUuid = asStringOrNull(
          _decodePayload(event.payloadJson)['movement_uuid'],
        );
        await (_db.update(_db.cashMovements)..where(
              (row) => row.uuid.equals(movementUuid ?? event.aggregateId),
            ))
            .write(const CashMovementsCompanion(synced: Value(true)));
        break;
      case 'shift.closed':
        await (_db.update(
          _db.localShifts,
        )..where((row) => row.uuid.equals(event.aggregateId))).write(
          const LocalShiftsCompanion(
            status: Value('closed_pending_sync'),
            synced: Value(true),
          ),
        );
        break;
    }
  }
}
