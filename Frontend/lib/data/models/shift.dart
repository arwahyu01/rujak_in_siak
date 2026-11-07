import '../../core/utils/json_utils.dart';

/// A device that still blocks shift finalization. The backend derives this
/// from checkpoint epochs and unresolved sync events, never from last seen.
class ShiftPendingDevice {
  const ShiftPendingDevice({
    required this.deviceUuid,
    this.deviceName,
    this.terminalCode,
    this.userName,
    this.requiresCheckpoint = true,
    this.acked = false,
    this.unresolvedEvents = 0,
    this.lastSequence,
    this.lastSeenAt,
  });

  final String deviceUuid;
  final String? deviceName;
  final String? terminalCode;
  final String? userName;
  final bool requiresCheckpoint;
  final bool acked;
  final int unresolvedEvents;
  final int? lastSequence;
  final DateTime? lastSeenAt;

  String get displayName {
    if (deviceName != null && deviceName!.isNotEmpty) return deviceName!;
    if (terminalCode != null && terminalCode!.isNotEmpty) return terminalCode!;
    return deviceUuid;
  }

  String get reason {
    if (unresolvedEvents > 0) {
      return '$unresolvedEvents event belum diterima server';
    }
    if (requiresCheckpoint && !acked) {
      return 'Perangkat belum mengonfirmasi sinkronisasi';
    }
    return 'Menunggu penyelesaian';
  }

