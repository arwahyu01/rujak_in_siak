import 'dart:async';
import 'dart:convert';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:drift/drift.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/services.dart';

import '../../core/database/app_database.dart';
import '../../core/errors/app_exception.dart';
import '../../core/format/dates.dart';
import '../../core/format/money.dart';
import '../models/catalog.dart';
import '../models/sale.dart';
import 'bluetooth_permissions.dart';

enum AutoPrintMode {
  all,
  cashOnly,
  manual;

  static AutoPrintMode fromName(String? value) => switch (value) {
    'cashOnly' => AutoPrintMode.cashOnly,
    'manual' => AutoPrintMode.manual,
    _ => AutoPrintMode.all,
  };

  String get label => switch (this) {
    AutoPrintMode.all => 'Semua transaksi',
    AutoPrintMode.cashOnly => 'Hanya tunai',
    AutoPrintMode.manual => 'Manual',
  };
}

class PrinterConfig {
  const PrinterConfig({
    this.autoPrintMode = AutoPrintMode.all,
    this.compact = false,
    this.name,
    this.address,
    this.paperWidth = 58,
  });

  final AutoPrintMode autoPrintMode;
  final bool compact;
  final String? name;
  final String? address;
  final int paperWidth;

  bool get hasAddress => address != null && address!.trim().isNotEmpty;

  bool get configured => hasAddress;

  bool shouldAutoPrint({required bool hasAwaitingPayment}) =>
      switch (autoPrintMode) {
        AutoPrintMode.all => true,
        AutoPrintMode.cashOnly => !hasAwaitingPayment,
        AutoPrintMode.manual => false,
      };

  PrinterConfig copyWith({
    AutoPrintMode? autoPrintMode,
    bool? compact,
    String? name,
    String? address,
    int? paperWidth,
  }) {
    return PrinterConfig(
      autoPrintMode: autoPrintMode ?? this.autoPrintMode,
      compact: compact ?? this.compact,
      name: name ?? this.name,
      address: address ?? this.address,
      paperWidth: paperWidth ?? this.paperWidth,
    );
  }

  factory PrinterConfig.fromJson(Map<String, dynamic> json) {
    // Configs written before auto-print modes stored only `enabled`.
    final mode = json.containsKey('auto_print_mode')
        ? AutoPrintMode.fromName(json['auto_print_mode'] as String?)
        : json['enabled'] == false
        ? AutoPrintMode.manual
        : AutoPrintMode.all;
    return PrinterConfig(
      autoPrintMode: mode,
      compact: json['compact'] == true,
      name: json['name'] as String?,
      address: json['address'] as String?,
      paperWidth: json['paper_width'] is num
          ? (json['paper_width'] as num).toInt()
          : 58,
    );
  }

  Map<String, dynamic> toJson() => {
    'auto_print_mode': autoPrintMode.name,
    'compact': compact,
    'name': name,
    'address': address,
    'paper_width': paperWidth,
  };
}

class PrintJobSummary {
  const PrintJobSummary({
    required this.id,
    required this.saleUuid,
    required this.receiptNumber,
    required this.status,
    required this.attempts,
    required this.createdAt,
    this.lastError,
  });

  final int id;
  final String saleUuid;
  final String receiptNumber;
  final String status;
  final int attempts;
  final DateTime createdAt;
  final String? lastError;
}

class ReceiptLayout {
  const ReceiptLayout._();

  static int charsPerLine(int paperWidth) => switch (paperWidth) {
    72 => 42,
    80 => 48,
    _ => 32,
  };

  static List<String> transactionHeading({
    required String receiptNumber,
    required bool isVoided,
    required bool hasAwaitingPayment,
    required int paperWidth,
  }) {
    final label = isVoided
        ? 'VOID'
        : hasAwaitingPayment
        ? 'MENUNGGU VERIFIKASI PEMBAYARAN'
        : 'LUNAS';
    final combined = '$label · $receiptNumber';
    if (label != 'MENUNGGU VERIFIKASI PEMBAYARAN' &&
        combined.length <= charsPerLine(paperWidth)) {
      return [combined];
    }
    return [label, receiptNumber];
  }

  static List<String> itemLines({
    required String label,
    required String amount,
    required int paperWidth,
  }) {
    final width = charsPerLine(paperWidth);
    if (amount.length >= width - 2) {
      return [...wrapWords(label, width), ...wrapWords(amount, width)];
    }
    if (label.length + amount.length + 1 <= width) {
      return [_padLine(label, amount, width)];
    }
    final budget = width - amount.length - 1;
    if (budget <= 2) {
      return [...wrapWords(label, width), amount.padLeft(width)];
    }
    final (first, rest) = _splitAtWord(label, budget);
    return [
      _padLine(first, amount, width),
      if (rest.isNotEmpty) ...wrapWords(rest, width),
    ];
  }

