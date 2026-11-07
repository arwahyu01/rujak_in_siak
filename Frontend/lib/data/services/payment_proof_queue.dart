import 'dart:io';
import 'dart:math' as math;

import 'package:drift/drift.dart';

import '../../core/database/app_database.dart';
import '../../core/errors/app_exception.dart';
import '../../features/payments/data/payment_api.dart';
import 'proof_image_service.dart';

class ProofUploadSeed {
  const ProofUploadSeed({
    required this.saleUuid,
    required this.paymentUuid,
    required this.localPath,
    this.idempotencyKey,
  });

  final String saleUuid;
  final String paymentUuid;
  final String? idempotencyKey;
  final String localPath;
}

class PaymentProofQueue {
  PaymentProofQueue(this._db, this._api, this._images);

  static const _maxAttempts = 20;
  static const _batchSize = 20;
  static const _backoff = [
    Duration(minutes: 1),
    Duration(minutes: 5),
    Duration(minutes: 15),
    Duration(hours: 1),
    Duration(hours: 6),
  ];

  final AppDatabase _db;
  final PaymentApi _api;
  final ProofImageService _images;
  bool _draining = false;

  Future<void> enqueueAll(Iterable<ProofUploadSeed> seeds) async {
    final now = DateTime.now();
    for (final seed in seeds) {
      if (seed.localPath.isEmpty) continue;
      await _db
          .into(_db.paymentProofUploads)
          .insert(
            PaymentProofUploadsCompanion.insert(
              saleUuid: seed.saleUuid,
              paymentUuid: seed.paymentUuid,
              idempotencyKey: Value(seed.idempotencyKey),
              localPath: Value(seed.localPath),
              createdAt: now,
              updatedAt: now,
            ),
            mode: InsertMode.insertOrIgnore,
          );
    }
  }

  Future<void> drain() async {
    if (_draining) return;
    _draining = true;
    try {
      await _sweepOrphans();
      final rows = await (_db.select(
        _db.paymentProofUploads,
      )..where((row) => row.status.equals('pending'))).get();
      final now = DateTime.now();
      final due = rows
          .where(
            (row) =>
                row.nextAttemptAt == null || !row.nextAttemptAt!.isAfter(now),
          )
          .take(_batchSize);
      for (final row in due) {
        await _process(row);
      }
    } catch (_) {
      // Uploading is background work and must never surface to the cashier.
    } finally {
      _draining = false;
    }
  }

  Future<void> _process(PaymentProofUpload row) async {
    final path = row.localPath;
    if (path == null || path.isEmpty || !await File(path).exists()) {
      await _markFailed(row, 'File bukti tidak ditemukan.');
      return;
    }

    try {
      await _api.uploadProof(row.paymentUuid, path);
      await (_db.update(
        _db.paymentProofUploads,
      )..where((item) => item.id.equals(row.id))).write(
        PaymentProofUploadsCompanion(
          status: const Value('uploaded'),
          localPath: const Value(null),
          lastError: const Value(null),
          nextAttemptAt: const Value(null),
          uploadedAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      );
      await _images.delete(path);
    } on AppException catch (error) {
      if (_isPermanent(error)) {
        await _markFailed(row, '${error.code}: ${error.message}');
      } else {
        await _markRetry(row, error);
      }
    } catch (error) {
      await _markRetry(row, AppException.unknown(error));
    }
  }

  bool _isPermanent(AppException error) {
    final status = error.statusCode;
    return status == 403 || status == 413 || status == 422;
  }

  Future<void> _markRetry(PaymentProofUpload row, AppException error) async {
    final attempts = row.attempts + 1;
    final now = DateTime.now();
    if (attempts >= _maxAttempts) {
      await _markFailed(row, '${error.code}: ${error.message}');
      return;
    }
    final delay = _backoff[math.min(attempts - 1, _backoff.length - 1)];
    await (_db.update(
      _db.paymentProofUploads,
    )..where((item) => item.id.equals(row.id))).write(
      PaymentProofUploadsCompanion(
        status: const Value('pending'),
        attempts: Value(attempts),
        lastError: Value('${error.code}: ${error.message}'),
        nextAttemptAt: Value(now.add(delay)),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> _markFailed(PaymentProofUpload row, String message) async {
    await (_db.update(
      _db.paymentProofUploads,
    )..where((item) => item.id.equals(row.id))).write(
      PaymentProofUploadsCompanion(
        status: const Value('failed'),
        attempts: Value(row.attempts + 1),
        lastError: Value(message),
        nextAttemptAt: const Value(null),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> _sweepOrphans() async {
    final rows = await (_db.select(
      _db.paymentProofUploads,
    )..where((row) => row.localPath.isNotNull())).get();
    final referenced = rows
        .map((row) => row.localPath)
        .whereType<String>()
        .toSet();
    await _images.sweepOrphans(referenced);
  }
}