  factory ShiftPendingDevice.fromJson(Map<String, dynamic> json) {
    return ShiftPendingDevice(
      deviceUuid: asStringOr(json['device_uuid'], ''),
      deviceName: asStringOrNull(json['device_name']),
      terminalCode: asStringOrNull(json['terminal_code']),
      userName: asStringOrNull(json['user_name']),
      requiresCheckpoint: asBool(json['requires_checkpoint'], true),
      acked: asBool(json['acked']),
      unresolvedEvents: asIntOr(json['unresolved_events'], 0),
      lastSequence: asIntOrNull(json['last_sequence']),
      lastSeenAt: asDate(json['last_seen_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'device_uuid': deviceUuid,
    'device_name': deviceName,
    'terminal_code': terminalCode,
    'user_name': userName,
    'requires_checkpoint': requiresCheckpoint,
    'acked': acked,
    'unresolved_events': unresolvedEvents,
    'last_sequence': lastSequence,
    'last_seen_at': lastSeenAt?.toIso8601String(),
  };
}

/// Server-authoritative shift totals across every device in the outlet.
class ShiftServerSummary {
  const ShiftServerSummary({
    required this.openingCash,
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

  final int openingCash;
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

  factory ShiftServerSummary.fromJson(Map<String, dynamic> json) {
    return ShiftServerSummary(
      openingCash: asIntOr(json['opening_cash'], 0),
      cashTendered: asIntOr(json['cash_tendered'], 0),
      cashChange: asIntOr(json['cash_change'], 0),
      cashIn: asIntOr(json['cash_in'], 0),
      cashOut: asIntOr(json['cash_out'], 0),
      cashRefund: asIntOr(json['cash_refund'], 0),
      expectedCash: asIntOr(json['expected_cash'], 0),
      confirmedNonCash: asIntOr(json['confirmed_noncash'], 0),
      awaitingVerification: asIntOr(json['awaiting_verification_amount'], 0),
      transactionCount: asIntOr(json['local_transaction_count'], 0),
      saleTotal: asIntOr(json['sale_total'], 0),
    );
  }

  Map<String, dynamic> toJson() => {
    'opening_cash': openingCash,
    'cash_tendered': cashTendered,
    'cash_change': cashChange,
    'cash_in': cashIn,
    'cash_out': cashOut,
    'cash_refund': cashRefund,
    'expected_cash': expectedCash,
    'confirmed_noncash': confirmedNonCash,
    'awaiting_verification_amount': awaitingVerification,
    'local_transaction_count': transactionCount,
    'sale_total': saleTotal,
  };
}

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
    this.closeEpoch = 0,
    this.isClosing = false,
    this.openedByName,
    this.openedDeviceName,
    this.closeActualCash,
    this.closedByName,
    this.closedDeviceName,
    this.canFinalize = false,
    this.pendingDevices = const [],
    this.serverSummary,
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
  final int closeEpoch;
  final bool isClosing;
  final String? openedByName;
  final String? openedDeviceName;
  final int? closeActualCash;
  final String? closedByName;
  final String? closedDeviceName;
  final bool canFinalize;
  final List<ShiftPendingDevice> pendingDevices;
  final ShiftServerSummary? serverSummary;

  /// Active means the shift is either accepting transactions or closing.
  bool get isActive => status == 'open' || status == 'closing';

  bool get isOpen => status == 'open';

  /// Only an open shift accepts new orders and checkouts.
  bool get acceptsTransactions => status == 'open';

  bool get isClosedPendingSync => status == 'closed_pending_sync';
  bool get isClosedConfirmed => status == 'closed_confirmed';
  bool get isClosedRemote => status == 'closed_remote';

  bool get waitingForDevices =>
      status == 'closing' && pendingDevices.isNotEmpty;

  String get statusLabel => switch (status) {
    'open' => 'Shift terbuka',
    'closing' => 'Sedang ditutup · menunggu perangkat',
    'closed_pending_sync' => 'Tutup · menunggu sinkron',
    'closed_confirmed' => 'Tutup · terkonfirmasi',
    'closed_sync_exception' => 'Tutup · perlu tindakan',
    'closed_remote' => 'Ditutup di server',
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
    int? closeEpoch,
    bool? isClosing,
    String? openedByName,
    String? openedDeviceName,
    int? closeActualCash,
    String? closedByName,
    String? closedDeviceName,
    bool? canFinalize,
    List<ShiftPendingDevice>? pendingDevices,
    ShiftServerSummary? serverSummary,
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
      closeEpoch: closeEpoch ?? this.closeEpoch,
      isClosing: isClosing ?? this.isClosing,
      openedByName: openedByName ?? this.openedByName,
      openedDeviceName: openedDeviceName ?? this.openedDeviceName,
      closeActualCash: closeActualCash ?? this.closeActualCash,
      closedByName: closedByName ?? this.closedByName,
      closedDeviceName: closedDeviceName ?? this.closedDeviceName,
      canFinalize: canFinalize ?? this.canFinalize,
      pendingDevices: pendingDevices ?? this.pendingDevices,
      serverSummary: serverSummary ?? this.serverSummary,
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
    this.fromServer = false,
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

  /// True when the totals cover every device in the outlet, not just this one.
  final bool fromServer;

  int varianceFor(int actualCash) => actualCash - expectedCash;

  factory ShiftSummary.fromServer(ShiftRecord shift) {
    final server = shift.serverSummary;
    if (server == null) {
      return ShiftSummary(
        shift: shift,
        cashTendered: 0,
        cashChange: 0,
        cashIn: 0,
        cashOut: 0,
        cashRefund: 0,
        expectedCash: shift.expectedCash ?? shift.openingCash,
        confirmedNonCash: 0,
        awaitingVerification: 0,
        transactionCount: 0,
        saleTotal: 0,
        fromServer: true,
      );
    }
    return ShiftSummary(
      shift: shift,
      cashTendered: server.cashTendered,
      cashChange: server.cashChange,
      cashIn: server.cashIn,
      cashOut: server.cashOut,
      cashRefund: server.cashRefund,
      expectedCash: server.expectedCash,
      confirmedNonCash: server.confirmedNonCash,
      awaitingVerification: server.awaitingVerification,
      transactionCount: server.transactionCount,
      saleTotal: server.saleTotal,
      fromServer: true,
    );
  }
}
