class ShiftRecord {
  const ShiftRecord({
    required this.uuid,
    required this.status,
    required this.openingCash,
    required this.openedAt,
    required this.synced,
    this.openingNotes,
    this.closedAt,
    this.expectedCash,
    this.actualCash,
    this.difference,
    this.closingNotes,
  });

  final String uuid;
  final String status;
  final int openingCash;
  final String? openingNotes;
  final DateTime openedAt;
  final DateTime? closedAt;
  final int? expectedCash;
  final int? actualCash;
  final int? difference;
  final String? closingNotes;
  final bool synced;

  bool get isOpen => status == 'open';
  bool get isClosedPendingSync => status == 'closed_pending_sync';
  bool get isClosedConfirmed => status == 'closed_confirmed';

  String get statusLabel => switch (status) {
    'open' => 'Shift terbuka',
    'closed_pending_sync' => 'Tutup · menunggu sinkron',
    'closed_confirmed' => 'Tutup · terkonfirmasi',
    'closed_sync_exception' => 'Tutup · perlu tindakan',
    _ => status,
  };

  ShiftRecord copyWith({
    String? status,
    DateTime? closedAt,
    int? expectedCash,
    int? actualCash,
    int? difference,
    String? closingNotes,
    bool? synced,
  }) {
    return ShiftRecord(
      uuid: uuid,
      status: status ?? this.status,
      openingCash: openingCash,
      openingNotes: openingNotes,
      openedAt: openedAt,
      closedAt: closedAt ?? this.closedAt,
      expectedCash: expectedCash ?? this.expectedCash,
      actualCash: actualCash ?? this.actualCash,
      difference: difference ?? this.difference,
      closingNotes: closingNotes ?? this.closingNotes,
      synced: synced ?? this.synced,
    );
  }
}

class ShiftSummary {
  const ShiftSummary({
    required this.shift,
    required this.cashTendered,
    required this.cashChange,
    required this.cashIn,
    required this.cashOut,
    required this.cashRefund,
    required this.expectedCash,
    required this.confirmedNonCash,
    required this.awaitingVerification,
    required this.transactionCount,
    required this.saleTotal,
  });

  final ShiftRecord shift;
  final int cashTendered;
  final int cashChange;
  final int cashIn;
  final int cashOut;
  final int cashRefund;
  final int expectedCash;
  final int confirmedNonCash;
  final int awaitingVerification;
  final int transactionCount;
  final int saleTotal;

  int varianceFor(int actualCash) => actualCash - expectedCash;
}