  static String _padLine(String label, String amount, int width) {
    final padding = width - label.length - amount.length;
    return '$label${' ' * (padding < 1 ? 1 : padding)}$amount';
  }

  static (String, String) _splitAtWord(String text, int budget) {
    if (text.length <= budget) return (text, '');
    final space = text.lastIndexOf(' ', budget);
    final cut = space <= 0 ? budget : space;
    return (text.substring(0, cut).trimRight(), text.substring(cut).trimLeft());
  }

  static List<String> wrapWords(String text, int width) {
    final lines = <String>[];
    var current = '';
    for (var word in text.split(RegExp(r'\s+'))) {
      if (word.isEmpty) continue;
      while (word.length > width) {
        if (current.isNotEmpty) {
          lines.add(current);
          current = '';
        }
        lines.add(word.substring(0, width));
        word = word.substring(width);
      }
      if (current.isEmpty) {
        current = word;
      } else if (current.length + 1 + word.length <= width) {
        current = '$current $word';
      } else {
        lines.add(current);
        current = word;
      }
    }
    if (current.isNotEmpty) lines.add(current);
    return lines;
  }
}

class PrinterService {
  PrinterService(this._db);

  static const _configKey = 'printer_config';
  static const _shortTimeout = Duration(seconds: 5);
  static const _listTimeout = Duration(seconds: 10);
  static const _connectTimeout = Duration(seconds: 15);
  static const _writeTimeout = Duration(seconds: 20);

  final AppDatabase _db;

