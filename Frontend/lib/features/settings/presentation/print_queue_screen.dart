import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/format/dates.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../data/bootstrap/bootstrap_controller.dart';
import '../../../data/services/printer_service.dart';

class PrintQueueScreen extends ConsumerStatefulWidget {
  const PrintQueueScreen({super.key});

  @override
  ConsumerState<PrintQueueScreen> createState() => _PrintQueueScreenState();
}

class _PrintQueueScreenState extends ConsumerState<PrintQueueScreen> {
  List<PrintJobSummary> _jobs = const [];
  bool _loading = true;
  int? _busyJob;
  AppException? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      final jobs = await ref.read(printerServiceProvider).pendingJobs();
      if (!mounted) return;
      setState(() {
        _jobs = jobs;
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = AppException.unknown(error);
      });
    }
  }

  Future<void> _retry(PrintJobSummary job) async {
    if (_busyJob != null) return;
    final data = ref.read(bootstrapProvider).value?.data;
    if (data == null) {
      setState(
        () => _error = const AppException(
          'CATALOG_MISSING',
          'Data bisnis belum tersedia. Muat ulang lalu coba lagi.',
        ),
      );
      return;
    }
    setState(() {
      _busyJob = job.id;
      _error = null;
    });
    final printer = ref.read(printerServiceProvider);
    try {
      final sale = await ref.read(saleRepositoryProvider).byUuid(job.saleUuid);
      if (sale == null) {
        throw const AppException(
          'SALE_NOT_FOUND',
          'Transaksi untuk struk ini tidak ditemukan di perangkat.',
        );
      }
      await printer.markSending(job.id);
      await printer.printSale(
        sale: sale,
        business: data.business,
        outlet: data.outlet,
        reprint: true,
      );
      await printer.markResult(job.id, success: true);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Struk berhasil dicetak.')));
      await _load();
    } on AppException catch (error) {
      final outcomeUnknown = error.code == 'PRINT_TIMEOUT';
      await printer.markResult(
        job.id,
        success: false,
        error: error.message,
        outcomeUnknown: outcomeUnknown,
      );
      if (!mounted) return;
      setState(
        () => _error = outcomeUnknown
            ? AppException(
                error.code,
                '${error.message} Kemungkinan struk sudah tercetak; periksa '
                'kertas sebelum mencetak ulang.',
              )
            : error,
      );
      await _load();
    } catch (error) {
      const message = 'Gagal mencetak. Periksa printer Bluetooth.';
      await printer.markResult(
        job.id,
        success: false,
        error: message,
        outcomeUnknown: true,
      );
      if (!mounted) return;
      setState(
        () => _error = const AppException(
          'PRINT_FAILED',
          '$message Kemungkinan struk sudah tercetak; periksa kertas '
              'sebelum mencetak ulang.',
        ),
      );
      await _load();
    } finally {
      if (mounted) setState(() => _busyJob = null);
    }
  }

  Future<void> _markPrinted(PrintJobSummary job) async {
    if (_busyJob != null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tandai sudah tercetak'),
        content: Text(
          'Tandai struk ${job.receiptNumber} sebagai sudah tercetak? '
          'Lakukan ini hanya jika kertas struk sudah keluar dari printer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sudah tercetak'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busyJob = job.id);
    try {
      await ref.read(printerServiceProvider).markPrinted(job.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Struk ditandai sudah tercetak.')),
      );
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = AppException.unknown(error));
    } finally {
      if (mounted) setState(() => _busyJob = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Antrean cetak'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            tooltip: 'Muat ulang',
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          children: [
            const InfoBanner(
              message:
                  'Struk yang gagal dicetak tetap tersimpan di antrean. '
                  'Kegagalan printer tidak memengaruhi transaksi pembayaran.',
              tone: StatusTone.info,
              icon: Icons.info_outline_rounded,
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              InfoBanner(
                message: _error!.message,
                tone: StatusTone.danger,
                icon: Icons.print_disabled_rounded,
                action: TextButton(
                  onPressed: () => context.push('/settings/printer'),
                  child: const Text('Printer'),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: AppSpacing.xxl),
                child: AppLoading(label: 'Memuat antrean…'),
              )
            else if (_jobs.isEmpty)
              const AppEmptyState(
                icon: Icons.print_outlined,
                title: 'Antrean kosong',
                message: 'Semua struk sudah tercetak atau belum ada antrean.',
              )
            else
              for (final job in _jobs)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  job.receiptNumber,
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              StatusChip(
                                label: _jobStatusLabel(job.status),
                                tone: _jobStatusTone(job.status),
                                compact: true,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${formatDateTime(job.createdAt)} · '
                            '${job.attempts} percobaan',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.inkMuted),
                          ),
                          if (job.lastError != null &&
                              job.lastError!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              job.lastError!,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.danger),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _busyJob == null
                                      ? () => _retry(job)
                                      : null,
                                  icon: _busyJob == job.id
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.print_rounded),
                                  label: Text(
                                    _busyJob == job.id
                                        ? 'Mencetak…'
                                        : 'Cetak sekarang',
                                  ),
                                ),
                              ),
                              if (job.status == 'unknown') ...[
                                const SizedBox(width: AppSpacing.sm),
                                TextButton(
                                  onPressed: _busyJob == null
                                      ? () => _markPrinted(job)
                                      : null,
                                  child: const Text('Sudah tercetak'),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

String _jobStatusLabel(String status) => switch (status) {
  'failed' => 'Gagal',
  'unknown' => 'Tidak diketahui',
  'sent' => 'Terkirim',
  'sending' => 'Mengirim',
  _ => 'Menunggu',
};

StatusTone _jobStatusTone(String status) => switch (status) {
  'failed' => StatusTone.danger,
  'unknown' => StatusTone.warning,
  'sent' => StatusTone.success,
  _ => StatusTone.warning,
};
