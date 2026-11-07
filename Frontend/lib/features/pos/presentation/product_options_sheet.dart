import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/money.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/catalog.dart';
import '../state/cart_controller.dart';

Future<void> showProductOptions(BuildContext context, CatalogProduct product) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _ProductOptionsSheet(product: product),
  );
}

class _ProductOptionsSheet extends ConsumerStatefulWidget {
  const _ProductOptionsSheet({required this.product});

  final CatalogProduct product;

  @override
  ConsumerState<_ProductOptionsSheet> createState() =>
      _ProductOptionsSheetState();
}

class _ProductOptionsSheetState extends ConsumerState<_ProductOptionsSheet> {
  final _notes = TextEditingController();
  final Set<String> _addons = {};
  String? _variantUuid;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    final variants = widget.product.activeVariants;
    if (variants.length == 1) _variantUuid = variants.first.uuid;
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  int get _unitPrice =>
      widget.product.unitPrice(variantUuid: _variantUuid, addonUuids: _addons);

  bool get _needsVariant =>
      widget.product.activeVariants.isNotEmpty && _variantUuid == null;

  void _add() {
    final variants = widget.product.activeVariants;
    final variant = variants
        .where((item) => item.uuid == _variantUuid)
        .firstOrNull;
    final addons = widget.product.activeAddons
        .where((addon) => _addons.contains(addon.uuid))
        .map(
          (addon) =>
              CartAddon(uuid: addon.uuid, name: addon.name, price: addon.price),
        )
        .toList(growable: false);

    ref
        .read(cartProvider.notifier)
        .addLine(
          productUuid: widget.product.uuid,
          productName: widget.product.name,
          unitPrice: _unitPrice,
          variantUuid: variant?.uuid,
          variantName: variant?.name,
          addons: addons,
          taxRateBasisPoints: widget.product.taxRateBasisPoints,
          quantity: _quantity,
          notes: _notes.text,
        );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final variants = product.activeVariants;
    final addons = product.activeAddons;
    final total = _unitPrice * _quantity;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(product.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 2),
            Text(
              product.categoryName ?? 'Menu',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
            ),
            if (product.description != null &&
                product.description!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                product.description!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (variants.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Text(
                    'Pilih varian',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  const Text(
                    'wajib',
                    style: TextStyle(
                      color: AppColors.coral,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              for (final variant in variants)
                RadioListTile<String>(
                  value: variant.uuid,
                  // ignore: deprecated_member_use
                  groupValue: _variantUuid,
                  contentPadding: EdgeInsets.zero,
                  title: Text(variant.name),
                  subtitle: variant.priceDelta == 0
                      ? null
                      : Text(
                          '${variant.priceDelta > 0 ? '+' : ''}'
                          '${formatRupiah(variant.priceDelta)}',
                        ),
                  // ignore: deprecated_member_use
                  onChanged: (value) => setState(() => _variantUuid = value),
                ),
            ],
            if (addons.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text('Tambahan', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final addon in addons)
                    FilterChip(
                      label: Text(
                        '${addon.name} · ${formatRupiah(addon.price)}',
                      ),
                      selected: _addons.contains(addon.uuid),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _addons.add(addon.uuid);
                          } else {
                            _addons.remove(addon.uuid);
                          }
                        });
                      },
                    ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _notes,
              maxLength: 140,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
                hintText: 'Contoh: tanpa kacang, pedas sedang',
                prefixIcon: Icon(Icons.edit_note_rounded),
              ),
            ),
            Row(
              children: [
                Text('Jumlah', style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                _QuantityStepper(
                  value: _quantity,
                  onMinus: _quantity <= 1
                      ? null
                      : () => setState(() => _quantity--),
                  onPlus: _quantity >= 100
                      ? null
                      : () => setState(() => _quantity++),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: _needsVariant ? null : _add,
              child: Text('Tambah · ${formatRupiah(total)}'),
            ),
            if (_needsVariant) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Pilih varian terlebih dahulu.',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.danger),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({required this.value, this.onMinus, this.onPlus});

  final int value;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: onMinus,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.remove_rounded, size: 20),
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            onPressed: onPlus,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.add_rounded, size: 20),
          ),
        ],
      ),
    );
  }
}
