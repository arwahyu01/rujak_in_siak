import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/money.dart';
import '../../../core/pricing/pricing_calculator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/status_chip.dart';
import '../state/cart_controller.dart';

class CartPanel extends ConsumerWidget {
  const CartPanel({
    super.key,
    required this.config,
    required this.onCheckout,
    required this.onHold,
    this.compact = false,
  });

  final PricingConfig config;
  final VoidCallback onCheckout;
  final VoidCallback onHold;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final pricing = cart.calculate(config);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: compact ? null : BorderRadius.circular(AppRadius.lg),
        border: compact ? null : Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Text('Pesanan', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(width: AppSpacing.sm),
                if (cart.itemCount > 0)
                  StatusChip(label: '${cart.itemCount} item', compact: true),
                const Spacer(),
                if (!cart.isEmpty)
                  TextButton.icon(
                    onPressed: () {
                      ref.read(cartProvider.notifier).clear();
                    },
                    icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                    label: const Text('Kosongkan'),
                  ),
              ],
            ),
          ),
          if (cart.isEmpty)
            const Expanded(
              child: AppEmptyState(
                icon: Icons.shopping_basket_outlined,
                title: 'Keranjang kosong',
                message: 'Pilih menu di katalog untuk memulai pesanan.',
              ),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: _OrderTypeSelector(cart: cart),
            ),
            if (cart.orderType == 'dine_in')
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  0,
                ),
                child: TextFormField(
                  initialValue: cart.tableNumber,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    isDense: true,
                    labelText: 'Nomor meja',
                    prefixIcon: Icon(Icons.table_restaurant_outlined),
                  ),
                  onChanged: (value) =>
                      ref.read(cartProvider.notifier).setTableNumber(value),
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xs,
                ),
                itemCount: cart.lines.length,
                separatorBuilder: (_, _) => const Divider(height: 16),
                itemBuilder: (context, index) {
                  final line = cart.lines[index];
                  return _CartLineTile(
                    line: line,
                    onIncrement: () =>
                        ref.read(cartProvider.notifier).increment(line.id),
                    onDecrement: () =>
                        ref.read(cartProvider.notifier).decrement(line.id),
                    onRemove: () =>
                        ref.read(cartProvider.notifier).removeLine(line.id),
                    onEdit: () => _editLine(context, ref, line),
                  );
                },
              ),
            ),
            if (pricing != null)
              _Totals(
                pricing: pricing,
                cart: cart,
                onDiscount: () => _editTransactionDiscount(context, ref, cart),
              ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                    onPressed: onHold,
                    icon: const Icon(Icons.pause_circle_outline_rounded),
                    label: const Text('Tahan pesanan'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FilledButton(
                    onPressed: onCheckout,
                    child: Text('Bayar · ${formatRupiah(pricing?.total ?? 0)}'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _editTransactionDiscount(
    BuildContext context,
    WidgetRef ref,
    CartState cart,
  ) async {
    final value = await _askAmount(
      context,
      title: 'Diskon transaksi',
      label: 'Nominal diskon',
      initial: cart.transactionDiscount,
      helper: 'Total diskon transaksi dalam rupiah.',
    );
    if (value == null) return;
    ref.read(cartProvider.notifier).setTransactionDiscount(value);
  }

  Future<void> _editLine(
    BuildContext context,
    WidgetRef ref,
    CartLine line,
  ) async {
    final quantity = TextEditingController(text: '${line.quantity}');
    final discount = TextEditingController(
      text: line.itemDiscount == 0 ? '' : '${line.itemDiscount}',
    );
    final notes = TextEditingController(text: line.notes ?? '');
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(line.productName, maxLines: 2),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: quantity,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                decoration: const InputDecoration(labelText: 'Jumlah'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: discount,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(9),
                ],
                decoration: const InputDecoration(
                  labelText: 'Diskon item',
                  prefixText: 'Rp ',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: notes,
                maxLength: 140,
                decoration: const InputDecoration(labelText: 'Catatan'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (result == true) {
      final notifier = ref.read(cartProvider.notifier);
      final parsedQuantity = int.tryParse(quantity.text) ?? line.quantity;
      if (parsedQuantity <= 0) {
        notifier.removeLine(line.id);
      } else {
        notifier.setQuantity(line.id, parsedQuantity);
      }
      notifier.setLineDiscount(line.id, int.tryParse(discount.text) ?? 0);
      notifier.setLineNotes(line.id, notes.text);
    }
    quantity.dispose();
    discount.dispose();
    notes.dispose();
  }
}

class _OrderTypeSelector extends ConsumerWidget {
  const _OrderTypeSelector({required this.cart});

  final CartState cart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: 'dine_in', label: Text('Dine-in')),
        ButtonSegment(value: 'take_away', label: Text('Bawa pulang')),
        ButtonSegment(value: 'delivery', label: Text('Antar')),
      ],
      selected: {cart.orderType},
      showSelectedIcon: false,
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        textStyle: WidgetStatePropertyAll(
          Theme.of(context).textTheme.labelSmall,
        ),
      ),
      onSelectionChanged: (value) =>
          ref.read(cartProvider.notifier).setOrderType(value.first),
    );
  }
}

