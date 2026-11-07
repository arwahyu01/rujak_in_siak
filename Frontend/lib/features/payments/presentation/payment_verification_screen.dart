import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/format/dates.dart';
import '../../../core/format/labels.dart';
import '../../../core/format/money.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../data/session/session_controller.dart';
import '../data/payment_api.dart';

class PaymentVerificationScreen extends ConsumerStatefulWidget {
  const PaymentVerificationScreen({super.key});

  @override
  ConsumerState<PaymentVerificationScreen> createState() =>
      _PaymentVerificationScreenState();
}

class _PaymentVerificationScreenState
    extends ConsumerState<PaymentVerificationScreen> {
  List<PendingPayment> _payments = const [];
  bool _loading = true;
  bool _busy = false;
  AppException? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final user = ref.read(sessionProvider).value?.user;
    if (user != null &&
        !user.canAny(const ['payments.view_pending', 'payments.verify'])) {
      setState(() {
        _loading = false;
        _error = const AppException(
          'FORBIDDEN',
          'Akun ini tidak memiliki akses memverifikasi pembayaran.',
        );
      });
      return;
    }
    try {
      final payments = await ref.read(paymentApiProvider).pending();
      if (!mounted) return;
      setState(() {
        _payments = payments;
        _loading = false;
        _error = null;
      });
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = AppException.unknown(error);
      });
    }
  }

  Future<void> _verify(PendingPayment payment) async {
    final user = ref.read(sessionProvider).value?.user;
    if (user == null || !user.can('payments.verify')) return;
    if (payment.recordedByUuid != null && payment.recordedByUuid == user.uuid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pembayaran yang Anda catat sendiri tidak dapat Anda verifikasi.',
          ),
        ),
      );
      return;
    }
    if (payment.proofRequired && !payment.hasProof) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bukti pembayaran wajib diunggah sebelum pembayaran ini '
            'diverifikasi.',
          ),
        ),
      );
      return;
    }
    final input = await showDialog<_VerifyInput>(
      context: context,
      builder: (context) => _VerifyDialog(payment: payment),
    );
    if (input == null) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(paymentApiProvider)
          .verify(
            payment.uuid,
            verifiedAmount: input.amount,
            providerReference: input.reference,
            note: input.note,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pembayaran berhasil diverifikasi.')),
      );
      await _refreshSales(payment.saleUuid);
      await _load();
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reject(PendingPayment payment) async {
    final user = ref.read(sessionProvider).value?.user;
    if (user == null || !user.can('payments.reject')) return;
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => _RejectDialog(payment: payment),
    );
    if (reason == null || reason.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(paymentApiProvider)
          .reject(payment.uuid, reason: reason.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pembayaran ditolak.')));
      await _refreshSales(payment.saleUuid);
      await _load();
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refreshSales(String? saleUuid) async {
    if (saleUuid == null) return;
    try {
      final record = await ref
          .read(saleRepositoryProvider)
          .fetchRemote(saleUuid);
      if (record != null) {
        await ref.read(saleRepositoryProvider).saveRemoteSale(record);
      }
    } catch (_) {
      // The sale cache refreshes on the next pull or detail open.
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(sessionProvider).value?.user;
    final canVerify = user?.can('payments.verify') ?? false;
    final canReject = user?.can('payments.reject') ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verifikasi pembayaran'),
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
                  'Pembayaran QRIS, transfer, dan e-wallet berstatus menunggu '
                  'verifikasi sampai dikonfirmasi. Anda tidak dapat memverifikasi '
                  'pembayaran yang Anda catat sendiri.',
              tone: StatusTone.info,
              icon: Icons.verified_user_outlined,
            ),
            const SizedBox(height: AppSpacing.md),
            if (_error != null) ...[
              InfoBanner(
                message: _error!.message,
                tone: StatusTone.danger,
                icon: Icons.error_outline_rounded,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: AppSpacing.xxl),
                child: AppLoading(label: 'Memuat pembayaran…'),
              )
            else if (_payments.isEmpty)
              const AppEmptyState(
                icon: Icons.task_alt_rounded,
                title: 'Tidak ada pembayaran tertunda',
                message:
                    'Semua pembayaran non-tunai sudah diverifikasi atau ditolak.',
              )
            else
              for (final payment in _payments)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _PaymentVerificationCard(
                    payment: payment,
                    busy: _busy,
                    isOwnPayment:
                        payment.recordedByUuid != null &&
                        payment.recordedByUuid == user?.uuid,
                    canVerify: canVerify,
                    canReject: canReject,
                    onVerify: () => _verify(payment),
                    onReject: () => _reject(payment),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _PaymentVerificationCard extends StatelessWidget {
  const _PaymentVerificationCard({
    required this.payment,
    required this.busy,
    required this.isOwnPayment,
    required this.canVerify,
    required this.canReject,
    required this.onVerify,
    required this.onReject,
  });

  final PendingPayment payment;
  final bool busy;
  final bool isOwnPayment;
  final bool canVerify;
  final bool canReject;
  final VoidCallback onVerify;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
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
                        payment.receiptNumber ?? 'Tanpa nomor struk',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        [
                          formatDateTime(payment.recordedAt),
                          payment.recordedByName ?? '-',
                        ].join(' · '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  formatRupiah(payment.amount),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              [
                paymentMethodLabel(payment.method),
                paymentStatusLabel(payment.status),
              ].join(' · '),
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.inkMuted,
              ),
            ),
            if (payment.providerReference != null &&
                payment.providerReference!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Catatan: ${payment.providerReference}',
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (payment.notes != null && payment.notes!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                payment.notes!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.inkMuted,
                ),
              ),
            ],
            if (payment.hasProof) ...[
              const SizedBox(height: AppSpacing.sm),
              _ProofPreview(uuid: payment.uuid),
            ],
            if (payment.proofRequired && !payment.hasProof) ...[
              const SizedBox(height: AppSpacing.sm),
              const InfoBanner(
                message:
                    'Bukti pembayaran wajib diunggah sebelum pembayaran ini '
                    'dapat diverifikasi.',
                tone: StatusTone.danger,
                icon: Icons.image_not_supported_outlined,
              ),
            ],
            if (isOwnPayment) ...[
              const SizedBox(height: AppSpacing.sm),
              const InfoBanner(
                message:
                    'Anda mencatat pembayaran ini. Minta kasir lain memverifikasi.',
                tone: StatusTone.warning,
                icon: Icons.person_off_outlined,
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                if (canReject)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: busy ? null : onReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                      ),
                      child: const Text('Tolak'),
                    ),
                  ),
                if (canReject && canVerify)
                  const SizedBox(width: AppSpacing.sm),
                if (canVerify)
                  Expanded(
                    child: FilledButton(
                      onPressed: busy ||
                              isOwnPayment ||
                              (payment.proofRequired && !payment.hasProof)
                          ? null
                          : onVerify,
                      child: const Text('Verifikasi'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProofPreview extends ConsumerStatefulWidget {
  const _ProofPreview({required this.uuid});

  final String uuid;

  @override
  ConsumerState<_ProofPreview> createState() => _ProofPreviewState();
}

class _ProofPreviewState extends ConsumerState<_ProofPreview> {
  late Future<Uint8List> _future = _load();

  Future<Uint8List> _load() => ref.read(paymentApiProvider).proof(widget.uuid);

  void _retry() {
    setState(() => _future = _load());
  }

  void _open(Uint8List bytes) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(AppSpacing.sm),
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 5,
                child: Center(child: Image.memory(bytes)),
              ),
            ),
            Positioned(
              top: AppSpacing.xs,
              right: AppSpacing.xs,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Tutup',
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Bukti pembayaran',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        FutureBuilder<Uint8List>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.sm),
                child: LinearProgressIndicator(),
              );
            }
            final bytes = snapshot.data;
            if (snapshot.hasError || bytes == null) {
              return Row(
                children: [
                  const Expanded(child: Text('Bukti tidak dapat dimuat.')),
                  TextButton(
                    onPressed: _retry,
                    child: const Text('Muat ulang bukti'),
                  ),
                ],
              );
            }
            return InkWell(
              onTap: () => _open(bytes),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Image.memory(
                  bytes,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _VerifyInput {
  const _VerifyInput({required this.amount, this.reference, this.note});

  final int amount;
  final String? reference;
  final String? note;
}

class _VerifyDialog extends StatefulWidget {
  const _VerifyDialog({required this.payment});

  final PendingPayment payment;

  @override
  State<_VerifyDialog> createState() => _VerifyDialogState();
}

class _VerifyDialogState extends State<_VerifyDialog> {
  late final TextEditingController _amount = TextEditingController(
    text: '${widget.payment.amount}',
  );
  late final TextEditingController _reference = TextEditingController(
    text: widget.payment.providerReference ?? '',
  );
  final TextEditingController _note = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    _note.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = int.tryParse(_amount.text.replaceAll(RegExp(r'\D'), ''));
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Nominal verifikasi tidak valid.');
      return;
    }
    if (amount > widget.payment.amount) {
      setState(() => _error = 'Nominal melebihi pembayaran yang dicatat.');
      return;
    }
    Navigator.of(context).pop(
      _VerifyInput(
        amount: amount,
        reference: _reference.text,
        note: _note.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Verifikasi pembayaran'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${paymentMethodLabel(widget.payment.method)} · '
              '${formatRupiah(widget.payment.amount)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _amount,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Nominal terverifikasi',
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _reference,
              decoration: const InputDecoration(
                labelText: 'Catatan pembayaran (opsional)',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _note,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
              ),
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
        FilledButton(onPressed: _submit, child: const Text('Verifikasi')),
      ],
    );
  }
}

class _RejectDialog extends StatefulWidget {
  const _RejectDialog({required this.payment});

  final PendingPayment payment;

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final TextEditingController _reason = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _submit() {
    if (_reason.text.trim().isEmpty) {
      setState(() => _error = 'Alasan penolakan wajib diisi.');
      return;
    }
    Navigator.of(context).pop(_reason.text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tolak pembayaran'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${paymentMethodLabel(widget.payment.method)} · '
            '${formatRupiah(widget.payment.amount)}',
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _reason,
            autofocus: true,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Alasan penolakan'),
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
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
          onPressed: _submit,
          child: const Text('Tolak'),
        ),
      ],
    );
  }
}
