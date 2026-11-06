import 'dart:convert';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:drift/drift.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

import '../../core/database/app_database.dart';
import '../../core/errors/app_exception.dart';
import '../../core/format/dates.dart';
import '../../core/format/money.dart';
import '../models/catalog.dart';
import '../models/sale.dart';
import 'bluetooth_permissions.dart';

class PrinterConfig {
  const PrinterConfig({
    this.enabled = false,
    this.name,
    this.address,
    this.paperWidth = 58,
  });

  final bool enabled;
  final String? name;
  final String? address;
  final int paperWidth;

  bool get configured =>
      enabled && address != null && address!.trim().isNotEmpty;

  factory PrinterConfig.fromJson(Map<String, dynamic> json) {
    return PrinterConfig(
      enabled: json['enabled'] == true,
      name: json['name'] as String?,
      address: json['address'] as String?,
      paperWidth: json['paper_width'] is num
          ? (json['paper_width'] as num).toInt()
          : 58,
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
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

class PrinterService {
  PrinterService(this._db);

  static const _configKey = 'printer_config';

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
    return BlueThermalPrinter.instance.getBondedDevices();
  }

  Future<bool> isBluetoothOn() async {
    await _ensureBluetoothPermission();
    return await BlueThermalPrinter.instance.isOn ?? false;
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
    if (!config.configured) {
      throw const AppException(
        'PRINTER_NOT_CONFIGURED',
        'Printer belum dipilih. Atur printer Bluetooth di menu Pengaturan.',
      );
    }
    final device = (await bondedDevices()).where(
      (item) => item.address == config.address,
    );
    if (device.isEmpty) {
      throw const AppException(
        'PRINTER_NOT_FOUND',
        'Printer tidak ditemukan pada daftar perangkat Bluetooth yang dipasangkan.',
      );
    }
    await BlueThermalPrinter.instance.connect(device.first);
  }

  Future<void> printSale({
    required SaleRecord sale,
    required AppBusiness business,
    required AppOutlet outlet,
    PrinterConfig? config,
    bool reprint = false,
  }) async {
    final settings = config ?? await loadConfig();
    final bytes = await buildReceipt(
      sale: sale,
      business: business,
      outlet: outlet,
      paperWidth: settings.paperWidth,
      reprint: reprint,
    );
    await connect(settings);
    await BlueThermalPrinter.instance.writeBytes(Uint8List.fromList(bytes));
  }

  Future<List<int>> buildReceipt({
    required SaleRecord sale,
    required AppBusiness business,
    required AppOutlet outlet,
    int paperWidth = 58,
    bool reprint = false,
  }) async {
    final profile = await CapabilityProfile.load();
    final paper = switch (paperWidth) {
      80 => PaperSize.mm80,
      72 => PaperSize.mm72,
      _ => PaperSize.mm58,
    };
    final generator = Generator(paper, profile);
    var bytes = <int>[];
    bytes += generator.reset();

    final center = const PosStyles(align: PosAlign.center, bold: true);
    const centered = PosStyles(align: PosAlign.center);

    bytes += generator.text(business.name, styles: center);
    if (outlet.name.isNotEmpty) {
      bytes += generator.text('Outlet ${outlet.name}', styles: centered);
    }
    final address = outlet.address ?? business.address;
    if (address != null && address.isNotEmpty) {
      bytes += generator.text(address, styles: centered, linesAfter: 0);
    }
    if (business.phone != null && business.phone!.isNotEmpty) {
      bytes += generator.text(business.phone!, styles: centered);
    }
    bytes += generator.feed(1);
    final typeLabel = sale.isVoided
        ? 'VOID'
        : sale.hasAwaitingPayment
        ? 'PAYMENT PENDING'
        : 'PAID RECEIPT';
    bytes += generator.text('$typeLabel ${sale.receiptNumber}', styles: center);
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
    bytes += generator.feed(1);
    bytes += generator.text('-' * 32);

    for (final item in sale.items) {
      final name = item.variantName == null
          ? item.productName
          : '${item.productName} (${item.variantName})';
      bytes += generator.row([
        PosColumn(
          text: '${item.quantity}x $name',
          width: 8,
          styles: const PosStyles(bold: true),
        ),
        PosColumn(
          text: formatRupiah(item.lineTotal),
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
      if (item.addonsSummary != null && item.addonsSummary!.isNotEmpty) {
        bytes += generator.text('  + ${item.addonsSummary}');
      }
      if (item.notes != null && item.notes!.isNotEmpty) {
        bytes += generator.text('  * ${item.notes}');
      }
    }

    bytes += generator.text('-' * 32);
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
    bytes += generator.text('-' * 32);
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
    if (sale.hasAwaitingPayment) {
      bytes += generator.text(
        'MENUNGGU VERIFIKASI PEMBAYARAN',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
    }

    bytes += generator.feed(1);
    bytes += generator.text('Terima kasih', styles: center);
    bytes += generator.text(
      'Simpan struk ini sebagai bukti pembayaran.',
      styles: centered,
    );
    bytes += generator.feed(2);
    bytes += generator.cut();
    return bytes;
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

  Future<void> enqueue(String saleUuid) async {
    final existing =
        await (_db.select(_db.printJobs)..where(
              (row) =>
                  row.saleUuid.equals(saleUuid) &
                  row.status.equals('sent').not(),
            ))
            .getSingleOrNull();
    if (existing != null) return;
    await _db
        .into(_db.printJobs)
        .insert(
          PrintJobsCompanion.insert(
            saleUuid: saleUuid,
            createdAt: DateTime.now(),
          ),
        );
  }

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
