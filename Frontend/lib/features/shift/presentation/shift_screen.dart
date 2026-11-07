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
    final canView =
        user?.canAny(const ['shifts.view', 'shifts.manage']) ?? false;
    final canManage = user?.can('shifts.manage') ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shift outlet'),
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
            return _OpenShiftView(canView: canView, canManage: canManage);
          }
          return _ActiveShiftView(
            summary: summary,
            storedOffline: value.storedOffline,
            canView: canView,
            canManage: canManage,
          );
        },
      ),
    );
  }
}

class _OpenShiftView extends ConsumerStatefulWidget {
  const _OpenShiftView({required this.canView, required this.canManage});

  final bool canView;
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
                ? 'Shift outlet dibuka. Semua kasir dapat bertransaksi.'
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
              'Satu outlet memiliki satu shift bersama. Owner membuka shift '
              'dengan modal awal, lalu semua kasir memakai shift yang sama '
              'dari perangkat masing-masing.',
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
                  'Buka shift outlet',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  widget.canManage
                      ? 'Belum ada shift aktif. Buka shift untuk mulai '
                          'menerima transaksi dari semua perangkat.'
                      : 'Belum ada shift aktif. Minta Owner atau pengguna '
                          'dengan izin shift untuk membuka shift outlet.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
                ),
                if (widget.canManage) ...[
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _cash,
                    enabled: !_submitting,
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
                    enabled: !_submitting,
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
                    onPressed: _submitting ? null : _open,
                    icon: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.play_arrow_rounded),
                    label: Text(_submitting ? 'Membuka shift…' : 'Buka shift'),
                  ),
                ] else ...[
                  const SizedBox(height: AppSpacing.md),
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
    required this.canView,
    required this.canManage,
  });

  final ShiftSummary summary;
  final bool storedOffline;
  final bool canView;
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
      final pending = closed.pendingDevices;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            closed.isClosedConfirmed
                ? 'Shift ditutup dan snapshot tersimpan.'
                : closed.isClosing
                ? pending.isEmpty
                      ? 'Penutupan shift menunggu konfirmasi perangkat.'
                      : 'Penutupan tertahan. Perangkat belum sinkron: '
                            '${pending.map((d) => d.displayName).join(', ')}.'
                : closed.statusLabel,
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

  Future<void> _checkpoint(BuildContext context, WidgetRef ref) async {
    try {
      final updated = await ref.read(shiftProvider.notifier).checkpoint();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updated.isClosedConfirmed
                ? 'Perangkat terkonfirmasi. Shift selesai ditutup.'
                : 'Perangkat terkonfirmasi. Masih menunggu perangkat lain.',
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
        if (shift.waitingForDevices)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: InfoBanner(
              message:
                  'Penutupan shift tertahan sampai semua perangkat yang '
                  'bertransaksi mengonfirmasi sinkronisasi. Perangkat ini '
                  'dapat mengonfirmasi setelah outbox kosong.',
              tone: StatusTone.warning,
              icon: Icons.sync_problem_rounded,
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
                            'Shift outlet bersama',
                            style: theme.textTheme.titleMedium,
                          ),
                          Text(
                            shift.openedByName == null
                                ? 'Dibuka ${formatDateTime(shift.openedAt)}'
                                : 'Dibuka ${shift.openedByName} · '
                                      '${formatDateTime(shift.openedAt)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.inkMuted,
                            ),
                          ),
                          if (shift.openedDeviceName != null)
                            Text(
                              'Perangkat pembuka: ${shift.openedDeviceName}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.inkMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                    StatusChip(
                      label: shift.statusLabel,
                      tone: shift.isClosing
                          ? StatusTone.warning
                          : StatusTone.success,
                    ),
                  ],
                ),
                if (summary.fromServer) ...[
                  const SizedBox(height: AppSpacing.sm),
                  const InfoBanner(
                    message:
                        'Ringkasan dari server dan mencakup transaksi seluruh '
                        'perangkat pada shift ini.',
                    tone: StatusTone.info,
                    icon: Icons.devices_rounded,
                  ),
                ],
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
        if (shift.pendingDevices.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _PendingDevicesCard(devices: shift.pendingDevices),
        ],
        const SizedBox(height: AppSpacing.lg),
        if (shift.isClosing) ...[
          OutlinedButton.icon(
            onPressed: () => ref.read(shiftProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Perbarui status penutupan'),
          ),
          if (canView) ...[
            const SizedBox(height: AppSpacing.sm),
            FilledButton.icon(
              onPressed: () => _checkpoint(context, ref),
              icon: const Icon(Icons.cloud_done_rounded),
              label: const Text('Konfirmasi perangkat ini sudah sinkron'),
            ),
          ],
        ] else if (canManage) ...[
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

class _PendingDevicesCard extends StatelessWidget {
  const _PendingDevicesCard({required this.devices});

  final List<ShiftPendingDevice> devices;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Perangkat yang belum sinkron', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            for (final device in devices)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.userName == null
                          ? device.displayName
                          : '${device.displayName} · ${device.userName}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      device.reason,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
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
    final shift = widget.summary.shift;
    return AlertDialog(
      title: const Text('Tutup shift outlet'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              shift.openedByName == null
                  ? 'Shift dibuka ${formatDateTime(shift.openedAt)}'
                  : 'Dibuka ${shift.openedByName} · '
                        '${formatDateTime(shift.openedAt)}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Kas seharusnya ${formatRupiah(widget.summary.expectedCash)}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
            ),
            if (widget.summary.fromServer)
              const Padding(
                padding: EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  'Total mencakup transaksi dari semua perangkat.',
                  style: TextStyle(
                    color: AppColors.inkMuted,
                    fontSize: 12,
                  ),
                ),
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
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Shift baru final setelah semua perangkat yang bertransaksi '
              'mengonfirmasi sinkronisasi.',
              style: TextStyle(color: AppColors.inkMuted, fontSize: 12),
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
