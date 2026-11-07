import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/format/dates.dart';
import '../../../core/format/labels.dart';
import '../../../core/format/money.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../data/bootstrap/bootstrap_controller.dart';
import '../../../data/models/sale.dart';
import '../../../data/repositories/sale_repository.dart';

class ReceiptScreen extends ConsumerStatefulWidget {
  const ReceiptScreen({super.key, this.outcome, this.saleUuid});

  final CheckoutOutcome? outcome;
  final String? saleUuid;

  @override
  ConsumerState<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends ConsumerState<ReceiptScreen> {
  SaleRecord? _sale;
  bool _loading = false;
  bool _printing = false;
  bool _printed = false;
  String? _printError;
  bool _autoPrintStarted = false;

  @override
  void initState() {
    super.initState();
    _sale = widget.outcome?.sale;
    if (_sale == null && widget.saleUuid != null) {
      _loading = true;
      _loadSale(widget.saleUuid!);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoPrint());
  }

  Future<void> _loadSale(String uuid) async {
    try {
      final repository = ref.read(saleRepositoryProvider);
      var sale = await repository.byUuid(uuid);
      if (sale == null) {
        try {
          sale = await repository.fetchRemote(uuid);
          if (sale != null) await repository.saveRemoteSale(sale);
        } on AppException {
          sale = null;
        }
      }
      if (!mounted) return;
      setState(() {
        _sale = sale;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _autoPrint() async {
    if (_autoPrintStarted) return;
    _autoPrintStarted = true;
    final sale = _sale;
    if (widget.outcome == null || !widget.outcome!.printQueued) return;
    if (sale == null || !mounted) return;
    final config = await ref.read(printerServiceProvider).loadConfig();
    if (!config.configured) return;
    if (!config.shouldAutoPrint(hasAwaitingPayment: sale.hasAwaitingPayment)) {
      return;
    }
    await _print();
  }

  Future<void> _print() async {
    final sale = _sale;
    final data = ref.read(bootstrapProvider).value?.data;
    if (sale == null || _printing) return;
    if (data == null) {
      setState(() {
        _printError = 'Data bisnis belum tersedia. Muat ulang lalu coba lagi.';
      });
      return;
    }
    setState(() {
      _printing = true;
      _printError = null;
    });
    final printer = ref.read(printerServiceProvider);
    try {
      final config = await printer.loadConfig();
      if (!config.configured) {
        throw const AppException(
          'PRINTER_NOT_CONFIGURED',
          'Printer belum diatur. Buka Pengaturan › Printer Bluetooth.',
        );
      }
      final on = await printer.isBluetoothOn();
      if (!on) {
        throw const AppException(
          'BLUETOOTH_OFF',
          'Bluetooth perangkat belum aktif.',
        );
      }
      await _markSendingJobs();
      await printer.printSale(
        sale: sale,
        business: data.business,
        outlet: data.outlet,
        config: config,
        reprint: _isReprint,
      );
      await _markJobs(success: true);
      if (!mounted) return;
      setState(() {
        _printing = false;
        _printed = true;
        _printError = null;
      });
    } catch (error) {
      final message = error is AppException
          ? error.message
          : 'Gagal mencetak struk. Periksa printer lalu coba lagi.';
      final outcomeUnknown =
          error is! AppException || error.code == 'PRINT_TIMEOUT';
      await _markJobs(
        success: false,
        error: message,
        outcomeUnknown: outcomeUnknown,
      );
      if (!mounted) return;
      setState(() {
        _printing = false;
        _printed = false;
        _printError = outcomeUnknown
            ? '$message Kemungkinan struk sudah tercetak; periksa kertas '
                  'sebelum mencetak ulang.'
            : message;
      });
    }
  }

  Future<void> _markSendingJobs() async {
    final sale = _sale;
    if (sale == null) return;
    try {
      final printer = ref.read(printerServiceProvider);
      final jobs = await printer.pendingJobs();
      for (final job in jobs) {
        if (job.saleUuid == sale.uuid) {
          await printer.markSending(job.id);
        }
      }
    } catch (_) {
      // Status bookkeeping must never block a completed payment.
    }
  }

  Future<void> _markJobs({
    required bool success,
    String? error,
    bool outcomeUnknown = false,
  }) async {
    final sale = _sale;
    if (sale == null) return;
    try {
      final printer = ref.read(printerServiceProvider);
      final jobs = await printer.pendingJobs();
      for (final job in jobs) {
        if (job.saleUuid == sale.uuid) {
          await printer.markResult(
            job.id,
            success: success,
            error: error,
            outcomeUnknown: outcomeUnknown,
          );
        }
      }
    } catch (_) {
      // Queue bookkeeping must never block a completed payment.
    }
  }

  void _done() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/pos');
    }
  }

  /// History opens are reprints; the receipt was printed at checkout.
  bool get _isReprint => _printed || widget.outcome == null;

  String get _printLabel => _isReprint
      ? 'Cetak ulang'
      : (_sale?.hasAwaitingPayment ?? false)
      ? 'Cetak bukti pending'
      : 'Cetak struk';

  @override
  Widget build(BuildContext context) {
    final sale = _sale;
    final outcome = widget.outcome;
    final data = ref.watch(bootstrapProvider).value?.data;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Struk'),
        leading: IconButton(
          onPressed: _done,
          icon: const Icon(Icons.close_rounded),
        ),
        actions: [
          IconButton(
            onPressed: _printing ? null : _print,
            tooltip: _printLabel,
            icon: const Icon(Icons.print_outlined),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: _loading
          ? const AppLoading(label: 'Memuat transaksi…')
          : sale == null
          ? AppEmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Struk tidak ditemukan',
              message:
                  'Transaksi belum tersimpan di perangkat. Periksa riwayat atau '
                  'sinkronkan data.',
              action: FilledButton(
                onPressed: _done,
                child: const Text('Kembali ke kasir'),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              children: [
                if (outcome?.offline == true)
                  const Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.md),
                    child: InfoBanner(
                      message:
                          'Transaksi tersimpan offline dan akan dikirim otomatis '
                          'saat koneksi tersedia. Simpan struk ini sebagai bukti.',
                      tone: StatusTone.warning,
                      icon: Icons.cloud_off_rounded,
                    ),
                  ),
                if (outcome?.replayed == true)
                  const Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.md),
                    child: InfoBanner(
                      message:
                          'Order ini sudah pernah diproses. Struk yang ditampilkan '
                          'adalah transaksi yang tersimpan di server.',
                      tone: StatusTone.info,
                      icon: Icons.history_rounded,
                    ),
                  ),
                if (sale.hasAwaitingPayment)
                  const Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.md),
                    child: InfoBanner(
                      message:
                          'Pembayaran non-tunai menunggu verifikasi kasir. '
                          'Transaksi belum lunas sampai pembayaran diverifikasi.',
                      tone: StatusTone.warning,
                      icon: Icons.hourglass_top_rounded,
                    ),
                  ),
                if (sale.isOffline && outcome == null)
                  const Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.md),
                    child: InfoBanner(
                      message:
                          'Transaksi ini dibuat offline dan belum dikonfirmasi server.',
                      tone: StatusTone.warning,
                      icon: Icons.cloud_off_rounded,
                    ),
                  ),
                if (_printError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: InfoBanner(
                      message: _printError!,
                      tone: StatusTone.danger,
                      icon: Icons.print_disabled_rounded,
                      action: TextButton(
                        onPressed: () => context.push('/settings/printer'),
                        child: const Text('Atur'),
                      ),
                    ),
                  ),
                if (_printed)
                  const Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.md),
                    child: InfoBanner(
                      message: 'Struk berhasil dikirim ke printer.',
                      tone: StatusTone.success,
                      icon: Icons.print_rounded,
                    ),
                  ),
                _SaleReceiptCard(sale: sale),
                const SizedBox(height: AppSpacing.lg),
                if (data != null)
                  OutlinedButton.icon(
                    onPressed: _printing ? null : _print,
                    icon: _printing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.print_outlined),
                    label: Text(_printing ? 'Mencetak…' : _printLabel),
                  ),
                const SizedBox(height: AppSpacing.sm),
                FilledButton(
                  onPressed: _done,
                  child: const Text('Transaksi selesai'),
                ),
              ],
            ),
    );
  }
}

