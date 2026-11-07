import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/format/dates.dart';
import '../../../core/format/money.dart';
import '../../../core/pricing/pricing_calculator.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../data/bootstrap/bootstrap_controller.dart';
import '../../../data/models/catalog.dart';
import '../../../data/models/shift.dart';
import '../../../data/repositories/bootstrap_repository.dart';
import '../../../data/session/session_controller.dart';
import '../../../data/shifts/shift_controller.dart';
import '../state/cart_controller.dart';
import 'cart_panel.dart';
import 'held_orders_sheet.dart';
import 'product_options_sheet.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final _search = TextEditingController();
  String? _categoryUuid;
  bool _holding = false;

  @override
  void initState() {
    super.initState();
    _search.addListener(_onSearch);
  }

  void _onSearch() => setState(() {});

  @override
  void dispose() {
    _search
      ..removeListener(_onSearch)
      ..dispose();
    super.dispose();
  }

  bool get _shiftAcceptsTransactions =>
      ref.read(shiftProvider).value?.hasOpenShift ?? false;

  void _showShiftBlocked() {
    final shift = ref.read(shiftProvider).value;
    final message = shift == null || (shift.shift == null && !shift.isClosing)
        ? 'Status shift belum tersedia. Muat ulang status shift sebelum '
              'bertransaksi.'
        : shift.isClosing
        ? 'Shift outlet sedang ditutup. Transaksi baru ditahan sampai '
              'penutupan selesai.'
        : 'Shift outlet belum dibuka. Minta Owner membuka shift sebelum '
              'bertransaksi.';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _addProduct(CatalogProduct product) async {
    if (!_shiftAcceptsTransactions) {
      _showShiftBlocked();
      return;
    }
    if (product.activeVariants.isNotEmpty || product.activeAddons.isNotEmpty) {
      await showProductOptions(context, product);
      return;
    }
    ref
        .read(cartProvider.notifier)
        .addLine(
          productUuid: product.uuid,
          productName: product.name,
          unitPrice: product.price,
          taxRateBasisPoints: product.taxRateBasisPoints,
        );
  }

  Future<void> _hold() async {
    if (_holding) return;
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) return;
    setState(() => _holding = true);
    try {
      await ref.read(orderRepositoryProvider).hold(cart);
      if (!mounted) return;
      ref.read(cartProvider.notifier).clear();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Pesanan ditahan. Lanjutkan dari daftar tahanan.'),
          ),
        );
    } catch (error) {
      if (!mounted) return;
      final message = error is AppException
          ? error.message
          : 'Pesanan gagal ditahan. Periksa penyimpanan lalu coba lagi.';
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _holding = false);
    }
  }

  void _checkout() {
    if (!_shiftAcceptsTransactions) {
      _showShiftBlocked();
      return;
    }
    if (ref.read(cartProvider).isEmpty) return;
    context.push('/checkout');
  }

  void _openCartSheet(PricingConfig config) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        final media = MediaQuery.of(context);
        final available = media.size.height - media.viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
          child: SizedBox(
            height: available * 0.78,
            child: CartPanel(
              config: config,
              compact: true,
              onCheckout: () {
                Navigator.of(context).pop();
                _checkout();
              },
              onHold: () {
                Navigator.of(context).pop();
                _hold();
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bootstrap = ref.watch(bootstrapProvider);
    final shift = ref.watch(shiftProvider);

    if (bootstrap.isLoading && !bootstrap.hasValue) {
      return const AppLoading(label: 'Memuat katalog…');
    }
    if (bootstrap.hasError && !bootstrap.hasValue) {
      return AppErrorView(
        error: bootstrap.error!,
        onRetry: () => ref.read(bootstrapProvider.notifier).refresh(),
      );
    }

    final state = bootstrap.value;
    final snapshot = state?.snapshot;
    final data = snapshot?.data;
    if (data == null) {
      return AppEmptyState(
        icon: Icons.storefront_outlined,
        title: 'Katalog belum tersedia',
        message:
            'Aplikasi memerlukan katalog dari server untuk transaksi pertama. '
            'Sambungkan perangkat ke jaringan outlet lalu muat ulang.',
        action: FilledButton.icon(
          onPressed: state?.refreshing == true
              ? null
              : () => ref.read(bootstrapProvider.notifier).refresh(),
          icon: state?.refreshing == true
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.cloud_download_outlined),
          label: const Text('Muat katalog'),
        ),
      );
    }

    final session = ref.watch(sessionProvider).value;
    final currentShift = shift.value;
    final canTransact = currentShift?.hasOpenShift ?? false;
    final closing = currentShift?.isClosing ?? false;

    final config = data.pricingConfig;
    final products = data.products
        .where((product) => product.sellable)
        .toList();
    final categories = data.categories
        .where(
          (category) =>
              products.any((product) => product.categoryUuid == category.uuid),
        )
        .toList();
    final query = _search.text.trim().toLowerCase();
    final visible = products.where((product) {
      if (_categoryUuid != null && product.categoryUuid != _categoryUuid) {
        return false;
      }
      if (query.isEmpty) return true;
      return product.name.toLowerCase().contains(query) ||
          product.sku.toLowerCase().contains(query) ||
          (product.barcode?.toLowerCase().contains(query) ?? false);
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final catalog = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PosHeader(
              data: data,
              snapshot: snapshot!,
              refreshing: state?.refreshing == true,
              onRefresh: () => ref.read(bootstrapProvider.notifier).refresh(),
              onHeld: () => showHeldOrders(context),
              leaseRemaining: session?.lease?.remaining,
              leaseValid: session?.leaseValid ?? false,
            ),
            if (canTransact && currentShift?.shift != null)
              _SharedShiftBanner(shift: currentShift!.shift!)
            else
              _ShiftNotice(
                closing: closing,
                error: shift.error,
                refreshing: shift.isLoading,
                canManage: session?.user.can('shifts.manage') ?? false,
                onRetry: () => ref.read(shiftProvider.notifier).refresh(),
                onOpenShift: () => context.go('/shift'),
              ),
            if (state?.lastError != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: InfoBanner(
                  message: state!.lastError!.message,
                  tone: StatusTone.danger,
                  icon: Icons.cloud_off_rounded,
                  action: TextButton(
                    onPressed: () =>
                        ref.read(bootstrapProvider.notifier).refresh(),
                    child: const Text('Coba'),
                  ),
                ),
              ),
            if (snapshot.freshness == CatalogFreshness.warning)
              const Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: InfoBanner(
                  message:
                      'Katalog lokal berumur lebih dari 24 jam. Segarkan saat ada koneksi.',
                  tone: StatusTone.warning,
                  icon: Icons.schedule_rounded,
                ),
              ),
            if (snapshot.freshness == CatalogFreshness.expired)
              const Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: InfoBanner(
                  message:
                      'Katalog kedaluwarsa. Transaksi offline diblokir sampai katalog diperbarui.',
                  tone: StatusTone.danger,
                  icon: Icons.error_outline_rounded,
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xs,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: TextField(
                controller: _search,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Cari menu, SKU, atau barcode',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: _search.clear,
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                children: [
                  _CategoryChip(
                    label: 'Semua',
                    count: products.length,
                    selected: _categoryUuid == null,
                    onTap: () => setState(() => _categoryUuid = null),
                  ),
                  for (final category in categories)
                    _CategoryChip(
                      label: category.name,
                      count: products
                          .where((item) => item.categoryUuid == category.uuid)
                          .length,
                      selected: _categoryUuid == category.uuid,
                      onTap: () =>
                          setState(() => _categoryUuid = category.uuid),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: visible.isEmpty
                  ? AppEmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'Menu tidak ditemukan',
                      message: query.isEmpty
                          ? 'Belum ada produk yang dapat dijual pada kategori ini.'
                          : 'Coba kata kunci lain atau pilih kategori berbeda.',
                      action: query.isEmpty
                          ? null
                          : TextButton(
                              onPressed: _search.clear,
                              child: const Text('Hapus pencarian'),
                            ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        0,
                        AppSpacing.lg,
                        AppSpacing.lg,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 240,
                            mainAxisExtent: 132,
                            mainAxisSpacing: AppSpacing.md,
                            crossAxisSpacing: AppSpacing.md,
                          ),
                      itemCount: visible.length,
                      itemBuilder: (context, index) {
                        final product = visible[index];
                        return _ProductTile(
                          product: product,
                          onTap: () => _addProduct(product),
                        );
                      },
                    ),
            ),
            if (!wide)
              _CartBar(
                config: config,
                onOpen: () => _openCartSheet(config),
                onCheckout: _checkout,
              ),
          ],
        );

        if (!wide) return catalog;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: catalog),
            Container(
              width: 380,
              padding: const EdgeInsets.fromLTRB(
                0,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: CartPanel(
                config: config,
                onCheckout: _checkout,
                onHold: _hold,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ShiftNotice extends StatelessWidget {
  const _ShiftNotice({
    required this.closing,
    required this.error,
    required this.refreshing,
    required this.canManage,
    required this.onRetry,
    required this.onOpenShift,
  });

  final bool closing;
  final Object? error;
  final bool refreshing;
  final bool canManage;
  final VoidCallback onRetry;
  final VoidCallback onOpenShift;

  @override
  Widget build(BuildContext context) {
    final message = error != null
        ? 'Status shift tidak dapat diperiksa. Katalog tetap dapat dilihat, '
              'tetapi transaksi baru ditahan sampai status shift terverifikasi.'
        : closing
        ? 'Shift outlet sedang ditutup dan menunggu sinkronisasi perangkat. '
              'Transaksi baru ditahan sampai penutupan selesai.'
        : 'Shift outlet belum dibuka. Katalog tetap dapat dilihat, tetapi '
              'transaksi baru ditahan sampai Owner membuka shift.';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: InfoBanner(
        message: message,
        tone: error != null || closing ? StatusTone.danger : StatusTone.warning,
        icon: closing
            ? Icons.sync_problem_rounded
            : error != null
            ? Icons.error_outline_rounded
            : Icons.schedule_rounded,
        action: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: refreshing ? null : onRetry,
              tooltip: 'Muat ulang status shift',
              icon: refreshing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded, size: 18),
            ),
            TextButton(
              onPressed: onOpenShift,
              child: Text(closing || !canManage ? 'Lihat shift' : 'Buka shift'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SharedShiftBanner extends StatelessWidget {
  const _SharedShiftBanner({required this.shift});

  final ShiftRecord shift;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final openedBy = shift.openedByName;
    final openedAt = formatDateTime(shift.openedAt);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.devices_rounded,
            size: 16,
            color: AppColors.inkMuted,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              openedBy == null
                  ? 'Shift outlet bersama · dibuka $openedAt'
                  : 'Shift outlet bersama · $openedBy · $openedAt',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.inkMuted,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          StatusChip(
            label: 'Shift aktif',
            tone: StatusTone.success,
            compact: true,
          ),
        ],
      ),
    );
  }
}

class _PosHeader extends ConsumerWidget {
  const _PosHeader({
    required this.data,
    required this.snapshot,
    required this.refreshing,
    required this.onRefresh,
    required this.onHeld,
    required this.leaseValid,
    this.leaseRemaining,
  });

  final BootstrapData data;
  final CatalogSnapshot snapshot;
  final bool refreshing;
  final VoidCallback onRefresh;
  final VoidCallback onHeld;
  final bool leaseValid;
  final Duration? leaseRemaining;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(connectivityProvider).value ?? false;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 30,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  StatusChip(
                    label: online ? 'Online' : 'Offline',
                    tone: online ? StatusTone.success : StatusTone.warning,
                    icon: online ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                    compact: true,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  StatusChip(
                    label: leaseValid
                        ? 'Lease ${_hours(leaseRemaining)}'
                        : 'Lease habis',
                    tone: leaseValid ? StatusTone.info : StatusTone.danger,
                    icon: Icons.verified_user_outlined,
                    compact: true,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  StatusChip(
                    label: switch (snapshot.freshness) {
                      CatalogFreshness.fresh => 'Katalog baru',
                      CatalogFreshness.warning => 'Katalog >24 jam',
                      CatalogFreshness.expired => 'Katalog kedaluwarsa',
                      CatalogFreshness.missing => 'Katalog kosong',
                    },
                    tone: switch (snapshot.freshness) {
                      CatalogFreshness.fresh => StatusTone.success,
                      CatalogFreshness.warning => StatusTone.warning,
                      CatalogFreshness.expired => StatusTone.danger,
                      CatalogFreshness.missing => StatusTone.neutral,
                    },
                    icon: Icons.inventory_2_outlined,
                    compact: true,
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: refreshing ? null : onRefresh,
            tooltip: 'Segarkan katalog',
            icon: refreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync_rounded),
          ),
          IconButton(
            onPressed: onHeld,
            tooltip: 'Pesanan ditahan',
            icon: const Icon(Icons.pause_circle_outline_rounded),
          ),
        ],
      ),
    );
  }

  String _hours(Duration? remaining) {
    if (remaining == null) return '-';
    final hours = remaining.inMinutes / 60;
    if (hours >= 1) return '${hours.floor()}j';
    return '${remaining.inMinutes}m';
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: ChoiceChip(
        selected: selected,
        onSelected: (_) => onTap(),
        label: Text('$label · $count'),
        showCheckmark: false,
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product, required this.onTap});

  final CatalogProduct product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.coralSoft,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Center(
                      child: Text(
                        product.name.isEmpty
                            ? '?'
                            : product.name.substring(0, 1).toUpperCase(),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: AppColors.coral),
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (product.activeVariants.isNotEmpty)
                    const StatusChip(label: 'Varian', compact: true),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Text(
                formatRupiah(product.price),
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: AppColors.forestDark),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartBar extends ConsumerWidget {
  const _CartBar({
    required this.config,
    required this.onOpen,
    required this.onCheckout,
  });

  final PricingConfig config;
  final VoidCallback onOpen;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    if (cart.isEmpty) return const SizedBox.shrink();
    var total = 0;
    var valid = true;
    try {
      total = cart.totalFor(config);
    } catch (_) {
      // Keep the POS usable even if a legacy cart holds invalid line data.
      valid = false;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.outline)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            InkWell(
              onTap: onOpen,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xs),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${cart.itemCount} item · ${cart.lines.length} baris',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.inkMuted,
                      ),
                    ),
                    Text(
                      valid ? formatRupiah(total) : 'Perhitungan tidak valid',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: valid ? AppColors.forestDark : AppColors.danger,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            OutlinedButton(
              onPressed: onOpen,
              child: Text('Keranjang (${cart.itemCount})'),
            ),
            const SizedBox(width: AppSpacing.sm),
            FilledButton(
              onPressed: valid ? onCheckout : null,
              child: const Text('Bayar'),
            ),
          ],
        ),
      ),
    );
  }
}
