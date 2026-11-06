import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/format/dates.dart';
import '../../../core/format/money.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../data/models/shift.dart';
import '../../../data/session/session_controller.dart';
import '../../../data/shifts/shift_controller.dart';

class ShiftScreen extends ConsumerWidget {
  const ShiftScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(shiftProvider);
    final user = ref.watch(sessionProvider).value?.user;
    final canManage =
        user?.canAny(const ['shifts.manage', 'shifts.view']) ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shift kasir'),
        actions: [
          IconButton(
            onPressed: state.isLoading
                ? null
                : () => ref.read(shiftProvider.notifier).refresh(),
            tooltip: 'Muat ulang',
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: state.when(
        loading: () => const AppLoading(label: 'Memuat shift…'),
        error: (error, _) => AppErrorView(
          error: error,
          onRetry: () => ref.read(shiftProvider.notifier).refresh(),
        ),
        data: (value) {
          final shift = value.shift;
          final summary = value.summary;
          if (shift == null || summary == null) {
            return _OpenShiftView(canManage: canManage);
          }
          return _ActiveShiftView(
            summary: summary,
            storedOffline: value.storedOffline,
            canManage: canManage,
          );
        },
      ),
    );
  }
}

class _OpenShiftView extends ConsumerStatefulWidget {
  const _OpenShiftView({required this.canManage});

  final bool canManage;

  @override
  ConsumerState<_OpenShiftView> createState() => _OpenShiftViewState();
}

class _OpenShiftViewState extends ConsumerState<_OpenShiftView> {
  final TextEditingController _cash = TextEditingController();
  final TextEditingController _notes = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _cash.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    final cash = int.tryParse(_cash.text.replaceAll(RegExp(r'\D'), ''));
    if (cash == null || cash < 0) {
      setState(() => _error = 'Modal awal tidak valid.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final shift = await ref
          .read(shiftProvider.notifier)
          .open(openingCash: cash, openingNotes: _notes.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            shift.synced
                ? 'Shift dibuka.'
                : 'Shift dibuka offline dan akan disinkronkan.',
          ),
        ),
      );
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      children: [
        const InfoBanner(
          message:
              'Buka shift sebelum memproses transaksi. Modal awal digunakan '
              'untuk menghitung kas yang seharusnya ada saat tutup shift.',
          tone: StatusTone.info,
          icon: Icons.info_outline_rounded,
        ),
        const SizedBox(height: AppSpacing.lg),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Buka shift baru',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _cash,
                  enabled: widget.canManage && !_submitting,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Modal awal',
                    prefixText: 'Rp ',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _notes,
                  enabled: widget.canManage && !_submitting,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Catatan pembukaan (opsional)',
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _error!,
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  onPressed: widget.canManage && !_submitting ? _open : null,
                  icon: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow_rounded),
                  label: Text(_submitting ? 'Membuka shift…' : 'Buka shift'),
                ),
                if (!widget.canManage) ...[
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'Akun ini tidak memiliki izin membuka shift.',
                    style: TextStyle(color: AppColors.inkMuted, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ActiveShiftView extends ConsumerWidget {
  const _ActiveShiftView({
    required this.summary,
    required this.storedOffline,
    required this.canManage,
  });

  final ShiftSummary summary;
  final bool storedOffline;
  final bool canManage;

  Future<void> _movement(
    BuildContext context,
    WidgetRef ref, {
    required String type,
  }) async {
    final result = await showDialog<_MovementInput>(
      context: context,
      builder: (context) => _MovementDialog(type: type),
    );
    if (result == null) return;
    try {
      await ref
          .read(shiftProvider.notifier)
          .recordMovement(
            type: result.type,
            amount: result.amount,
            reason: result.reason,
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.type == 'cash_in'
                ? 'Kas masuk tercatat.'
                : 'Kas keluar tercatat.',
          ),
        ),
      );
    } on AppException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _close(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<_CloseInput>(
      context: context,
      builder: (context) => _CloseDialog(summary: summary),
    );
    if (result == null) return;
    try {
      final closed = await ref
          .read(shiftProvider.notifier)
          .close(actualCash: result.actualCash, closingNotes: result.notes);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            closed.isClosedPendingSync
                ? 'Shift ditutup offline dan menunggu sinkronisasi.'
                : 'Shift ditutup.',
          ),
        ),
      );
    } on AppException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shift = summary.shift;
    final theme = Theme.of(context);
    final variance = shift.difference;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      children: [
        if (storedOffline)
          const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.md),
            child: InfoBanner(
              message:
                  'Shift ini belum tersinkron ke server. Data tetap tersimpan lokal.',
              tone: StatusTone.warning,
              icon: Icons.cloud_off_rounded,
            ),
          ),
        if (summary.awaitingVerification > 0)
          const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.md),
            child: InfoBanner(
              message:
                  'Ada pembayaran non-tunai menunggu verifikasi. Rekonsiliasi '
                  'shift sebaiknya dilakukan setelah semua pembayaran diverifikasi.',
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
                            'Shift aktif',
                            style: theme.textTheme.titleMedium,
                          ),
                          Text(
                            'Dibuka ${formatDateTime(shift.openedAt)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    StatusChip(
                      label: shift.statusLabel,
                      tone: StatusTone.success,
                    ),
                  ],
                ),
                const Divider(height: AppSpacing.xl),
                _row(context, 'Modal awal', shift.openingCash),
                _row(context, 'Tunai diterima', summary.cashTendered),
                _row(context, 'Kembalian tunai', summary.cashChange),
                _row(context, 'Kas masuk', summary.cashIn),
                _row(context, 'Kas keluar', summary.cashOut),
                _row(context, 'Refund tunai', summary.cashRefund),
                const Divider(height: AppSpacing.xl),
                _row(
                  context,
                  'Kas seharusnya',
                  summary.expectedCash,
                  bold: true,
                ),
                const SizedBox(height: AppSpacing.md),
                _row(
                  context,
                  'Non-tunai terkonfirmasi',
                  summary.confirmedNonCash,
                ),
                if (summary.awaitingVerification > 0)
                  _row(
                    context,
                    'Menunggu verifikasi',
                    summary.awaitingVerification,
                  ),
                _row(context, 'Jumlah transaksi', summary.transactionCount),
                _row(context, 'Total penjualan', summary.saleTotal, bold: true),
                if (variance != null) ...[
                  const Divider(height: AppSpacing.xl),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Selisih kas',
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                      Text(
                        formatRupiahSigned(variance),
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: variance == 0
                              ? AppColors.forest
                              : AppColors.danger,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (canManage) ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _movement(context, ref, type: 'cash_in'),
                  icon: const Icon(Icons.add_card_rounded),
                  label: const Text('Kas masuk'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _movement(context, ref, type: 'cash_out'),
                  icon: const Icon(Icons.outbox_rounded),
                  label: const Text('Kas keluar'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          FilledButton.icon(
            onPressed: () => _close(context, ref),
            icon: const Icon(Icons.lock_clock_rounded),
            label: const Text('Tutup shift'),
          ),
        ] else
          const Text(
            'Akun ini hanya dapat melihat ringkasan shift.',
            style: TextStyle(color: AppColors.inkMuted, fontSize: 12),
          ),
      ],
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    int value, {
    bool bold = false,
  }) {
    final style = bold
        ? Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(formatRupiah(value), style: style),
        ],
      ),
    );
  }
}

