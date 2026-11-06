import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/format/labels.dart';
import '../../../core/format/money.dart';
import '../../../core/pricing/pricing_calculator.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../data/bootstrap/bootstrap_controller.dart';
import '../../../data/models/sale.dart';
import '../../../data/repositories/bootstrap_repository.dart';
import '../../../data/session/session_controller.dart';
import '../../../data/shifts/shift_controller.dart';
import '../../../data/sync/sync_controller.dart';
import '../../pos/state/cart_controller.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final List<_PaymentDraft> _drafts = [];
  bool _submitting = false;
  AppException? _error;
  bool _serverOrderPending = false;
  bool _initialised = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialise());
  }

  void _initialise() {
    if (_initialised) return;
    _initialised = true;
    final snapshot = ref.read(bootstrapProvider).value?.snapshot;
    final cart = ref.read(cartProvider);
    final pricing = cart.calculate(
      snapshot?.data?.pricingConfig ?? const PricingConfig(),
    );
    if (pricing == null) return;
    final methods = _methods(snapshot?.data?.paymentMethods ?? const []);
    final draft = _PaymentDraft(
      method: methods.contains('cash') ? 'cash' : methods.first,
      amount: pricing.total,
      tendered: pricing.total,
    );
    draft.attach(() {
      if (mounted) setState(() {});
    });
    _drafts.add(draft);
    setState(() {});
  }

  List<String> _methods(List<String> configured) {
    const allowed = {'cash', 'qris', 'transfer', 'ewallet'};
    final values = configured.where(allowed.contains).toList();
    return values.isEmpty ? const ['cash'] : values;
  }

  @override
  void dispose() {
    for (final draft in _drafts) {
      draft.dispose();
    }
    super.dispose();
  }

  bool get _isSplit => _drafts.length > 1;

  int _sum() {
    var total = 0;
    for (final draft in _drafts) {
      total += _isSplit ? draft.amountValue : _total;
    }
    return total;
  }

  int get _total {
    final snapshot = ref.read(bootstrapProvider).value?.snapshot;
    final cart = ref.read(cartProvider);
    return cart.totalFor(
      snapshot?.data?.pricingConfig ?? const PricingConfig(),
    );
  }

  void _addDraft() {
    final remaining = _total - _sum();
    final methods = _methods(
      ref.read(bootstrapProvider).value?.data?.paymentMethods ?? const [],
    );
    final draft = _PaymentDraft(
      method: methods.contains('transfer')
          ? 'transfer'
          : (methods.length > 1 ? methods[1] : methods.first),
      amount: remaining > 0 ? remaining : 0,
    );
    draft.attach(() {
      if (mounted) setState(() {});
    });
    setState(() {
      _drafts.add(draft);
    });
  }

  void _removeDraft(_PaymentDraft draft) {
    if (_drafts.length <= 1) return;
    setState(() {
      _drafts.remove(draft);
    });
    draft.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final snapshot = ref.read(bootstrapProvider).value?.snapshot;
    final data = snapshot?.data;
    final cart = ref.read(cartProvider);
    final shift = ref.read(shiftProvider).value?.shift;
    final session = ref.read(sessionProvider).value;

    if (data == null || session == null || shift == null) {
      setState(
        () => _error = const AppException(
          'CHECKOUT_NOT_READY',
          'Data kasir belum siap. Muat ulang aplikasi.',
        ),
      );
      return;
    }
    final pricing = cart.calculate(data.pricingConfig);
    if (pricing == null) return;

    final drafts = <LocalPaymentDraft>[];
    var sum = 0;
    for (final draft in _drafts) {
      final amount = _isSplit ? draft.amountValue : pricing.total;
      if (amount <= 0) {
        setState(
          () => _error = const AppException(
            'PAYMENT_AMOUNT_INVALID',
            'Nominal setiap pembayaran harus lebih besar dari nol.',
          ),
        );
        return;
      }
      if (draft.method == 'cash') {
        final tendered = draft.tenderedValue ?? amount;
        if (tendered < amount) {
          setState(
            () => _error = const AppException(
              'CASH_TENDERED_INSUFFICIENT',
              'Uang tunai diterima kurang dari nominal pembayaran.',
            ),
          );
          return;
        }
      } else if (draft.reference.text.trim().isEmpty) {
        setState(
          () => _error = const AppException(
            'PROVIDER_REFERENCE_REQUIRED',
            'Referensi pembayaran non-tunai wajib diisi.',
          ),
        );
        return;
      }
      sum += amount;
      drafts.add(
        LocalPaymentDraft(
          method: draft.method,
          amount: amount,
          tenderedAmount: draft.method == 'cash'
              ? draft.tenderedValue ?? amount
              : null,
          providerReference: draft.method == 'cash'
              ? null
              : draft.reference.text.trim(),
        ),
      );
    }

    if (sum != pricing.total) {
      setState(
        () => _error = AppException(
          'PAYMENT_TOTAL_MISMATCH',
          'Total pembayaran ${formatRupiah(sum)} belum sama dengan total '
              'transaksi ${formatRupiah(pricing.total)}.',
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi pembayaran'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final draft in drafts)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(paymentMethodLabel(draft.method))),
                    Text(formatRupiah(draft.amount)),
                  ],
                ),
              ),
            const Divider(),
            Row(
              children: [
                Text('Total', style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                Text(
                  formatRupiah(pricing.total),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              drafts.any((payment) => payment.method != 'cash')
                  ? 'Pembayaran non-tunai akan berstatus menunggu verifikasi.'
                  : 'Pembayaran tunai langsung dikonfirmasi.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Periksa lagi'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Proses'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final outcome = await ref
          .read(saleRepositoryProvider)
          .checkout(
            cart: cart,
            pricing: pricing,
            payments: drafts,
            shift: shift,
            snapshot: snapshot!,
            session: session,
          );
      if (!mounted) return;
      ref.read(cartProvider.notifier).clear();
      await ref.read(shiftProvider.notifier).refresh();
      try {
        await ref.read(syncProvider.notifier).refreshStatus();
      } catch (_) {
        // Status is informational only; checkout already succeeded.
      }
      if (!mounted) return;
      context.pushReplacement('/receipt', extra: outcome);
    } on AppException catch (error) {
      if (!mounted) return;
      final orderUuid = error.details?['order_uuid'];
      final orderVersion = error.details?['order_version'];
      if (orderUuid is String && orderUuid.isNotEmpty) {
        ref
            .read(cartProvider.notifier)
            .linkServerOrder(
              uuid: orderUuid,
              version: orderVersion is num ? orderVersion.toInt() : 1,
            );
      }
      setState(() {
        _error = error;
        _serverOrderPending = error.code == 'CHECKOUT_UNCONFIRMED';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = AppException.unknown(error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bootstrap = ref.watch(bootstrapProvider).value;
    final snapshot = bootstrap?.snapshot;
    final data = snapshot?.data;
    final cart = ref.watch(cartProvider);
    final session = ref.watch(sessionProvider).value;
    final shift = ref.watch(shiftProvider).value?.shift;
    final config = data?.pricingConfig;
    final pricing = config == null ? null : cart.calculate(config);

    if (pricing == null || data == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pembayaran')),
        body: AppEmptyState(
          icon: Icons.shopping_cart_outlined,
          title: 'Tidak ada transaksi',
          message: 'Keranjang kosong atau data katalog belum tersedia.',
          action: FilledButton(
            onPressed: () => context.go('/pos'),
            child: const Text('Kembali ke kasir'),
          ),
        ),
      );
    }

    final sum = _sum();
    final remaining = pricing.total - sum;
    final offlineReady =
        session?.leaseValid == true &&
        snapshot!.freshness != CatalogFreshness.expired;

    return PopScope(
      canPop: !_serverOrderPending,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || !_serverOrderPending) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Penyelesaian transaksi harus dicoba lagi agar tidak terjadi '
              'pesanan ganda. Periksa koneksi lalu tekan Proses.',
            ),
          ),
        );
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pembayaran'),
          leading: IconButton(
            onPressed: _serverOrderPending
                ? null
                : () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.close_rounded),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: Center(
                child: StatusChip(
                  label: 'Shift ${shift?.isOpen == true ? 'aktif' : '-'}',
                  tone: StatusTone.neutral,
                  compact: true,
                ),
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.forestDark,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total tagihan',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatRupiah(pricing.total),
                    style: Theme.of(
                      context,
                    ).textTheme.displaySmall?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${cart.itemCount} item · ${orderTypeLabel(cart.orderType)}'
                    '${cart.tableNumber == null ? '' : ' · Meja ${cart.tableNumber}'}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (_error != null) ...[
              InfoBanner(
                message: _error!.message,
                tone: StatusTone.danger,
                icon: Icons.error_outline_rounded,
              ),
              if (_serverOrderPending)
                const Padding(
                  padding: EdgeInsets.only(top: AppSpacing.sm),
                  child: InfoBanner(
                    message:
                        'Order sudah tercatat di server. Jangan menutup layar ini; '
                        'periksa koneksi lalu proses kembali agar transaksi tidak ganda.',
                    tone: StatusTone.warning,
                    icon: Icons.sync_problem_rounded,
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
            ],
            if (!offlineReady)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: InfoBanner(
                  message: session?.leaseValid != true
                      ? 'Lease offline tidak valid. Transaksi hanya bisa diproses online.'
                      : 'Katalog lokal kedaluwarsa. Transaksi offline diblokir.',
                  tone: StatusTone.warning,
                  icon: Icons.cloud_off_rounded,
                ),
              ),
            Row(
              children: [
                Text(
                  'Pembayaran',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                if (_drafts.length > 1)
                  const StatusChip(
                    label: 'Split pembayaran',
                    tone: StatusTone.info,
                    icon: Icons.call_split_rounded,
                    compact: true,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final draft in _drafts)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _PaymentCard(
                  draft: draft,
                  methods: _methods(data.paymentMethods),
                  split: _isSplit,
                  total: pricing.total,
                  onChanged: () => setState(() {}),
                  onRemove: _drafts.length > 1
                      ? () => _removeDraft(draft)
                      : null,
                ),
              ),
            OutlinedButton.icon(
              onPressed: _drafts.length >= 5 ? null : _addDraft,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tambah pembayaran'),
            ),
            const SizedBox(height: AppSpacing.lg),
            _PaymentSummary(
              total: pricing.total,
              paid: sum,
              remaining: remaining,
              split: _isSplit,
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : Text('Proses pembayaran · ${formatRupiah(pricing.total)}'),
            ),
          ),
        ),
      ),
    );
  }
}

class _PaymentDraft {
  _PaymentDraft({required this.method, required int amount, int? tendered})
    : amount = TextEditingController(text: amount == 0 ? '' : '$amount'),
      tendered = TextEditingController(
        text: tendered == null || tendered == 0 ? '' : '$tendered',
      );

  String method;
  final TextEditingController amount;
  final TextEditingController tendered;
  final TextEditingController reference = TextEditingController();
  VoidCallback? _listener;

  int get amountValue => int.tryParse(amount.text) ?? 0;
  int? get tenderedValue {
    final value = int.tryParse(tendered.text);
    return value;
  }

  int get change {
    final parsed = tenderedValue;
    if (parsed == null) return 0;
    return parsed > amountValue ? parsed - amountValue : 0;
  }

  void attach(VoidCallback listener) {
    _listener = listener;
    amount.addListener(listener);
  }

  void dispose() {
    if (_listener != null) amount.removeListener(_listener!);
    amount.dispose();
    tendered.dispose();
    reference.dispose();
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.draft,
    required this.methods,
    required this.split,
    required this.total,
    required this.onChanged,
    this.onRemove,
  });

  final _PaymentDraft draft;
  final List<String> methods;
  final bool split;
  final int total;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final isCash = draft.method == 'cash';
    final amount = split ? draft.amountValue : total;
    final quick = _quickAmounts(amount);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: draft.method,
                    decoration: const InputDecoration(
                      labelText: 'Metode',
                      isDense: true,
                    ),
                    items: [
                      for (final method in methods)
                        DropdownMenuItem(
                          value: method,
                          child: Text(paymentMethodLabel(method)),
                        ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      draft.method = value;
                      onChanged();
                    },
                  ),
                ),
                if (onRemove != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  IconButton(
                    onPressed: onRemove,
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                    tooltip: 'Hapus pembayaran',
                  ),
                ],
              ],
            ),
            if (split) ...[
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: draft.amount,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(9),
                ],
                decoration: const InputDecoration(
                  labelText: 'Nominal',
                  prefixText: 'Rp ',
                  isDense: true,
                ),
                onChanged: (_) => onChanged(),
              ),
            ],
            if (isCash) ...[
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: draft.tendered,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(9),
                ],
                decoration: const InputDecoration(
                  labelText: 'Uang diterima',
                  prefixText: 'Rp ',
                  isDense: true,
                ),
                onChanged: (_) => onChanged(),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  ActionChip(
                    label: Text('Uang pas ${formatRupiah(amount)}'),
                    onPressed: () {
                      draft.tendered.text = '$amount';
                      onChanged();
                    },
                  ),
                  for (final value in quick)
                    ActionChip(
                      label: Text(formatRupiah(value)),
                      onPressed: () {
                        draft.tendered.text = '$value';
                        onChanged();
                      },
                    ),
                ],
              ),
              if (draft.change > 0)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(
                    'Kembalian ${formatRupiah(draft.change)}',
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(color: AppColors.forest),
                  ),
                ),
            ] else ...[
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: draft.reference,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Referensi pembayaran',
                  hintText: 'Nomor transaksi QRIS/transfer/e-wallet',
                  prefixIcon: Icon(Icons.numbers_rounded),
                  isDense: true,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Akan tercatat menunggu verifikasi sampai dikonfirmasi backend.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<int> _quickAmounts(int amount) {
    final values = <int>{};
    for (final step in [5000, 10000, 20000, 50000, 100000]) {
      final rounded = ((amount + step - 1) ~/ step) * step;
      if (rounded > amount) values.add(rounded);
    }
    if (amount > 0 && amount % 1000 != 0) values.add(amount + 1000);
    final sorted = values.toList()..sort();
    return sorted.take(4).toList();
  }
}

class _PaymentSummary extends StatelessWidget {
  const _PaymentSummary({
    required this.total,
    required this.paid,
    required this.remaining,
    required this.split,
  });

  final int total;
  final int paid;
  final int remaining;
  final bool split;

  @override
  Widget build(BuildContext context) {
    final balanced = remaining == 0;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: balanced ? AppColors.forestSoft : AppColors.amberSoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(
            balanced
                ? Icons.check_circle_outline_rounded
                : Icons.info_outline_rounded,
            color: balanced ? AppColors.forest : AppColors.amber,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              balanced
                  ? (split
                        ? 'Nominal pembayaran sudah sesuai total.'
                        : 'Siap diproses.')
                  : remaining > 0
                  ? 'Kurang ${formatRupiah(remaining)} dari total.'
                  : 'Lebih ${formatRupiah(remaining.abs())} dari total.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: balanced ? AppColors.forestDark : AppColors.amber,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
