import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/dates.dart';
import '../../../core/format/labels.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_view.dart';
import '../../../data/repositories/order_repository.dart';
import '../state/cart_controller.dart';

Future<void> showHeldOrders(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const _HeldOrdersSheet(),
  );
}

class _HeldOrdersSheet extends ConsumerStatefulWidget {
  const _HeldOrdersSheet();

  @override
  ConsumerState<_HeldOrdersSheet> createState() => _HeldOrdersSheetState();
}

class _HeldOrdersSheetState extends ConsumerState<_HeldOrdersSheet> {
  late Future<List<HeldOrderSummary>> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(orderRepositoryProvider).listHeld();
  }

  void _reload() {
    setState(() {
      _future = ref.read(orderRepositoryProvider).listHeld();
    });
  }

  Future<void> _resume(HeldOrderSummary summary) async {
    final cart = ref.read(cartProvider);
    if (!cart.isEmpty) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Ganti keranjang?'),
          content: const Text(
            'Keranjang saat ini akan diganti dengan pesanan yang ditahan. '
            'Tahan pesanan saat ini terlebih dahulu bila masih diperlukan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Ganti'),
            ),
          ],
        ),
      );
      if (replace != true) return;
    }

    final held = await ref.read(orderRepositoryProvider).loadHeld(summary.uuid);
    if (!mounted) return;
    if (held == null) {
      _reload();
      return;
    }
    ref.read(cartProvider.notifier).restore(held.cart);
    Navigator.of(context).pop();
  }

  Future<void> _delete(HeldOrderSummary summary) async {
    await ref.read(orderRepositoryProvider).deleteHeld(summary.uuid);
    if (!mounted) return;
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'Pesanan ditahan',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  onPressed: _reload,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: FutureBuilder<List<HeldOrderSummary>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const AppLoading(label: 'Memuat pesanan…');
                  }
                  if (snapshot.hasError) {
                    return AppErrorView(
                      error: snapshot.error!,
                      onRetry: _reload,
                    );
                  }
                  final orders = snapshot.data ?? const [];
                  if (orders.isEmpty) {
                    return const AppEmptyState(
                      icon: Icons.pause_circle_outline_rounded,
                      title: 'Tidak ada pesanan ditahan',
                      message:
                          'Pesanan yang ditahan akan muncul di sini dan bisa dilanjutkan kapan saja.',
                    );
                  }
                  return ListView.separated(
                    itemCount: orders.length,
                    separatorBuilder: (_, _) => const Divider(height: 12),
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.surfaceMuted,
                          child: Icon(
                            Icons.pause_rounded,
                            color: AppColors.inkMuted,
                          ),
                        ),
                        title: Text(
                          '${orderTypeLabel(order.orderType)}'
                          '${order.tableNumber == null ? '' : ' · Meja ${order.tableNumber}'}',
                        ),
                        subtitle: Text(
                          '${order.itemCount} item · ${relativeTime(order.updatedAt)}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              onPressed: () => _resume(order),
                              child: const Text('Lanjutkan'),
                            ),
                            IconButton(
                              tooltip: 'Hapus',
                              onPressed: () => _delete(order),
                              icon: const Icon(Icons.delete_outline_rounded),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
