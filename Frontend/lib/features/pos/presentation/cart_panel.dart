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
    PricingResult? pricing;
    Object? pricingError;
    if (!cart.isEmpty) {
      try {
        pricing = cart.calculate(config);
      } catch (error) {
        // Never let invalid line data escape a widget build.
        pricingError = error;
      }
    }

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
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Pesanan',
                          style: Theme.of(context).textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      if (cart.itemCount > 0)
                        StatusChip(
                          label: '${cart.itemCount} item',
                          compact: true,
                        ),
                    ],
                  ),
                ),
                if (!cart.isEmpty)
                  TextButton.icon(
                    onPressed: () => _confirmClear(context, ref),
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
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: _OrderTypeSelector(cart: cart),
                    ),
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
                        onChanged: (value) => ref
                            .read(cartProvider.notifier)
                            .setTableNumber(value),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  for (var index = 0; index < cart.lines.length; index++) ...[
                    if (index > 0) const Divider(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.xs,
                      ),
                      child: _CartLineTile(
                        line: cart.lines[index],
                        onIncrement: () => ref
                            .read(cartProvider.notifier)
                            .increment(cart.lines[index].id),
                        onDecrement: () => ref
                            .read(cartProvider.notifier)
                            .decrement(cart.lines[index].id),
                        onRemove: () => _removeLineWithUndo(
                          context,
                          ref,
                          cart.lines[index],
                          index,
                        ),
                        onEdit: () =>
                            _editLine(context, ref, cart.lines[index]),
                      ),
                    ),
                  ],
                  if (pricingError != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.md,
                        AppSpacing.lg,
                        AppSpacing.sm,
                      ),
                      child: InfoBanner(
                        message:
                            'Perhitungan keranjang tidak valid. Periksa diskon '
                            'dan jumlah item sebelum melanjutkan.',
                        tone: StatusTone.danger,
                        icon: Icons.error_outline_rounded,
                      ),
                    )
                  else if (pricing != null)
                    _Totals(
                      pricing: pricing,
                      cart: cart,
                      onDiscount: () =>
                          _editTransactionDiscount(context, ref, cart),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                    onPressed: pricingError == null ? onHold : null,
                    icon: const Icon(Icons.pause_circle_outline_rounded),
                    label: const Text('Tahan pesanan'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FilledButton(
                    onPressed: pricing == null ? null : onCheckout,
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

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(cartProvider.notifier);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kosongkan keranjang?'),
        content: const Text(
          'Semua item, diskon, catatan, dan nomor meja pada pesanan ini akan '
          'dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Kosongkan'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    notifier.clear();
  }

  void _removeLineWithUndo(
    BuildContext context,
    WidgetRef ref,
    CartLine line,
    int index,
  ) {
    final notifier = ref.read(cartProvider.notifier);
    notifier.removeLine(line.id);
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${line.productName} dihapus.'),
          action: SnackBarAction(
            label: 'Urungkan',
            onPressed: () => notifier.insertLine(index, line),
          ),
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
    final result = await showDialog<_LineEditResult>(
      context: context,
      builder: (_) => _EditLineDialog(line: line),
    );
    if (result == null) return;

    final notifier = ref.read(cartProvider.notifier);
    if (result.quantity <= 0) {
      notifier.removeLine(line.id);
    } else {
      notifier.setQuantity(line.id, result.quantity);
    }
    notifier.setLineDiscount(line.id, result.discount);
    notifier.setLineNotes(line.id, result.notes);
  }
}

class _LineEditResult {
  const _LineEditResult({
    required this.quantity,
    required this.discount,
    required this.notes,
  });

  final int quantity;
  final int discount;
  final String notes;
}

class _EditLineDialog extends StatefulWidget {
  const _EditLineDialog({required this.line});

  final CartLine line;

  @override
  State<_EditLineDialog> createState() => _EditLineDialogState();
}

class _EditLineDialogState extends State<_EditLineDialog> {
  late final TextEditingController _quantity = TextEditingController(
    text: '${widget.line.quantity}',
  );
  late final TextEditingController _discount = TextEditingController(
    text: widget.line.itemDiscount == 0 ? '' : '${widget.line.itemDiscount}',
  );
  late final TextEditingController _notes = TextEditingController(
    text: widget.line.notes ?? '',
  );

  @override
  void dispose() {
    _quantity.dispose();
    _discount.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _save() {
    Navigator.of(context).pop(
      _LineEditResult(
        quantity: int.tryParse(_quantity.text) ?? widget.line.quantity,
        discount: int.tryParse(_discount.text) ?? 0,
        notes: _notes.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.line.productName, maxLines: 2),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _quantity,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
              decoration: const InputDecoration(labelText: 'Jumlah'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _discount,
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
              controller: _notes,
              maxLength: 140,
              decoration: const InputDecoration(labelText: 'Catatan'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(onPressed: _save, child: const Text('Simpan')),
      ],
    );
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
                  IconButton(
                    onPressed: onDecrement,
                    tooltip: 'Kurangi jumlah',
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                    icon: const Icon(Icons.remove_rounded, size: 18),
                  ),
                  SizedBox(
                    width: 24,
                    child: Text(
                      '${line.quantity}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: onIncrement,
                    tooltip: 'Tambah jumlah',
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                    icon: const Icon(Icons.add_rounded, size: 18),
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
              Expanded(
                child: Text(
                  'Total',
                  style: Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
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
          Expanded(
            child: Text(
              label,
              style: style?.copyWith(color: AppColors.inkMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
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
}) {
  return showDialog<int>(
    context: context,
    builder: (_) => _AmountDialog(
      title: title,
      label: label,
      initial: initial,
      helper: helper,
    ),
  );
}

class _AmountDialog extends StatefulWidget {
  const _AmountDialog({
    required this.title,
    required this.label,
    required this.initial,
    this.helper,
  });

  final String title;
  final String label;
  final int initial;
  final String? helper;

  @override
  State<_AmountDialog> createState() => _AmountDialogState();
}

class _AmountDialogState extends State<_AmountDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial == 0 ? '' : '${widget.initial}',
  );

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
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(9),
        ],
        decoration: InputDecoration(
          labelText: widget.label,
          prefixText: 'Rp ',
          helperText: widget.helper,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop(int.tryParse(_controller.text) ?? 0),
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
