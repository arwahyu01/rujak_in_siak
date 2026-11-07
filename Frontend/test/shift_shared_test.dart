import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rujak_pos/core/database/app_database.dart';
import 'package:rujak_pos/core/errors/app_exception.dart';
import 'package:rujak_pos/core/network/api_client.dart';
import 'package:rujak_pos/data/models/shift.dart';
import 'package:rujak_pos/data/repositories/shift_repository.dart';
import 'package:rujak_pos/data/shifts/shift_controller.dart';
import 'package:rujak_pos/data/sync/outbox_writer.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions request) handler;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object? data, {int status = 200}) {
  return ResponseBody.fromString(
    jsonEncode({'data': data}),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

Map<String, dynamic> _remoteShift({
  String uuid = 'shared-shift',
  String status = 'open',
  bool isClosing = false,
  int closeEpoch = 0,
  bool canFinalize = false,
}) {
  return {
    'uuid': uuid,
    'status': status,
    'is_active': true,
    'is_closing': isClosing,
    'opening_cash': 100000,
    'cash_tendered': 250000,
    'cash_change': 25000,
    'cash_in': 0,
    'cash_out': 0,
    'cash_refund': 0,
    'expected_cash': 325000,
    'confirmed_noncash': 50000,
    'awaiting_verification_amount': 0,
    'local_transaction_count': 4,
    'pending_sync_count': 0,
    'close_epoch': closeEpoch,
    'open_shift': null,
    'opened_at': '2026-11-06T08:00:00+07:00',
    'opened_by': {'uuid': 'owner-uuid', 'name': 'Owner Satu'},
    'opened_device': {
      'uuid': 'owner-device',
      'terminal_code': 'T01',
      'name': 'HP Owner',
    },
    'summary': {
      'opening_cash': 100000,
      'cash_tendered': 250000,
      'cash_change': 25000,
      'cash_in': 0,
      'cash_out': 0,
      'cash_refund': 0,
      'expected_cash': 325000,
      'confirmed_noncash': 50000,
      'awaiting_verification_amount': 0,
      'local_transaction_count': 4,
      'sale_total': 300000,
      'confirmed_amount': 300000,
      'refunded_amount': 0,
    },
    'sync': {
      'close_epoch': closeEpoch,
      'is_closing': isClosing,
      'participant_count': 2,
      'pending_device_count': isClosing ? 1 : 0,
      'can_finalize': canFinalize,
      'pending_devices': isClosing
          ? [
              {
                'device_uuid': 'cashier-device',
                'device_name': 'HP Kasir A',
                'terminal_code': 'T02',
                'user_name': 'Kasir A',
                'requires_checkpoint': true,
                'acked': false,
                'unresolved_events': 3,
                'last_sequence': 12,
              },
            ]
          : <dynamic>[],
    },
    'pending_devices': isClosing
        ? [
            {
              'device_uuid': 'cashier-device',
              'device_name': 'HP Kasir A',
              'terminal_code': 'T02',
              'user_name': 'Kasir A',
              'requires_checkpoint': true,
              'acked': false,
              'unresolved_events': 3,
              'last_sequence': 12,
            },
          ]
        : <dynamic>[],
    'can_finalize': canFinalize,
    'closing_snapshot': null,
  };
}

Future<void> _seedShift(
  AppDatabase db, {
  required String uuid,
  required String status,
  bool synced = true,
  int closeEpoch = 0,
  bool isClosing = false,
}) async {
  await db
      .into(db.localShifts)
      .insert(
        LocalShiftsCompanion.insert(
          uuid: uuid,
          status: Value(status),
          openingCash: const Value(100000),
          openedAt: DateTime(2026, 11, 6, 8),
          synced: Value(synced),
          closeEpoch: Value(closeEpoch),
          isClosing: Value(isClosing),
        ),
      );
}

void main() {
  group('shared shift status', () {
    test('only an open shift accepts transactions', () {
      final open = ShiftRecord(
        uuid: 's',
        status: 'open',
        openingCash: 0,
        openedAt: _date,
        synced: true,
      );
      final closing = ShiftRecord(
        uuid: 's',
        status: 'closing',
        openingCash: 0,
        openedAt: _date,
        synced: true,
        isClosing: true,
      );

      expect(open.isActive, isTrue);
      expect(open.acceptsTransactions, isTrue);
      expect(closing.isActive, isTrue);
      expect(closing.acceptsTransactions, isFalse);
      expect(closing.statusLabel, contains('menunggu perangkat'));
      expect(
        ShiftViewState(shift: closing).hasOpenShift,
        isFalse,
        reason: 'POS must gate on accepting transactions, not just active',
      );
    });

    test('server summary is authoritative across devices', () {
      final shift = ShiftRecord(
        uuid: 's',
        status: 'open',
        openingCash: 100000,
        openedAt: _date,
        synced: true,
        serverSummary: const ShiftServerSummary(
          openingCash: 100000,
          cashTendered: 250000,
          cashChange: 25000,
          cashIn: 5000,
          cashOut: 0,
          cashRefund: 0,
          expectedCash: 330000,
          confirmedNonCash: 50000,
          awaitingVerification: 0,
          transactionCount: 4,
          saleTotal: 300000,
        ),
      );

      final summary = ShiftSummary.fromServer(shift);
      expect(summary.fromServer, isTrue);
      expect(summary.expectedCash, 330000);
      expect(summary.transactionCount, 4);
      expect(summary.varianceFor(330000), 0);
    });

    test('pending device reason names unresolved events', () {
      const device = ShiftPendingDevice(
        deviceUuid: 'd',
        deviceName: 'HP Kasir A',
        unresolvedEvents: 3,
      );
      expect(device.displayName, 'HP Kasir A');
      expect(device.reason, contains('3 event'));
    });
  });

  group('ShiftRepository shared shift resolution', () {
    late AppDatabase db;
    late _FakeAdapter adapter;
    late ShiftRepository repository;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      adapter = _FakeAdapter((request) async => _json(_remoteShift()));
      repository = ShiftRepository(
        db,
        ApiClient(dio: Dio()..httpClientAdapter = adapter),
        OutboxWriter(db),
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('adopts the server shift and stops using a local stale shift', () async {
      await _seedShift(db, uuid: 'local-stale', status: 'open');

      final shift = await repository.refreshActiveFromServer();

      expect(shift?.uuid, 'shared-shift');
      expect(shift?.openedByName, 'Owner Satu');
      expect(shift?.openedDeviceName, 'HP Owner');
      expect(shift?.serverSummary?.expectedCash, 325000);

      final stale = await repository.byUuid('local-stale');
      expect(stale?.status, 'closed_remote');
      expect((await repository.activeShift())?.uuid, 'shared-shift');
    });

    test('marks a synced local shift closed when the server has none', () async {
      adapter = _FakeAdapter((request) async => _json(null));
      repository = ShiftRepository(
        db,
        ApiClient(dio: Dio()..httpClientAdapter = adapter),
        OutboxWriter(db),
      );
      await _seedShift(db, uuid: 'shared-shift', status: 'open');

      final shift = await repository.refreshActiveFromServer();

      expect(shift, isNull);
      expect((await repository.byUuid('shared-shift'))?.status, 'closed_remote');
      expect(await repository.activeShift(), isNull);
    });

    test('checkpoint sends the close epoch and persists finalization', () async {
      adapter = _FakeAdapter(
        (request) async => _json(
          _remoteShift(
            status: 'closed_confirmed',
            closeEpoch: 2,
          )..['is_closing'] = false
           ..['is_active'] = false,
        ),
      );
      repository = ShiftRepository(
        db,
        ApiClient(dio: Dio()..httpClientAdapter = adapter),
        OutboxWriter(db),
      );
      await _seedShift(
        db,
        uuid: 'shared-shift',
        status: 'closing',
        closeEpoch: 2,
        isClosing: true,
      );
      final shift = (await repository.byUuid('shared-shift'))!;

      final updated = await repository.checkpoint(shift);

      expect(updated.status, 'closed_confirmed');
      expect(updated.isClosing, isFalse);
      expect(adapter.requests.single.path, contains('/shifts/shared-shift/sync-checkpoint'));
      expect((adapter.requests.single.data as Map)['close_epoch'], 2);
      expect(await repository.activeShift(), isNull);
    });

    test('close is blocked locally while the outbox is not drained', () async {
      await _seedShift(db, uuid: 'shared-shift', status: 'open');
      final shift = (await repository.byUuid('shared-shift'))!;
      await db
          .into(db.outboxEvents)
          .insert(
            OutboxEventsCompanion.insert(
              eventId: 'event-1',
              eventType: 'order.created',
              aggregateType: 'order',
              aggregateId: 'order-1',
              sequence: 1,
              payloadJson: '{}',
              occurredAt: DateTime(2026, 11, 6, 9),
              createdAt: DateTime(2026, 11, 6, 9),
            ),
          );

      await expectLater(
        repository.close(
          summary: ShiftSummary(
            shift: shift,
            cashTendered: 0,
            cashChange: 0,
            cashIn: 0,
            cashOut: 0,
            cashRefund: 0,
            expectedCash: shift.openingCash,
            confirmedNonCash: 0,
            awaitingVerification: 0,
            transactionCount: 0,
            saleTotal: 0,
          ),
          actualCash: shift.openingCash,
        ),
        throwsA(
          isA<AppException>().having(
            (error) => error.code,
            'code',
            'SHIFT_DEVICE_OUTBOX_NOT_DRAINED',
          ),
        ),
      );
      expect(adapter.requests, isEmpty);
      expect((await repository.byUuid('shared-shift'))?.status, 'open');
    });

    test('close requires connectivity instead of writing a local snapshot', () async {
      adapter = _FakeAdapter((request) async {
        throw DioException.connectionError(
          requestOptions: request,
          reason: 'offline',
        );
      });
      repository = ShiftRepository(
        db,
        ApiClient(dio: Dio()..httpClientAdapter = adapter),
        OutboxWriter(db),
      );
      await _seedShift(db, uuid: 'shared-shift', status: 'open');
      final shift = (await repository.byUuid('shared-shift'))!;

      await expectLater(
        repository.close(
          summary: ShiftSummary(
            shift: shift,
            cashTendered: 0,
            cashChange: 0,
            cashIn: 0,
            cashOut: 0,
            cashRefund: 0,
            expectedCash: shift.openingCash,
            confirmedNonCash: 0,
            awaitingVerification: 0,
            transactionCount: 0,
            saleTotal: 0,
          ),
          actualCash: shift.openingCash,
        ),
        throwsA(
          isA<AppException>().having(
            (error) => error.code,
            'code',
            'SHIFT_CLOSE_REQUIRES_SYNC',
          ),
        ),
      );
      expect((await repository.byUuid('shared-shift'))?.status, 'open');
    });
  });
}

final _date = DateTime(2026, 11, 6, 8);
