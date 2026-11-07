import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../../data/models/sale.dart';
import '../../../data/session/session_controller.dart';

class SaleDetailScreen extends ConsumerStatefulWidget {
  const SaleDetailScreen({super.key, required this.saleUuid});

  final String saleUuid;

  @override
  ConsumerState<SaleDetailScreen> createState() => _SaleDetailScreenState();
}

class _SaleDetailScreenState extends ConsumerState<SaleDetailScreen> {
  SaleRecord? _sale;
  bool _loading = true;
  bool _refreshing = false;
  bool _busy = false;
  AppException? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load({bool remote = true}) async {
    final repository = ref.read(saleRepositoryProvider);
    try {
      final local = await repository.byUuid(widget.saleUuid);
      if (!mounted) return;
      setState(() {
        _sale = local;
        _loading = false;
      });

      final online = ref.read(connectivityProvider).value ?? false;
      if (!remote || !online) return;
      setState(() => _refreshing = true);
      try {
        final fresh = await repository.fetchRemote(widget.saleUuid);
        if (fresh == null) {
          throw const AppException(
            'NOT_FOUND',
            'Transaksi tidak ditemukan pada server.',
          );
        }
        await repository.saveRemoteSale(fresh);
        if (!mounted) return;
        setState(() {
          _sale = fresh;
          _error = null;
        });
      } on AppException catch (error) {
        if (!mounted) return;
        setState(() {
          _error = local == null ? error : null;
        });
      } finally {
        if (mounted) setState(() => _refreshing = false);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = AppException.unknown(error);
      });
    }
  }

  Future<void> _void() async {
    final sale = _sale;
    if (sale == null || _busy) return;
    final reason = await _askText(
      title: 'Void transaksi',
      label: 'Alasan void',
      hint: 'Contoh: salah input pesanan',
      confirmLabel: 'Void transaksi',
    );
    if (reason == null || reason.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      final updated = await ref
          .read(salesApiProvider)
          .voidSale(sale.uuid, reason.trim());
      if (!mounted) return;
      setState(() {
        _sale = updated;
        _error = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaksi berhasil di-void.')),
      );
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refund() async {
    final sale = _sale;
    if (sale == null || _busy) return;
    final refundable = sale.confirmedAmount - sale.refundedAmount;
    final result = await showDialog<_RefundInput>(
      context: context,
      builder: (context) => _RefundDialog(maxAmount: refundable),
    );
    if (result == null) return;
    setState(() => _busy = true);
    try {
      final updated = await ref
          .read(salesApiProvider)
          .refundSale(
            sale.uuid,
            amount: result.amount,
            reason: result.reason,
            method: result.method,
          );
      if (!mounted) return;
      setState(() {
        _sale = updated;
        _error = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Refund ${formatRupiah(result.amount)} tercatat.'),
        ),
      );
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _askText({
    required String title,
    required String label,
    required String hint,
    required String confirmLabel,
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) => _TextPromptDialog(
        title: title,
        label: label,
        hint: hint,
        confirmLabel: confirmLabel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sale = _sale;
    final user = ref.watch(sessionProvider).value?.user;
    final canVoid = user?.can('sales.void') ?? false;
    final canRefund = user?.can('sales.refund') ?? false;
    final online = ref.watch(connectivityProvider).value ?? false;

    final awaiting = sale?.awaitingAmount ?? 0;
    final confirmed = sale?.confirmedAmount ?? 0;
    final refunded = sale?.refundedAmount ?? 0;
    final refundable = confirmed - refunded;
    final voidBlockedReason = sale == null
        ? null
        : sale.isVoided
        ? 'Transaksi sudah di-void.'
        : confirmed > 0
        ? 'Pembayaran sudah terkonfirmasi. Gunakan refund, bukan void.'
        : awaiting > 0
        ? 'Tolak pembayaran yang menunggu verifikasi sebelum void.'
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail transaksi'),
        actions: [
          IconButton(
            onPressed: sale == null
                ? null
                : () => context.push('/receipt/${sale.uuid}'),
            tooltip: 'Buka struk',
            icon: const Icon(Icons.receipt_long_outlined),
          ),
          if (_refreshing)
            const Padding(
              padding: EdgeInsets.only(right: AppSpacing.md),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const AppLoading(label: 'Memuat transaksi…')
          : sale == null
          ? AppEmptyState(
              icon: Icons.search_off_rounded,
              title: 'Transaksi tidak ditemukan',
              message:
                  _error?.message ??
                  'Transaksi mungkin belum tersinkron ke perangkat ini.',
              action: OutlinedButton(
                onPressed: () => _load(),
                child: const Text('Coba lagi'),
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
                if (_error != null) ...[
                  InfoBanner(
                    message: _error!.message,
                    tone: StatusTone.danger,
                    icon: Icons.error_outline_rounded,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (sale.isVoided)
                  const Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.md),
                    child: InfoBanner(
                      message:
                          'Transaksi ini telah di-void dan tidak dihitung dalam penjualan.',
                      tone: StatusTone.danger,
                      icon: Icons.block_rounded,
                    ),
                  ),
                if (sale.isOffline)
                  const Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.md),
                    child: InfoBanner(
                      message:
                          'Transaksi dibuat offline. Aksi void/refund menunggu '
                          'transaksi tersinkron ke server.',
                      tone: StatusTone.warning,
                      icon: Icons.cloud_off_rounded,
                    ),
                  ),
                if (sale.hasAwaitingPayment)
                  const Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.md),
                    child: InfoBanner(
                      message:
                          'Masih ada pembayaran menunggu verifikasi pada transaksi ini.',
                      tone: StatusTone.warning,
                      icon: Icons.hourglass_top_rounded,
                    ),
                  ),
                Card(
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
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    formatDateTime(sale.transactedAt),
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: AppColors.inkMuted),
                                  ),
                                ],
                              ),
                            ),
                            StatusChip(
                              label: sale.isVoided
                                  ? 'Void'
                                  : paymentStatusLabel(sale.paymentStatus),
                              tone: sale.isVoided
                                  ? StatusTone.danger
                                  : paymentStatusTone(sale.paymentStatus),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          '${orderTypeLabel(sale.orderType)}'
                          '${sale.tableNumber == null ? '' : ' · Meja ${sale.tableNumber}'}'
                          '${sale.cashierName == null ? '' : ' · ${sale.cashierName}'}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.inkMuted),
                        ),
                        const Divider(height: AppSpacing.xl),
                        for (final item in sale.items)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 30,
                                  child: Text(
                                    '${item.quantity}x',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: AppColors.inkMuted),
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: AppColors.inkMuted,
                                              ),
                                        ),
                                    ],
                                  ),
                                ),
                                Text(formatRupiah(item.lineTotal)),
                              ],
                            ),
                          ),
                        const Divider(height: AppSpacing.xl),
                        _row(context, 'Subtotal', sale.subtotal),
                        if (sale.discountTotal > 0)
                          _row(context, 'Diskon', -sale.discountTotal),
                        if (sale.serviceCharge > 0)
                          _row(context, 'Service charge', sale.serviceCharge),
                        if (sale.taxTotal > 0)
                          _row(context, 'Pajak', sale.taxTotal),
                        const Divider(height: AppSpacing.xl),
                        _row(context, 'Total', sale.total, bold: true),
                        if (sale.confirmedAmount > 0)
                          _row(context, 'Terkonfirmasi', sale.confirmedAmount),
                        if (sale.awaitingAmount > 0)
                          _row(
                            context,
                            'Menunggu verifikasi',
                            sale.awaitingAmount,
                          ),
                        if (sale.refundedAmount > 0)
                          _row(context, 'Refund', -sale.refundedAmount),
                      ],
                    ),
                  ),
                ),
                if (sale.payments.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Pembayaran',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          for (final payment in sale.payments)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          paymentMethodLabel(payment.method),
                                        ),
                                        if (payment.providerReference != null &&
                                            payment
                                                .providerReference!
                                                .isNotEmpty)
                                          Text(
                                            payment.providerReference!,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: AppColors.inkMuted,
                                                ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  StatusChip(
                                    label: paymentStatusLabel(payment.status),
                                    tone: paymentStatusTone(payment.status),
                                    compact: true,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(formatRupiah(payment.amount)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                if (canVoid && !sale.isVoided)
                  OutlinedButton.icon(
                    onPressed: _busy || !online || voidBlockedReason != null
                        ? null
                        : _void,
                    icon: const Icon(Icons.block_rounded),
                    label: const Text('Void transaksi'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                    ),
                  ),
                if (canVoid &&
                    !sale.isVoided &&
                    voidBlockedReason != null &&
                    confirmed == 0)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      voidBlockedReason,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ),
                if (canRefund && !sale.isVoided && refundable > 0) ...[
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: _busy || !online ? null : _refund,
                    icon: const Icon(Icons.undo_rounded),
                    label: Text('Refund · sisa ${formatRupiah(refundable)}'),
                  ),
                ],
                if (!online)
                  const Padding(
                    padding: EdgeInsets.only(top: AppSpacing.sm),
                    child: Text(
                      'Void dan refund memerlukan koneksi ke server.',
                      style: TextStyle(color: AppColors.inkMuted, fontSize: 12),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    int value, {
    bool bold = false,
  }) {
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

class _TextPromptDialog extends StatefulWidget {
  const _TextPromptDialog({
    required this.title,
    required this.label,
    required this.hint,
    required this.confirmLabel,
  });

  final String title;
  final String label;
  final String hint;
  final String confirmLabel;

  @override
  State<_TextPromptDialog> createState() => _TextPromptDialogState();
}

class _TextPromptDialogState extends State<_TextPromptDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: 3,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

class _RefundInput {
  const _RefundInput({required this.amount, required this.reason, this.method});

  final int amount;
  final String reason;
  final String? method;
}

class _RefundDialog extends StatefulWidget {
  const _RefundDialog({required this.maxAmount});

  final int maxAmount;

  @override
  State<_RefundDialog> createState() => _RefundDialogState();
}

class _RefundDialogState extends State<_RefundDialog> {
  final TextEditingController _amount = TextEditingController();
  final TextEditingController _reason = TextEditingController();
  String? _method = 'cash';
  String? _error;

  @override
  void initState() {
    super.initState();
    _amount.text = '${widget.maxAmount}';
  }

  @override
  void dispose() {
    _amount.dispose();
    _reason.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = int.tryParse(_amount.text.replaceAll(RegExp(r'\D'), ''));
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Nominal refund tidak valid.');
      return;
    }
    if (amount > widget.maxAmount) {
      setState(() => _error = 'Nominal melebihi sisa yang dapat direfund.');
      return;
    }
    if (_reason.text.trim().isEmpty) {
      setState(() => _error = 'Alasan refund wajib diisi.');
      return;
    }
    Navigator.of(context).pop(
      _RefundInput(
        amount: amount,
        reason: _reason.text.trim(),
        method: _method,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Refund transaksi'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Maksimal ${formatRupiah(widget.maxAmount)}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _amount,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Nominal refund',
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: _method,
              decoration: const InputDecoration(labelText: 'Metode refund'),
              items: const [
                DropdownMenuItem(value: 'cash', child: Text('Tunai')),
                DropdownMenuItem(value: 'qris', child: Text('QRIS')),
                DropdownMenuItem(value: 'transfer', child: Text('Transfer')),
                DropdownMenuItem(value: 'ewallet', child: Text('E-Wallet')),
              ],
              onChanged: (value) => setState(() => _method = value),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _reason,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Alasan refund'),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.danger, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Proses refund')),
      ],
    );
  }
}
