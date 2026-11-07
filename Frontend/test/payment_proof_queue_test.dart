import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rujak_pos/core/database/app_database.dart';
import 'package:rujak_pos/core/network/api_client.dart';
import 'package:rujak_pos/data/services/payment_proof_queue.dart';
import 'package:rujak_pos/data/services/proof_image_service.dart';
import 'package:rujak_pos/features/payments/data/payment_api.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions request) handler;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    // Drain the multipart stream so Dio closes the file handle on Windows.
    if (requestStream != null) await requestStream.drain<void>();
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _ok() {
  return ResponseBody.fromString(
    jsonEncode({
      'data': {'uuid': 'pay-1', 'has_proof': true},
    }),
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

ResponseBody _error(int status, String code) {
  return ResponseBody.fromString(
    jsonEncode({
      'error': {'code': code, 'message': 'gagal', 'retryable': false},
    }),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

void main() {
  late AppDatabase db;
  late Directory temp;
  late _FakeAdapter adapter;
  late PaymentProofQueue queue;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    temp = Directory.systemTemp.createTempSync('proof_queue_test');
    adapter = _FakeAdapter((_) async => _ok());
    final dio = Dio()..httpClientAdapter = adapter;
    queue = PaymentProofQueue(
      db,
      PaymentApi(ApiClient(dio: dio)),
      ProofImageService(supportDirectory: () async => temp),
    );
  });

  tearDown(() async {
    await db.close();
    if (temp.existsSync()) temp.deleteSync(recursive: true);
  });

  Future<String> makeProofFile(String name) async {
    final file = File('${temp.path}/$name');
    await file.writeAsBytes([1, 2, 3, 4]);
    return file.path;
  }

  ProofUploadSeed seed(String uuid, String path) => ProofUploadSeed(
    saleUuid: 'sale-1',
    paymentUuid: uuid,
    idempotencyKey: 'key-$uuid',
    localPath: path,
  );

  Future<PaymentProofUpload> row(String uuid) {
    return (db.select(
      db.paymentProofUploads,
    )..where((item) => item.paymentUuid.equals(uuid))).getSingle();
  }

  test('enqueue is idempotent per payment', () async {
    final path = await makeProofFile('proof_a.jpg');
    await queue.enqueueAll([seed('pay-1', path)]);
    await queue.enqueueAll([seed('pay-1', path)]);

    final rows = await db.select(db.paymentProofUploads).get();
    expect(rows, hasLength(1));
    expect(rows.single.status, 'pending');
  });

  test('success marks uploaded, clears path and deletes file', () async {
    final path = await makeProofFile('proof_ok.jpg');
    await queue.enqueueAll([seed('pay-1', path)]);

    await queue.drain();

    final result = await row('pay-1');
    expect(result.status, 'uploaded');
    expect(result.localPath, isNull);
    expect(result.uploadedAt, isNotNull);
    expect(File(path).existsSync(), isFalse);
    expect(adapter.requests, hasLength(1));
    expect(
      adapter.requests.single.uri.toString(),
      contains('payments/pay-1/proof'),
    );
  });

  test(
    '404 stays pending with backoff and is not retried immediately',
    () async {
      adapter = _FakeAdapter((_) async => _error(404, 'NOT_FOUND'));
      final dio = Dio()..httpClientAdapter = adapter;
      queue = PaymentProofQueue(
        db,
        PaymentApi(ApiClient(dio: dio)),
        ProofImageService(supportDirectory: () async => temp),
      );
      final path = await makeProofFile('proof_404.jpg');
      await queue.enqueueAll([seed('pay-1', path)]);

      await queue.drain();
      final first = await row('pay-1');
      expect(first.status, 'pending');
      expect(first.attempts, 1);
      expect(first.nextAttemptAt, isNotNull);
      expect(first.nextAttemptAt!.isAfter(DateTime.now()), isTrue);
      expect(first.localPath, path);
      expect(File(path).existsSync(), isTrue);

      await queue.drain();
      expect(adapter.requests, hasLength(1));
    },
  );

  test('422 is permanent and keeps the file for investigation', () async {
    adapter = _FakeAdapter((_) async => _error(422, 'VALIDATION_FAILED'));
    final dio = Dio()..httpClientAdapter = adapter;
    queue = PaymentProofQueue(
      db,
      PaymentApi(ApiClient(dio: dio)),
      ProofImageService(supportDirectory: () async => temp),
    );
    final path = await makeProofFile('proof_422.jpg');
    await queue.enqueueAll([seed('pay-1', path)]);

    await queue.drain();

    final result = await row('pay-1');
    expect(result.status, 'failed');
    expect(result.attempts, 1);
    expect(result.lastError, contains('VALIDATION_FAILED'));
    expect(File(path).existsSync(), isTrue);
  });

  test('missing local file fails without calling the server', () async {
    await queue.enqueueAll([seed('pay-1', '${temp.path}/missing.jpg')]);

    await queue.drain();

    final result = await row('pay-1');
    expect(result.status, 'failed');
    expect(adapter.requests, isEmpty);
  });

  test('concurrent drains upload only once', () async {
    final path = await makeProofFile('proof_concurrent.jpg');
    adapter = _FakeAdapter((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return _ok();
    });
    final dio = Dio()..httpClientAdapter = adapter;
    queue = PaymentProofQueue(
      db,
      PaymentApi(ApiClient(dio: dio)),
      ProofImageService(supportDirectory: () async => temp),
    );
    await queue.enqueueAll([seed('pay-1', path)]);

    await Future.wait([queue.drain(), queue.drain()]);

    expect(adapter.requests, hasLength(1));
    expect((await row('pay-1')).status, 'uploaded');
  });

  test('exhausted retries become permanently failed', () async {
    adapter = _FakeAdapter((_) async => _error(500, 'SERVER_ERROR'));
    final dio = Dio()..httpClientAdapter = adapter;
    queue = PaymentProofQueue(
      db,
      PaymentApi(ApiClient(dio: dio)),
      ProofImageService(supportDirectory: () async => temp),
    );
    final path = await makeProofFile('proof_cap.jpg');
    await queue.enqueueAll([seed('pay-1', path)]);
    await (db.update(db.paymentProofUploads)
          ..where((item) => item.paymentUuid.equals('pay-1')))
        .write(const PaymentProofUploadsCompanion(attempts: Value(19)));

    await queue.drain();

    final result = await row('pay-1');
    expect(result.status, 'failed');
    expect(result.attempts, 20);
    expect(File(path).existsSync(), isTrue);
  });
}
