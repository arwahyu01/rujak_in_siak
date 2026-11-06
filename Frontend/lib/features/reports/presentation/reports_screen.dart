import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/format/dates.dart';
import '../../../core/format/labels.dart';
import '../../../core/format/money.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_view.dart';
import '../../../data/session/session_controller.dart';
import '../data/reports_api.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int _rangeDays = 1;
  int _tab = 0;
  SalesReport? _sales;
  List<ProductReportRow> _products = const [];
  List<PaymentMethodReport> _payments = const [];
  bool _loading = true;
  AppException? _error;

  @override
  void initState() {
    super.initState();
    final user = ref.read(sessionProvider).value?.user;
    if (user != null && !user.can('reports.view')) {
      _loading = false;
      _error = const AppException(
        'FORBIDDEN',
        'Akun ini tidak memiliki akses melihat laporan.',
      );
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  ({DateTime from, DateTime to}) get _range {
    final now = DateTime.now();
    final to = DateTime(now.year, now.month, now.day);
    final from = to.subtract(Duration(days: _rangeDays - 1));
    return (from: from, to: to);
  }

  Future<void> _load() async {
    if (_error?.code == 'FORBIDDEN') return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final range = _range;
    final api = ref.read(reportsApiProvider);
    try {
      final sales = await api.sales(from: range.from, to: range.to);
      final products = await api.products(from: range.from, to: range.to);
      final payments = await api.payments(from: range.from, to: range.to);
      if (!mounted) return;
      setState(() {
        _sales = sales;
        _products = products;
        _payments = payments;
        _loading = false;
      });
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = AppException.unknown(error);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            tooltip: 'Muat ulang',
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final option in const [
                (label: 'Hari ini', days: 1),
                (label: '7 hari', days: 7),
                (label: '30 hari', days: 30),
              ])
                ChoiceChip(
                  label: Text(option.label),
                  selected: _rangeDays == option.days,
                  onSelected: (_) {
                    setState(() {
                      _rangeDays = option.days;
                      _tab = 0;
                    });
                    _load();
                  },
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${formatDate(_range.from)} – ${formatDate(_range.to)}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
          ),
          const SizedBox(height: AppSpacing.md),
          if (_error != null)
            AppErrorView(error: _error!, onRetry: _load)
          else if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: AppSpacing.xxl),
              child: AppLoading(label: 'Menyiapkan laporan…'),
            )
          else ...[
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Penjualan')),
                ButtonSegment(value: 1, label: Text('Produk')),
                ButtonSegment(value: 2, label: Text('Pembayaran')),
              ],
              selected: {_tab},
              onSelectionChanged: (value) => setState(() => _tab = value.first),
            ),
            const SizedBox(height: AppSpacing.md),
            if (_tab == 0) _SalesReportView(report: _sales),
            if (_tab == 1) _ProductsReportView(rows: _products),
            if (_tab == 2) _PaymentsReportView(rows: _payments),
          ],
        ],
      ),
    );
  }
}

class _SalesReportView extends StatelessWidget {
  const _SalesReportView({required this.report});

  final SalesReport? report;

  @override
  Widget build(BuildContext context) {
    final report = this.report;
    if (report == null) return const SizedBox.shrink();
    final summary = report.summary;
    if (summary.transactions == 0) {
      return const AppEmptyState(
        icon: Icons.bar_chart_outlined,
        title: 'Belum ada penjualan',
        message: 'Tidak ada transaksi pada rentang tanggal ini.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SummaryCard(
          total: summary.total,
          transactions: summary.transactions,
          discounts: summary.discounts,
          tax: summary.tax,
          serviceCharge: summary.serviceCharge,
          voidedTransactions: summary.voidedTransactions,
        ),
        const SizedBox(height: AppSpacing.md),
        if (report.daily.isNotEmpty) ...[
          _Section(
            title: 'Penjualan harian',
            child: Column(
              children: [
                for (final day in report.daily)
                  _Line(
                    label: formatDate(day.date),
                    value: formatRupiah(day.total),
                    hint: '${day.transactions} transaksi',
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (report.byCashier.isNotEmpty) ...[
          _Section(
            title: 'Per kasir',
            child: Column(
              children: [
                for (final cashier in report.byCashier)
                  _Line(
                    label: cashier.name,
                    value: formatRupiah(cashier.total),
                    hint: '${cashier.transactions} transaksi',
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (report.byOrderType.isNotEmpty)
          _Section(
            title: 'Per tipe pesanan',
            child: Column(
              children: [
                for (final type in report.byOrderType)
                  _Line(
                    label: orderTypeLabel(type.orderType),
                    value: formatRupiah(type.total),
                    hint: '${type.transactions} transaksi',
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.total,
    required this.transactions,
    required this.discounts,
    required this.tax,
    required this.serviceCharge,
    required this.voidedTransactions,
  });

  final int total;
  final int transactions;
  final int discounts;
  final int tax;
  final int serviceCharge;
  final int voidedTransactions;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.forestDark,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total penjualan',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.white70),
            ),
            Text(
              formatRupiah(total),
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(color: Colors.white),
            ),
            Text(
              '$transactions transaksi'
              '${voidedTransactions > 0 ? ' · $voidedTransactions void' : ''}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.sm,
              children: [
                _Metric(label: 'Diskon', value: formatRupiah(discounts)),
                _Metric(label: 'Pajak', value: formatRupiah(tax)),
                _Metric(label: 'Service', value: formatRupiah(serviceCharge)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.white60),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            child,
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value, this.hint});

  final String label;
  final String value;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label),
                if (hint != null)
                  Text(
                    hint!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
                  ),
              ],
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ProductsReportView extends StatelessWidget {
  const _ProductsReportView({required this.rows});

  final List<ProductReportRow> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const AppEmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'Belum ada produk terjual',
        message: 'Tidak ada penjualan produk pada rentang tanggal ini.',
      );
    }
    return _Section(
      title: 'Produk terlaris',
      child: Column(
        children: [
          for (final row in rows)
            _Line(
              label: row.name,
              hint: [
                if (row.sku != null && row.sku!.isNotEmpty) row.sku!,
                '${row.quantity} terjual',
              ].join(' · '),
              value: formatRupiah(row.total),
            ),
        ],
      ),
    );
  }
}

class _PaymentsReportView extends StatelessWidget {
  const _PaymentsReportView({required this.rows});

  final List<PaymentMethodReport> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const AppEmptyState(
        icon: Icons.payments_outlined,
        title: 'Belum ada pembayaran',
        message: 'Tidak ada pembayaran pada rentang tanggal ini.',
      );
    }
    return _Section(
      title: 'Pembayaran per metode',
      child: Column(
        children: [
          for (final row in rows)
            _Line(
              label: paymentMethodLabel(row.method),
              hint:
                  '${row.entries} entri · '
                  '${formatRupiah(row.confirmed)} terkonfirmasi',
              value: formatRupiah(row.recorded),
            ),
        ],
      ),
    );
  }
}
