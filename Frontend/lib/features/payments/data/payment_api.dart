import '../../../core/network/api_client.dart';
import '../../../core/utils/json_utils.dart';

class PendingPayment {
  const PendingPayment({
    required this.uuid,
    required this.method,
    required this.amount,
    required this.status,
    this.saleUuid,
    this.receiptNumber,
    this.providerReference,
    this.notes,
    this.recordedByName,
    this.recordedByUuid,
    this.recordedAt,
  });

  final String uuid;
  final String? saleUuid;
  final String? receiptNumber;
  final String method;
  final int amount;
  final String status;
  final String? providerReference;
  final String? notes;
  final String? recordedByName;
  final String? recordedByUuid;
  final DateTime? recordedAt;

  factory PendingPayment.fromJson(Map<String, dynamic> json) {
    final recordedBy = asMapOrNull(json['recorded_by']);
    return PendingPayment(
      uuid: asStringOr(json['uuid'], ''),
      saleUuid: asStringOrNull(json['sale_uuid']),
      receiptNumber: asStringOrNull(json['receipt_number']),
      method: asStringOr(json['method'], 'transfer'),
      amount: asIntOr(json['amount'], 0),
      status: asStringOr(json['status'], 'awaiting_verification'),
      providerReference: asStringOrNull(json['provider_reference']),
      notes: asStringOrNull(json['notes']),
      recordedByName: recordedBy == null
          ? null
          : asStringOrNull(recordedBy['name']),
      recordedByUuid: recordedBy == null
          ? null
          : asStringOrNull(recordedBy['uuid']),
      recordedAt: asDate(json['recorded_at']),
    );
  }
}

class PaymentApi {
  PaymentApi(this._api);

  final ApiClient _api;

  Future<List<PendingPayment>> pending() async {
    final result = await _api.get(
      'payments/pending-verification',
      query: {'per_page': 100},
    );
    return asMapList(
      result.data,
    ).map(PendingPayment.fromJson).toList(growable: false);
  }

  Future<void> verify(
    String uuid, {
    required int verifiedAmount,
    String? providerReference,
    String? note,
  }) async {
    await _api.post(
      'payments/$uuid/verify',
      body: {
        'verified_amount': verifiedAmount,
        if (providerReference != null && providerReference.trim().isNotEmpty)
          'provider_reference': providerReference.trim(),
        if (note != null && note.trim().isNotEmpty)
          'verification_note': note.trim(),
      },
    );
  }

  Future<void> reject(String uuid, {required String reason}) async {
    await _api.post('payments/$uuid/reject', body: {'reason': reason.trim()});
  }
}
