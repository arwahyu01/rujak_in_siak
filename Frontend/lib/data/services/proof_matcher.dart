import '../models/sale.dart';
import 'payment_proof_queue.dart';

List<ProofUploadSeed> matchProofUploads({
  required String saleUuid,
  required List<LocalPaymentDraft> drafts,
  required List<String> paymentKeys,
  required List<SalePaymentRecord> payments,
}) {
  final candidates = payments
      .where(
        (payment) =>
            payment.method != 'cash' &&
            payment.uuid != null &&
            payment.uuid!.isNotEmpty,
      )
      .toList(growable: false);
  final used = <String>{};
  final seeds = <ProofUploadSeed>[];

  for (var index = 0; index < drafts.length; index++) {
    final draft = drafts[index];
    if (draft.isCash || draft.proofPath == null) continue;
    final key = paymentKeys[index];

    SalePaymentRecord? match;
    for (final candidate in candidates) {
      if (used.contains(candidate.uuid)) continue;
      if (candidate.idempotencyKey == key) {
        match = candidate;
        break;
      }
    }
    match ??= _firstUnused(candidates, used, method: draft.method);
    match ??= _firstUnused(candidates, used);
    if (match?.uuid == null) continue;

    used.add(match!.uuid!);
    seeds.add(
      ProofUploadSeed(
        saleUuid: saleUuid,
        paymentUuid: match.uuid!,
        idempotencyKey: key,
        localPath: draft.proofPath!,
      ),
    );
  }

  return seeds;
}

SalePaymentRecord? _firstUnused(
  List<SalePaymentRecord> candidates,
  Set<String> used, {
  String? method,
}) {
  for (final candidate in candidates) {
    if (used.contains(candidate.uuid)) continue;
    if (method != null && candidate.method != method) continue;
    return candidate;
  }
  return null;
}
