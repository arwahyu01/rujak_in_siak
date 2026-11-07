import '../../core/utils/json_utils.dart';

class SaleItemRecord {
  const SaleItemRecord({
    required this.productName,
    this.uuid,
    this.productUuid,
    this.variantName,
    this.addonsSummary,
    this.quantity = 1,
    this.unitPrice = 0,
    this.discountAmount = 0,
    this.taxAmount = 0,
    this.lineTotal = 0,
    this.notes,
  });

  final String? uuid;
  final String? productUuid;
  final String productName;
  final String? variantName;
  final String? addonsSummary;
  final int quantity;
  final int unitPrice;
  final int discountAmount;
  final int taxAmount;
  final int lineTotal;
  final String? notes;

  factory SaleItemRecord.fromServer(Map<String, dynamic> json) {
    return SaleItemRecord(
      uuid: asStringOrNull(json['uuid']),
      productUuid: asStringOrNull(json['product_uuid']),
      productName: asStringOr(json['product_name'], 'Produk'),
      variantName: asStringOrNull(json['variant_name']),
      addonsSummary: asStringOrNull(json['addon_summary']),
      quantity: asIntOr(json['quantity'], 1),
      unitPrice: asIntOr(json['unit_price'], 0),
      discountAmount: asIntOr(json['discount_amount'], 0),
      taxAmount: asIntOr(json['tax_amount'], 0),
      lineTotal: asIntOr(json['total'], 0),
    );
  }
}

class SalePaymentRecord {
  const SalePaymentRecord({
    required this.method,
    required this.amount,
    required this.status,
    this.uuid,
    this.tenderedAmount,
    this.changeAmount = 0,
    this.providerReference,
    this.idempotencyKey,
    this.notes,
    this.recordedAt,
  });

  final String? uuid;
  final String method;
  final int amount;
  final int? tenderedAmount;
  final int changeAmount;
  final String status;
  final String? providerReference;
  final String? idempotencyKey;
  final String? notes;
  final DateTime? recordedAt;

  bool get isConfirmed => status == 'confirmed';
  bool get isAwaiting => status == 'awaiting_verification';

  factory SalePaymentRecord.fromServer(Map<String, dynamic> json) {
    return SalePaymentRecord(
      uuid: asStringOrNull(json['uuid']),
      method: asStringOr(json['method'], 'cash'),
      amount: asIntOr(json['amount'], 0),
      tenderedAmount: asIntOrNull(json['tendered_amount']),
      changeAmount: asIntOr(json['change_amount'], 0),
      status: asStringOr(json['status'], 'recorded'),
      providerReference: asStringOrNull(json['provider_reference']),
      idempotencyKey: asStringOrNull(json['idempotency_key']),
      notes: asStringOrNull(json['notes']),
      recordedAt: asDate(json['recorded_at']),
    );
  }
}

class LocalPaymentDraft {
  const LocalPaymentDraft({
    required this.method,
    required this.amount,
    this.tenderedAmount,
    this.providerReference,
    this.notes,
    this.idempotencyKey,
    this.proofPath,
    this.ownerConfirmed = false,
  });

  final String method;
  final int amount;
  final int? tenderedAmount;
  final String? providerReference;
  final String? notes;
  final String? idempotencyKey;
  final String? proofPath;
  final bool ownerConfirmed;

  bool get isCash => method == 'cash';

  int get changeAmount {
    if (!isCash) return 0;
    final tendered = tenderedAmount ?? amount;
    return tendered > amount ? tendered - amount : 0;
  }

  String get status =>
      isCash || ownerConfirmed ? 'confirmed' : 'awaiting_verification';

  Map<String, dynamic> toCheckoutJson(String idempotencyKey) => {
    'method': method,
    'amount': amount,
    if (isCash) 'tendered_amount': tenderedAmount ?? amount,
    if (providerReference != null && providerReference!.isNotEmpty)
      'provider_reference': providerReference,
    if (notes != null && notes!.isNotEmpty) 'notes': notes,
    'idempotency_key': idempotencyKey,
  };
}

class SaleRecord {
  const SaleRecord({
    required this.uuid,
    required this.receiptNumber,
    required this.orderType,
    required this.lifecycleStatus,
    required this.paymentStatus,
    required this.subtotal,
    required this.itemDiscountTotal,
    required this.transactionDiscountTotal,
    required this.discountTotal,
    required this.serviceCharge,
    required this.taxTotal,
    required this.total,
    required this.confirmedAmount,
    required this.awaitingAmount,
    required this.outstandingAmount,
    required this.refundedAmount,
    required this.transactedAt,
    this.orderUuid,
    this.sourceOrderVersion,
    this.origin = 'online',
    this.tableNumber,
    this.notes,
    this.shiftUuid,
    this.cashierName,
    this.synced = true,
    this.createdAt,
    this.items = const [],
    this.payments = const [],
  });

