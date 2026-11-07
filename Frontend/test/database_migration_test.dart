import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rujak_pos/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  test('schema version includes the proof upload queue', () {
    expect(db.schemaVersion, 4);
  });

  test('proof upload rows can be inserted and queried', () async {
    final now = DateTime(2026, 11, 7, 10);
    await db
        .into(db.paymentProofUploads)
        .insert(
          PaymentProofUploadsCompanion.insert(
            saleUuid: 'sale-1',
            paymentUuid: 'pay-1',
            idempotencyKey: const Value('key-1'),
            localPath: const Value('/data/proof_1.jpg'),
            createdAt: now,
            updatedAt: now,
          ),
        );

    final row = await db.select(db.paymentProofUploads).getSingle();
    expect(row.saleUuid, 'sale-1');
    expect(row.paymentUuid, 'pay-1');
    expect(row.status, 'pending');
    expect(row.attempts, 0);
  });

  test('payment uuid is unique per queue row', () async {
    Future<void> insert(String paymentUuid) {
      final now = DateTime(2026, 11, 7, 10);
      return db
          .into(db.paymentProofUploads)
          .insert(
            PaymentProofUploadsCompanion.insert(
              saleUuid: 'sale-1',
              paymentUuid: paymentUuid,
              createdAt: now,
              updatedAt: now,
            ),
          );
    }

    await insert('pay-1');
    await expectLater(insert('pay-1'), throwsA(anything));
    expect(await db.select(db.paymentProofUploads).get(), hasLength(1));
  });
}
