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
import '../../../data/models/sale.dart';
import '../../../data/session/session_controller.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final TextEditingController _search = TextEditingController();
  List<SaleRecord> _sales = const [];
  bool _loading = true;
  bool _syncing = false;
  AppException? _error;
  int _range = 0;
  String? _paymentFilter;
  String? _cashierFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final sales = await ref.read(saleRepositoryProvider).recent(limit: 150);
      if (!mounted) return;
      setState(() {
        _sales = sales;
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

  Future<void> _syncFromServer() async {
    if (_syncing) return;
    final user = ref.read(sessionProvider).value?.user;
    final online = ref.read(connectivityProvider).value ?? true;
    if (!online) {
      setState(
        () => _error = const AppException(
          'OFFLINE',
          'Tidak ada koneksi. Riwayat lokal tetap dapat dibuka.',
        ),
      );
      return;
    }
    if (user != null && !user.can('sales.view')) {
      setState(
        () => _error = const AppException(
          'FORBIDDEN',
          'Akun ini tidak memiliki akses melihat riwayat transaksi server.',
        ),
      );
      return;
    }
    setState(() {
      _syncing = true;
      _error = null;
    });
    try {
      await ref.read(salesApiProvider).fetch(perPage: 50);
      await _load();
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = AppException.unknown(error));
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  List<SaleRecord> get _filtered {
    final query = _search.text.trim().toLowerCase();
    final now = DateTime.now();
    final start = switch (_range) {
      1 => DateTime(now.year, now.month, now.day),
      2 => now.subtract(const Duration(days: 7)),
      _ => null,
    };
    return _sales
        .where((sale) {
          if (start != null && sale.transactedAt.isBefore(start)) return false;
          if (_paymentFilter != null && sale.paymentStatus != _paymentFilter) {
            return false;
          }
          if (_cashierFilter != null &&
              (sale.cashierName ?? '') != _cashierFilter) {
            return false;
          }
          if (query.isEmpty) return true;
          return sale.receiptNumber.toLowerCase().contains(query) ||
              (sale.cashierName ?? '').toLowerCase().contains(query) ||
              (sale.tableNumber ?? '').toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  List<String> get _paymentOptions {
    final values = _sales.map((sale) => sale.paymentStatus).toSet().toList()
      ..sort();
    return values;
  }

  List<String> get _cashierOptions {
    final values =
        _sales
            .map((sale) => sale.cashierName)
            .whereType<String>()
            .where((name) => name.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return values;
  }

  void _resetFilters() {
    setState(() {
      _range = 0;
      _paymentFilter = null;
      _cashierFilter = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return RefreshIndicator(
      onRefresh: _syncFromServer,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Cari nomor struk, kasir, atau meja',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _search.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              ChoiceChip(
                label: const Text('Semua tanggal'),
                selected: _range == 0,
                onSelected: (_) => setState(() => _range = 0),
              ),
              ChoiceChip(
                label: const Text('Hari ini'),
                selected: _range == 1,
                onSelected: (_) => setState(() => _range = 1),
              ),
              ChoiceChip(
                label: const Text('7 hari'),
                selected: _range == 2,
                onSelected: (_) => setState(() => _range = 2),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  key: ValueKey('payment-${_paymentFilter ?? 'all'}'),
                  initialValue: _paymentFilter,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Status pembayaran',
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Semua'),
                    ),
                    for (final status in _paymentOptions)
                      DropdownMenuItem<String?>(
                        value: status,
                        child: Text(paymentStatusLabel(status)),
                      ),
                  ],
                  onChanged: (value) => setState(() => _paymentFilter = value),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  key: ValueKey('cashier-${_cashierFilter ?? 'all'}'),
                  initialValue: _cashierFilter,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Kasir',
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Semua'),
                    ),
                    for (final cashier in _cashierOptions)
                      DropdownMenuItem<String?>(
                        value: cashier,
                        child: Text(cashier, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (value) => setState(() => _cashierFilter = value),
                ),
              ),
            ],
          ),
          if (_range != 0 || _paymentFilter != null || _cashierFilter != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _resetFilters,
                icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
                label: const Text('Hapus filter'),
              ),
            ),
          if (_error != null) ...[
            InfoBanner(
              message: _error!.message,
              tone: StatusTone.warning,
              icon: Icons.cloud_off_rounded,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Row(
            children: [
              Expanded(
                child: Text(
                  '${filtered.length} transaksi terakhir',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.inkMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _syncing ? null : _syncFromServer,
                icon: _syncing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync_rounded, size: 18),
                label: Text(_syncing ? 'Menyinkron…' : 'Muat server'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: AppSpacing.xxl),
              child: AppLoading(label: 'Memuat riwayat…'),
            )
          else if (filtered.isEmpty)
            AppEmptyState(
              icon: Icons.receipt_long_outlined,
              title: _sales.isEmpty
                  ? 'Belum ada transaksi'
                  : 'Tidak ada hasil pencarian',
              message: _sales.isEmpty
                  ? 'Transaksi yang diproses di perangkat ini akan muncul di sini.'
                  : 'Coba kata kunci lain atau muat data dari server.',
            )
          else
            for (final sale in filtered)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _SaleListTile(
                  sale: sale,
                  onTap: () async {
                    await context.push('/sales/${sale.uuid}');
                    await _load();
                  },
                ),
              ),
        ],
      ),
    );
  }
}

class _SaleListTile extends StatelessWidget {
  const _SaleListTile({required this.sale, required this.onTap});

  final SaleRecord sale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: sale.isVoided
                      ? AppColors.dangerSoft
                      : AppColors.forestSoft,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  sale.isVoided
                      ? Icons.block_rounded
                      : sale.isOffline
                      ? Icons.cloud_off_rounded
                      : Icons.receipt_long_rounded,
                  color: sale.isVoided ? AppColors.danger : AppColors.forest,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sale.receiptNumber,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        formatDateTime(sale.transactedAt),
                        if (sale.cashierName != null) sale.cashierName!,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.inkMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        StatusChip(
                          label: sale.isVoided
                              ? 'Void'
                              : paymentStatusLabel(sale.paymentStatus),
                          tone: sale.isVoided
                              ? StatusTone.danger
                              : paymentStatusTone(sale.paymentStatus),
                          compact: true,
                        ),
                        if (sale.isOffline)
                          const StatusChip(
                            label: 'Offline',
                            tone: StatusTone.warning,
                            icon: Icons.cloud_off_rounded,
                            compact: true,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatRupiah(sale.total),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${sale.items.length} item',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.inkMuted,
                    ),
                  ),
                ],
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.inkMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