  final String uuid;
  final String receiptNumber;
  final String? orderUuid;
  final int? sourceOrderVersion;
  final String origin;
  final String orderType;
  final String? tableNumber;
  final String lifecycleStatus;
  final String paymentStatus;
  final int subtotal;
  final int itemDiscountTotal;
  final int transactionDiscountTotal;
  final int discountTotal;
  final int serviceCharge;
  final int taxTotal;
  final int total;
  final int confirmedAmount;
  final int awaitingAmount;
  final int outstandingAmount;
  final int refundedAmount;
  final String? shiftUuid;
  final String? cashierName;
  final String? notes;
  final bool synced;
  final DateTime transactedAt;
  final DateTime? createdAt;
  final List<SaleItemRecord> items;
  final List<SalePaymentRecord> payments;

  bool get isVoided => lifecycleStatus == 'voided';
  bool get isOffline => origin == 'offline';
  bool get hasAwaitingPayment =>
      awaitingAmount > 0 || paymentStatus == 'awaiting_verification';

  String get paymentStatusLabel => switch (paymentStatus) {
    'paid' => 'Lunas',
    'partially_paid' => 'Dibayar sebagian',
    'awaiting_verification' => 'Menunggu verifikasi',
    'partially_refunded' => 'Refund sebagian',
    'refunded' => 'Refund',
    'cancelled' => 'Dibatalkan',
    _ => 'Belum dibayar',
  };

  factory SaleRecord.fromServer(Map<String, dynamic> json) {
    final shift = asMapOrNull(json['shift']);
    final cashier = asMapOrNull(json['cashier']);
    final transactedAt = asDate(json['transacted_at']) ?? DateTime.now();
    return SaleRecord(
      uuid: asStringOr(json['uuid'], ''),
      receiptNumber: asStringOr(json['receipt_number'], ''),
      orderUuid: asStringOrNull(json['source_order_uuid']),
      sourceOrderVersion: asIntOrNull(json['source_order_version']),
      origin: asStringOr(json['origin'], 'online'),
      orderType: asStringOr(json['order_type'], 'dine_in'),
      tableNumber: asStringOrNull(json['table_number']),
      lifecycleStatus: asStringOr(json['lifecycle_status'], 'finalized'),
      paymentStatus: asStringOr(json['payment_status'], 'unpaid'),
      subtotal: asIntOr(json['subtotal'], 0),
      itemDiscountTotal: asIntOr(json['item_discount_total'], 0),
      transactionDiscountTotal: asIntOr(json['transaction_discount_total'], 0),
      discountTotal: asIntOr(json['discount_total'], 0),
      serviceCharge: asIntOr(json['service_charge'], 0),
      taxTotal: asIntOr(json['tax_total'], 0),
      total: asIntOr(json['total'], 0),
      confirmedAmount: asIntOr(json['confirmed_amount'], 0),
      awaitingAmount: asIntOr(json['awaiting_verification_amount'], 0),
      outstandingAmount: asIntOr(json['outstanding_amount'], 0),
      refundedAmount: asIntOr(json['refunded_amount'], 0),
      shiftUuid: shift == null ? null : asStringOrNull(shift['uuid']),
      cashierName: cashier == null ? null : asStringOrNull(cashier['name']),
      notes: asStringOrNull(json['notes']),
      synced: true,
      transactedAt: transactedAt,
      createdAt: asDate(json['created_at']),
      items: asMapList(
        json['items'],
      ).map(SaleItemRecord.fromServer).toList(growable: false),
      payments: asMapList(
        json['payments'],
      ).map(SalePaymentRecord.fromServer).toList(growable: false),
    );
  }

  SaleRecord copyWith({
    String? paymentStatus,
    int? confirmedAmount,
    int? awaitingAmount,
    int? outstandingAmount,
    int? refundedAmount,
    bool? synced,
    List<SalePaymentRecord>? payments,
    List<SaleItemRecord>? items,
  }) {
    return SaleRecord(
      uuid: uuid,
      receiptNumber: receiptNumber,
      orderUuid: orderUuid,
      sourceOrderVersion: sourceOrderVersion,
      origin: origin,
      orderType: orderType,
      tableNumber: tableNumber,
      lifecycleStatus: lifecycleStatus,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      subtotal: subtotal,
      itemDiscountTotal: itemDiscountTotal,
      transactionDiscountTotal: transactionDiscountTotal,
      discountTotal: discountTotal,
      serviceCharge: serviceCharge,
      taxTotal: taxTotal,
      total: total,
      confirmedAmount: confirmedAmount ?? this.confirmedAmount,
      awaitingAmount: awaitingAmount ?? this.awaitingAmount,
      outstandingAmount: outstandingAmount ?? this.outstandingAmount,
      refundedAmount: refundedAmount ?? this.refundedAmount,
      shiftUuid: shiftUuid,
      cashierName: cashierName,
      notes: notes,
      synced: synced ?? this.synced,
      transactedAt: transactedAt,
      createdAt: createdAt,
      items: items ?? this.items,
      payments: payments ?? this.payments,
    );
  }
}