class _SaleReceiptCard extends StatelessWidget {
  const _SaleReceiptCard({required this.sale});

  final SaleRecord sale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sale.receiptNumber,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatDateTime(sale.transactedAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusChip(
                  label: sale.paymentStatusLabel,
                  tone: paymentStatusTone(sale.paymentStatus),
                  compact: true,
                ),
              ],
            ),
            const Divider(height: AppSpacing.xl),
            for (final item in sale.items)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 32,
                      child: Text(
                        '${item.quantity}x',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.inkMuted,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.variantName == null
                                ? item.productName
                                : '${item.productName} (${item.variantName})',
                          ),
                          if (item.addonsSummary != null &&
                              item.addonsSummary!.isNotEmpty)
                            Text(
                              '+ ${item.addonsSummary}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.inkMuted,
                              ),
                            ),
                          if (item.notes != null && item.notes!.isNotEmpty)
                            Text(
                              '* ${item.notes}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.inkMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(formatRupiah(item.lineTotal)),
                  ],
                ),
              ),
            const Divider(height: AppSpacing.xl),
            _AmountRow(label: 'Subtotal', value: sale.subtotal),
            if (sale.itemDiscountTotal > 0)
              _AmountRow(label: 'Diskon item', value: -sale.itemDiscountTotal),
            if (sale.transactionDiscountTotal > 0)
              _AmountRow(
                label: 'Diskon transaksi',
                value: -sale.transactionDiscountTotal,
              ),
            if (sale.serviceCharge > 0)
              _AmountRow(label: 'Service charge', value: sale.serviceCharge),
            if (sale.taxTotal > 0)
              _AmountRow(label: 'Pajak', value: sale.taxTotal),
            const Divider(height: AppSpacing.xl),
            _AmountRow(label: 'Total', value: sale.total, bold: true),
            if (sale.payments.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                'Pembayaran',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.inkMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              for (final payment in sale.payments)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          paymentMethodLabel(payment.method),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      if (!payment.isConfirmed) ...[
                        StatusChip(
                          label: payment.isAwaiting
                              ? 'Menunggu verifikasi'
                              : 'Belum dikonfirmasi',
                          tone: StatusTone.warning,
                          compact: true,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      Text(formatRupiah(payment.amount)),
                    ],
                  ),
                ),
              if (sale.awaitingAmount > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: _AmountRow(
                    label: 'Menunggu verifikasi',
                    value: sale.awaitingAmount,
                  ),
                ),
              if (sale.refundedAmount > 0)
                _AmountRow(
                  label: 'Sudah direfund',
                  value: -sale.refundedAmount,
                ),
            ],
            if (sale.cashierName != null && sale.cashierName!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                'Kasir: ${sale.cashierName}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.inkMuted,
                ),
              ),
            ],
            if (sale.tableNumber != null && sale.tableNumber!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${orderTypeLabel(sale.orderType)} · Meja ${sale.tableNumber}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.inkMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final int value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(
            value < 0 ? '-${formatRupiah(value.abs())}' : formatRupiah(value),
            style: style?.copyWith(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