class _CartLineTile extends StatelessWidget {
  const _CartLineTile({
    required this.line,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
    required this.onEdit,
  });

  final CartLine line;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final detail = [
      if (line.variantName != null) line.variantName!,
      if (line.addons.isNotEmpty)
        line.addons.map((addon) => addon.name).join(', '),
    ].join(' · ');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                line.productName,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              if (detail.isNotEmpty)
                Text(
                  detail,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
                ),
              if (line.notes != null && line.notes!.isNotEmpty)
                Text(
                  'Catatan: ${line.notes}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.coral),
                ),
              if (line.itemDiscount > 0)
                Text(
                  'Diskon -${formatRupiah(line.itemDiscount)}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.amber),
                ),
              const SizedBox(height: 4),
              Text(
                formatRupiah(line.gross - line.itemDiscount),
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: AppColors.forest),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: onDecrement,
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.remove_rounded, size: 18),
                    ),
                  ),
                  SizedBox(
                    width: 24,
                    child: Text(
                      '${line.quantity}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                  InkWell(
                    onTap: onIncrement,
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.add_rounded, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              iconSize: 18,
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'remove') onRemove();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Ubah item')),
                PopupMenuItem(value: 'remove', child: Text('Hapus')),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _Totals extends StatelessWidget {
  const _Totals({
    required this.pricing,
    required this.cart,
    required this.onDiscount,
  });

  final PricingResult pricing;
  final CartState cart;
  final VoidCallback onDiscount;

  @override
  Widget build(BuildContext context) {
    final rowStyle = Theme.of(context).textTheme.bodyMedium;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.outline)),
      ),
      child: Column(
        children: [
          _row(context, 'Subtotal', formatRupiah(pricing.subtotal), rowStyle),
          if (pricing.itemDiscountTotal > 0)
            _row(
              context,
              'Diskon item',
              '-${formatRupiah(pricing.itemDiscountTotal)}',
              rowStyle,
            ),
          InkWell(
            onTap: onDiscount,
            child: _row(
              context,
              cart.transactionDiscount > 0
                  ? 'Diskon transaksi'
                  : 'Tambah diskon transaksi',
              cart.transactionDiscount > 0
                  ? '-${formatRupiah(cart.transactionDiscount)}'
                  : 'Atur',
              rowStyle?.copyWith(color: AppColors.forest),
            ),
          ),
          if (pricing.serviceCharge > 0)
            _row(
              context,
              'Service charge',
              formatRupiah(pricing.serviceCharge),
              rowStyle,
            ),
          if (pricing.taxTotal > 0)
            _row(context, 'Pajak', formatRupiah(pricing.taxTotal), rowStyle),
          const Divider(height: 16),
          Row(
            children: [
              Text('Total', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Text(
                formatRupiah(pricing.total),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: AppColors.forestDark),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    String value,
    TextStyle? style,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(label, style: style?.copyWith(color: AppColors.inkMuted)),
          const Spacer(),
          Text(value, style: style),
        ],
      ),
    );
  }
}

Future<int?> _askAmount(
  BuildContext context, {
  required String title,
  required String label,
  int initial = 0,
  String? helper,
}) async {
  final controller = TextEditingController(
    text: initial == 0 ? '' : '$initial',
  );
  final result = await showDialog<int>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(9),
        ],
        decoration: InputDecoration(
          labelText: label,
          prefixText: 'Rp ',
          helperText: helper,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop(int.tryParse(controller.text) ?? 0),
          child: const Text('Simpan'),
        ),
      ],
    ),
  );
  controller.dispose();
  return result;
}
