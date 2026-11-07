import 'package:flutter_test/flutter_test.dart';
import 'package:rujak_pos/data/models/sale.dart';
import 'package:rujak_pos/data/services/proof_matcher.dart';

const _draftQris = LocalPaymentDraft(
  method: 'qris',
  amount: 10000,
  providerReference: 'QR-1',
  proofPath: '/tmp/qris.jpg',
);
const _draftTransfer = LocalPaymentDraft(
  method: 'transfer',
  amount: 5000,
  providerReference: 'TRX-1',
  proofPath: '/tmp/transfer.jpg',
);

SalePaymentRecord _serverPayment({
  required String uuid,
  required String method,
  String? key,
}) {
  return SalePaymentRecord(
    uuid: uuid,
    method: method,
    amount: 10000,
    status: 'awaiting_verification',
    idempotencyKey: key,
  );
}

void main() {
  test('matches drafts by idempotency key even when order differs', () {
    final seeds = matchProofUploads(
      saleUuid: 'sale-1',
      drafts: [_draftQris, _draftTransfer],
      paymentKeys: ['key-qris', 'key-transfer'],
      payments: [
        _serverPayment(
          uuid: 'pay-transfer',
          method: 'transfer',
          key: 'key-transfer',
        ),
        _serverPayment(uuid: 'pay-qris', method: 'qris', key: 'key-qris'),
      ],
    );

    expect(seeds, hasLength(2));
    expect(seeds[0].paymentUuid, 'pay-qris');
    expect(seeds[0].localPath, '/tmp/qris.jpg');
    expect(seeds[1].paymentUuid, 'pay-transfer');
  });

  test('falls back to non-cash order when server omits keys', () {
    final seeds = matchProofUploads(
      saleUuid: 'sale-1',
      drafts: [_draftQris, _draftTransfer],
      paymentKeys: ['key-qris', 'key-transfer'],
      payments: [
        _serverPayment(uuid: 'pay-qris', method: 'qris'),
        _serverPayment(uuid: 'pay-transfer', method: 'transfer'),
      ],
    );

    expect(seeds.map((seed) => seed.paymentUuid), ['pay-qris', 'pay-transfer']);
  });

  test('ignores cash payments and drafts without proof', () {
    final seeds = matchProofUploads(
      saleUuid: 'sale-1',
      drafts: const [
        LocalPaymentDraft(method: 'cash', amount: 10000),
        _draftQris,
        LocalPaymentDraft(
          method: 'transfer',
          amount: 5000,
          providerReference: 'TRX-1',
        ),
      ],
      paymentKeys: ['key-cash', 'key-qris', 'key-transfer'],
      payments: [
        _serverPayment(uuid: 'pay-cash', method: 'cash'),
        _serverPayment(uuid: 'pay-qris', method: 'qris', key: 'key-qris'),
        _serverPayment(
          uuid: 'pay-transfer',
          method: 'transfer',
          key: 'key-transfer',
        ),
      ],
    );

    expect(seeds, hasLength(1));
    expect(seeds.single.paymentUuid, 'pay-qris');
  });

  test('split non-cash payments each get their own queue row', () {
    final seeds = matchProofUploads(
      saleUuid: 'sale-1',
      drafts: [_draftQris, _draftTransfer],
      paymentKeys: ['key-qris', 'key-transfer'],
      payments: [
        _serverPayment(uuid: 'pay-qris', method: 'qris', key: 'key-qris'),
        _serverPayment(
          uuid: 'pay-transfer',
          method: 'transfer',
          key: 'key-transfer',
        ),
      ],
    );

    expect(seeds.map((seed) => seed.paymentUuid).toSet(), {
      'pay-qris',
      'pay-transfer',
    });
    expect(seeds.map((seed) => seed.saleUuid).toSet(), {'sale-1'});
  });

  test('does not reuse a server payment when proof drafts exceed matches', () {
    final seeds = matchProofUploads(
      saleUuid: 'sale-1',
      drafts: [_draftQris, _draftTransfer],
      paymentKeys: ['key-qris', 'key-transfer'],
      payments: [_serverPayment(uuid: 'pay-qris', method: 'qris')],
    );

    expect(seeds, hasLength(1));
    expect(seeds.single.paymentUuid, 'pay-qris');
  });
}