  Future<PrinterConfig> loadConfig() async {
    final raw = await _db.setting(_configKey);
    if (raw == null || raw.isEmpty) return const PrinterConfig();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const PrinterConfig();
      return PrinterConfig.fromJson(decoded.cast<String, dynamic>());
    } catch (_) {
      return const PrinterConfig();
    }
  }

  Future<void> saveConfig(PrinterConfig config) {
    return _db.putSetting(_configKey, jsonEncode(config.toJson()));
  }

  Future<List<BluetoothDevice>> bondedDevices() async {
    await _ensureBluetoothPermission();
    try {
      return await BlueThermalPrinter.instance.getBondedDevices().timeout(
        _listTimeout,
      );
    } on TimeoutException {
      throw const AppException(
        'BLUETOOTH_TIMEOUT',
        'Daftar perangkat Bluetooth tidak merespons. Muat ulang halaman '
            'atau periksa izin Bluetooth aplikasi.',
      );
    } on PlatformException catch (error) {
      throw AppException(
        'BLUETOOTH_ERROR',
        _bluetoothMessage(
          error,
          'Tidak dapat membaca perangkat Bluetooth. Pastikan izin Bluetooth '
          'diberikan pada aplikasi.',
        ),
      );
    }
  }

  Future<bool> isBluetoothOn() async {
    await _ensureBluetoothPermission();
    try {
      return await BlueThermalPrinter.instance.isOn.timeout(_shortTimeout) ??
          false;
    } on TimeoutException {
      throw const AppException(
        'BLUETOOTH_TIMEOUT',
        'Status Bluetooth tidak merespons. Coba muat ulang halaman.',
      );
    } on PlatformException catch (error) {
      throw AppException(
        'BLUETOOTH_ERROR',
        _bluetoothMessage(error, 'Status Bluetooth tidak dapat dibaca.'),
      );
    }
  }

  Future<bool> isConnectedTo(PrinterConfig config) async {
    if (!config.hasAddress) return false;
    await _ensureBluetoothPermission();
    try {
      final connected = await BlueThermalPrinter.instance
          .isDeviceConnected(BluetoothDevice(config.name, config.address))
          .timeout(_shortTimeout);
      return connected == true;
    } on TimeoutException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> _ensureBluetoothPermission() async {
    final granted = await BluetoothPermissions.ensure();
    if (!granted) {
      throw const AppException(
        'BLUETOOTH_PERMISSION',
        'Izin Bluetooth diperlukan untuk mencetak. Aktifkan izin Bluetooth '
            'untuk aplikasi ini di pengaturan Android.',
      );
    }
  }

  Future<void> connect(PrinterConfig config) async {
    if (!config.hasAddress) {
      throw const AppException(
        'PRINTER_NOT_CONFIGURED',
        'Printer belum dipilih. Atur printer Bluetooth di menu Pengaturan.',
      );
    }
    await _ensureBluetoothPermission();
    final bluetooth = BlueThermalPrinter.instance;
    final target = BluetoothDevice(config.name, config.address);
    try {
      final alreadyConnected = await bluetooth
          .isDeviceConnected(target)
          .timeout(_shortTimeout);
      if (alreadyConnected == true) return;

      final connected = await bluetooth.isConnected.timeout(_shortTimeout);
      if (connected == true) {
        await bluetooth.disconnect().timeout(_shortTimeout);
      }

      final device = (await bondedDevices()).where(
        (item) => item.address == config.address,
      );
      if (device.isEmpty) {
        throw const AppException(
          'PRINTER_NOT_FOUND',
          'Printer tidak ditemukan pada daftar perangkat Bluetooth yang '
              'dipasangkan. Pasangkan printer melalui pengaturan Bluetooth '
              'Android lalu muat ulang.',
        );
      }
      await bluetooth.connect(device.first).timeout(_connectTimeout);
    } on AppException {
      rethrow;
    } on TimeoutException {
      throw const AppException(
        'PRINTER_TIMEOUT',
        'Koneksi ke printer melebihi batas waktu. Pastikan printer menyala, '
            'dekat dengan perangkat, dan sudah dipasangkan.',
      );
    } on PlatformException catch (error) {
      // Older plugin builds reject a second connection; treat it as connected.
      if (error.code == 'connect_error' &&
          (error.message ?? '').contains('already connected')) {
        return;
      }
      throw AppException(
        'PRINTER_CONNECT_FAILED',
        _bluetoothMessage(
          error,
          'Gagal menghubungkan printer. Pastikan printer menyala dan sudah '
          'dipasangkan di pengaturan Bluetooth Android.',
        ),
      );
    }
  }

  Future<void> disconnect() async {
    try {
      final connected = await BlueThermalPrinter.instance.isConnected.timeout(
        _shortTimeout,
      );
      if (connected != true) return;
      await BlueThermalPrinter.instance.disconnect().timeout(_shortTimeout);
    } on TimeoutException {
      return;
    } on PlatformException {
      return;
    }
  }

  Future<void> openBluetoothSettings() async {
    try {
      await BlueThermalPrinter.instance.openSettings;
    } on PlatformException {
      return;
    }
  }

  String _bluetoothMessage(PlatformException error, String fallback) {
    switch (error.code) {
      case 'bluetooth_unavailable':
        return 'Perangkat ini tidak memiliki Bluetooth.';
      case 'no_permissions':
        return 'Izin Bluetooth belum diberikan untuk aplikasi ini.';
      case 'connect_error':
        final detail = error.message;
        return detail == null || detail.isEmpty
            ? 'Gagal menghubungkan printer. Periksa printer lalu coba lagi.'
            : 'Gagal menghubungkan printer: $detail';
      case 'write_error':
        return 'Koneksi printer terputus saat mengirim data.';
    }
    return fallback;
  }

  PaperSize _paperSize(int paperWidth) => switch (paperWidth) {
    80 => PaperSize.mm80,
    72 => PaperSize.mm72,
    _ => PaperSize.mm58,
  };

  Future<void> testPrint(PrinterConfig config) async {
    if (!config.hasAddress) {
      throw const AppException(
        'PRINTER_NOT_CONFIGURED',
        'Pilih perangkat printer terlebih dahulu.',
      );
    }
    final profile = await CapabilityProfile.load();
    final generator = Generator(_paperSize(config.paperWidth), profile);
    var bytes = <int>[];
    bytes += generator.reset();
    bytes += generator.text(
      'TES CETAK',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.text(
      'Koneksi printer berhasil.',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      formatDateTime(DateTime.now()),
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += _finish(generator, config.paperWidth);

    await connect(config);
    try {
      await BlueThermalPrinter.instance
          .writeBytes(Uint8List.fromList(bytes))
          .timeout(_listTimeout);
    } on TimeoutException {
      throw const AppException(
        'PRINT_TIMEOUT',
        'Tes cetak melebihi batas waktu. Periksa kertas dan koneksi printer.',
      );
    } on PlatformException catch (error) {
      throw AppException(
        'PRINT_FAILED',
        _bluetoothMessage(error, 'Tes cetak gagal dikirim ke printer.'),
      );
    }
  }

  Future<void> printSale({
    required SaleRecord sale,
    required AppBusiness business,
    required AppOutlet outlet,
    PrinterConfig? config,
    bool reprint = false,
    bool? compact,
  }) async {
    final settings = config ?? await loadConfig();
    final bytes = await buildReceipt(
      sale: sale,
      business: business,
      outlet: outlet,
      paperWidth: settings.paperWidth,
      reprint: reprint,
      compact: compact ?? settings.compact,
    );
    await connect(settings);
    try {
      await BlueThermalPrinter.instance
          .writeBytes(Uint8List.fromList(bytes))
          .timeout(_writeTimeout);
    } on TimeoutException {
      throw const AppException(
        'PRINT_TIMEOUT',
        'Pengiriman struk melebihi batas waktu. Periksa printer sebelum '
            'mencetak ulang.',
      );
    } on PlatformException catch (error) {
      throw AppException(
        'PRINT_FAILED',
        _bluetoothMessage(error, 'Struk gagal dikirim ke printer.'),
      );
    }
  }

  Future<List<int>> buildReceipt({
    required SaleRecord sale,
    required AppBusiness business,
    required AppOutlet outlet,
    int paperWidth = 58,
    bool reprint = false,
    bool compact = false,
  }) async {
    final profile = await CapabilityProfile.load();
    final paper = _paperSize(paperWidth);
    final generator = Generator(paper, profile);
    var bytes = <int>[];
    bytes += generator.reset();

    final center = const PosStyles(align: PosAlign.center, bold: true);
    const centered = PosStyles(align: PosAlign.center);

    bytes += generator.text(business.name, styles: center);
    if (!compact && outlet.name.isNotEmpty) {
      bytes += generator.text('Outlet ${outlet.name}', styles: centered);
    }
    final address = outlet.address ?? business.address;
    if (address != null && address.isNotEmpty) {
      bytes += generator.text(address, styles: centered, linesAfter: 0);
    }
    if (!compact && business.phone != null && business.phone!.isNotEmpty) {
      bytes += generator.text(business.phone!, styles: centered);
    }
    bytes += generator.feed(1);

    final heading = ReceiptLayout.transactionHeading(
      receiptNumber: sale.receiptNumber,
      isVoided: sale.isVoided,
      hasAwaitingPayment: sale.hasAwaitingPayment,
      paperWidth: paperWidth,
    );
    for (var index = 0; index < heading.length; index++) {
      bytes += generator.text(
        heading[index],
        styles: index == 0 ? center : centered,
      );
    }
    if (reprint) {
      bytes += generator.text('CETAK ULANG', styles: centered);
    }
    bytes += generator.text(
      formatDateTime(sale.transactedAt),
      styles: centered,
    );
    if (sale.cashierName != null && sale.cashierName!.isNotEmpty) {
      bytes += generator.text('Kasir: ${sale.cashierName}', styles: centered);
    }
    bytes += generator.text(
      '${_orderTypeLabel(sale.orderType)}'
      '${sale.tableNumber == null ? '' : ' · Meja ${sale.tableNumber}'}',
      styles: centered,
    );

    for (final item in sale.items) {
      final name = item.variantName == null
          ? item.productName
          : '${item.productName} (${item.variantName})';
      final lines = ReceiptLayout.itemLines(
        label: '${item.quantity}x $name',
        amount: formatRupiah(item.lineTotal),
        paperWidth: paperWidth,
      );
      for (final line in lines) {
        bytes += generator.text(line, styles: const PosStyles(bold: true));
      }
      if (item.addonsSummary != null && item.addonsSummary!.isNotEmpty) {
        bytes += generator.text('  + ${item.addonsSummary}');
      }
      if (item.notes != null && item.notes!.isNotEmpty) {
        bytes += generator.text('  * ${item.notes}');
      }
    }

    bytes += generator.hr();
    bytes += _row(generator, 'Subtotal', formatRupiah(sale.subtotal));
    if (sale.itemDiscountTotal > 0) {
      bytes += _row(
        generator,
        'Diskon item',
        '-${formatRupiah(sale.itemDiscountTotal)}',
      );
    }
    if (sale.transactionDiscountTotal > 0) {
      bytes += _row(
        generator,
        'Diskon transaksi',
        '-${formatRupiah(sale.transactionDiscountTotal)}',
      );
    }
    if (sale.serviceCharge > 0) {
      bytes += _row(
        generator,
        'Service charge',
        formatRupiah(sale.serviceCharge),
      );
    }
    if (sale.taxTotal > 0) {
      bytes += _row(generator, 'Pajak', formatRupiah(sale.taxTotal));
    }
    bytes += _row(generator, 'TOTAL', formatRupiah(sale.total), bold: true);
    bytes += generator.feed(1);

    for (final payment in sale.payments) {
      bytes += _row(
        generator,
        _paymentLabel(payment.method),
        formatRupiah(payment.amount),
      );
      if (payment.tenderedAmount != null &&
          payment.tenderedAmount! > payment.amount) {
        bytes += _row(
          generator,
          'Diterima',
          formatRupiah(payment.tenderedAmount!),
        );
        bytes += _row(
          generator,
          'Kembalian',
          formatRupiah(payment.changeAmount),
        );
      }
    }
    if (!compact) {
      bytes += generator.text('Terima kasih', styles: center);
      bytes += generator.text('Simpan struk sebagai bukti', styles: centered);
    }
    bytes += _finish(generator, paperWidth);
    return bytes;
  }

  static const _cutCommand = <int>[0x1D, 0x56, 0x00];

  /// Minimal feed before cut. [Generator.cut] adds five blank lines, which
  /// leaves a large gap between consecutive receipts. 80 mm printers get a
  /// slightly longer feed for their cutter offset.
  List<int> _finish(Generator generator, int paperWidth) {
    final feedLines = paperWidth >= 80 ? 4 : 2;
    return [...generator.feed(feedLines), ..._cutCommand];
  }

  List<int> _row(
    Generator generator,
    String label,
    String value, {
    bool bold = false,
  }) {
    final styles = PosStyles(bold: bold);
    return generator.row([
      PosColumn(text: label, width: 7, styles: styles),
      PosColumn(
        text: value,
        width: 5,
        styles: PosStyles(align: PosAlign.right, bold: bold),
      ),
    ]);
  }

  String _orderTypeLabel(String value) => switch (value) {
    'take_away' => 'Bawa pulang',
    'delivery' => 'Antar',
    _ => 'Makan di tempat',
  };

  String _paymentLabel(String value) => switch (value) {
    'cash' => 'Tunai',
    'qris' => 'QRIS',
    'transfer' => 'Transfer',
    'ewallet' => 'E-Wallet',
    _ => value,
  };

  Future<List<PrintJobSummary>> pendingJobs() async {
    await (_db.update(_db.printJobs)
          ..where((row) => row.status.equals('sending')))
        .write(const PrintJobsCompanion(status: Value('unknown')));
    final rows =
        await (_db.select(_db.printJobs)
              ..where(
                (row) =>
                    row.status.equals('pending') |
                    row.status.equals('failed') |
                    row.status.equals('unknown'),
              )
              ..orderBy([(row) => OrderingTerm.asc(row.id)]))
            .get();
    final result = <PrintJobSummary>[];
    for (final row in rows) {
      final sale = await (_db.select(
        _db.localSales,
      )..where((item) => item.uuid.equals(row.saleUuid))).getSingleOrNull();
      result.add(
        PrintJobSummary(
          id: row.id,
          saleUuid: row.saleUuid,
          receiptNumber: sale?.receiptNumber ?? '-',
          status: row.status,
          attempts: row.attempts,
          createdAt: row.createdAt,
          lastError: row.lastError,
        ),
      );
    }
    return result;
  }

  Future<void> markSending(int jobId) async {
    await (_db.update(_db.printJobs)..where((item) => item.id.equals(jobId)))
        .write(const PrintJobsCompanion(status: Value('sending')));
  }

  /// Acknowledges a job whose print outcome could not be confirmed but whose
  /// paper was verified by the cashier.
  Future<void> markPrinted(int jobId) async {
    await (_db.update(
      _db.printJobs,
    )..where((item) => item.id.equals(jobId))).write(
      PrintJobsCompanion(
        status: const Value('sent'),
        lastError: const Value(null),
        printedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> markResult(
    int jobId, {
    required bool success,
    String? error,
    bool outcomeUnknown = false,
  }) async {
    final row = await (_db.select(
      _db.printJobs,
    )..where((item) => item.id.equals(jobId))).getSingleOrNull();
    if (row == null) return;
    await (_db.update(
      _db.printJobs,
    )..where((item) => item.id.equals(jobId))).write(
      PrintJobsCompanion(
        status: Value(
          success
              ? 'sent'
              : outcomeUnknown
              ? 'unknown'
              : 'failed',
        ),
        attempts: Value(row.attempts + 1),
        lastError: Value(error),
        printedAt: Value(success ? DateTime.now() : null),
      ),
    );
  }
}