class _MovementInput {
  const _MovementInput({
    required this.type,
    required this.amount,
    required this.reason,
  });

  final String type;
  final int amount;
  final String reason;
}

class _MovementDialog extends StatefulWidget {
  const _MovementDialog({required this.type});

  final String type;

  @override
  State<_MovementDialog> createState() => _MovementDialogState();
}

class _MovementDialogState extends State<_MovementDialog> {
  final TextEditingController _amount = TextEditingController();
  final TextEditingController _reason = TextEditingController();
  String? _error;

  bool get _isIn => widget.type == 'cash_in';

  @override
  void dispose() {
    _amount.dispose();
    _reason.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = int.tryParse(_amount.text.replaceAll(RegExp(r'\D'), ''));
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Nominal tidak valid.');
      return;
    }
    if (_reason.text.trim().isEmpty) {
      setState(() => _error = 'Alasan wajib diisi.');
      return;
    }
    Navigator.of(context).pop(
      _MovementInput(
        type: widget.type,
        amount: amount,
        reason: _reason.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isIn ? 'Kas masuk' : 'Kas keluar'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _amount,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'Nominal',
              prefixText: 'Rp ',
              helperText: _isIn
                  ? 'Tambahan kas di luar penjualan.'
                  : 'Pengeluaran kas dari laci.',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _reason,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Alasan'),
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
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Simpan')),
      ],
    );
  }
}

class _CloseInput {
  const _CloseInput({required this.actualCash, this.notes});

  final int actualCash;
  final String? notes;
}

class _CloseDialog extends StatefulWidget {
  const _CloseDialog({required this.summary});

  final ShiftSummary summary;

  @override
  State<_CloseDialog> createState() => _CloseDialogState();
}

class _CloseDialogState extends State<_CloseDialog> {
  late final TextEditingController _cash = TextEditingController(
    text: '${widget.summary.expectedCash}',
  );
  final TextEditingController _notes = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _cash.dispose();
    _notes.dispose();
    super.dispose();
  }

  int? get _actual => int.tryParse(_cash.text.replaceAll(RegExp(r'\D'), ''));

  void _submit() {
    final actual = _actual;
    if (actual == null || actual < 0) {
      setState(() => _error = 'Kas aktual tidak valid.');
      return;
    }
    Navigator.of(
      context,
    ).pop(_CloseInput(actualCash: actual, notes: _notes.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final actual = _actual;
    final variance = actual == null ? null : widget.summary.varianceFor(actual);
    return AlertDialog(
      title: const Text('Tutup shift'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Kas seharusnya ${formatRupiah(widget.summary.expectedCash)}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _cash,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Kas aktual di laci',
                prefixText: 'Rp ',
              ),
            ),
            if (variance != null) ...[
              const SizedBox(height: AppSpacing.sm),
              InfoBanner(
                message: variance == 0
                    ? 'Kas sesuai dengan perhitungan sistem.'
                    : 'Selisih ${formatRupiahSigned(variance)} terhadap perhitungan sistem.',
                tone: variance == 0 ? StatusTone.success : StatusTone.warning,
                icon: variance == 0
                    ? Icons.check_circle_outline_rounded
                    : Icons.warning_amber_rounded,
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _notes,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Catatan penutupan (opsional)',
              ),
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
        FilledButton(onPressed: _submit, child: const Text('Tutup shift')),
      ],
    );
  }
}
