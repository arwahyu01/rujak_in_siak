import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/format/dates.dart';
import '../../../core/format/labels.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../data/session/session_controller.dart';
import '../../../data/sync/sync_controller.dart';
import '../../../data/shifts/shift_controller.dart';
import '../../../data/sync/sync_repository.dart';

class SyncScreen extends ConsumerStatefulWidget {
  const SyncScreen({super.key});

  @override
  ConsumerState<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends ConsumerState<SyncScreen> {
  SyncStatusSnapshot? _status;
  List<OutboxIssue> _issues = const [];
  bool _loading = true;
  bool _running = false;
  AppException? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      final repository = ref.read(syncRepositoryProvider);
      final status = await repository.status();
      final issues = await repository.issues(limit: 50);
      if (!mounted) return;
      setState(() {
        _status = status;
        _issues = issues;
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

  Future<void> _syncNow() async {
    if (_running) return;
    final session = ref.read(sessionProvider).value;
    if (session == null) return;

    String? pin;
    String? password;
    if (!session.leaseValid) {
      final credentials = await showDialog<_LeaseCredentials>(
        context: context,
        builder: (context) => const _LeaseDialog(),
      );
      if (credentials == null) return;
      pin = credentials.pin;
      password = credentials.password;
    }

    setState(() {
      _running = true;
      _error = null;
    });
    try {
      final report = await ref
          .read(syncProvider.notifier)
          .syncNow(pin: pin, password: password);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sinkron selesai · ${report.accepted} terkirim, '
            '${report.pulled} diperbarui'
            '${report.conflicts > 0 ? ', ${report.conflicts} konflik' : ''}.',
          ),
        ),
      );
      await _load();
      try {
        await ref.read(shiftProvider.notifier).refresh();
      } catch (_) {
        // Shift refresh is best-effort after a sync.
      }
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = AppException.unknown(error));
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider).value;
    final user = session?.user;
    final canViewIssues = user?.can('sync.view') ?? false;
    final status = _status;
    final online = ref.watch(connectivityProvider).value ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sinkronisasi'),
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
            if (!online)
              const Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.md),
                child: InfoBanner(
                  message:
                      'Tidak ada koneksi. Transaksi tetap tersimpan dan akan '
                      'dikirim saat jaringan tersedia.',
                  tone: StatusTone.warning,
                  icon: Icons.wifi_off_rounded,
                ),
              ),
            if (session != null && !session.leaseValid)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: InfoBanner(
                  message:
                      'Lisensi offline telah berakhir. Sinkronisasi memerlukan '
                      'PIN atau kata sandi untuk memperbarui lisensi.',
                  tone: StatusTone.danger,
                  icon: Icons.timer_off_rounded,
                ),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: InfoBanner(
                  message: _error!.message,
                  tone: StatusTone.danger,
                  icon: Icons.error_outline_rounded,
                ),
              ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: AppSpacing.xxl),
                child: AppLoading(label: 'Memuat status sinkronisasi…'),
              )
            else if (status != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              status.isClean
                                  ? 'Semua data tersinkron'
                                  : '${status.total} data menunggu sinkron',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          StatusChip(
                            label: status.isClean ? 'Bersih' : 'Tertunda',
                            tone: status.isClean
                                ? StatusTone.success
                                : StatusTone.warning,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          _CountPill(
                            label: 'Antre',
                            value: status.pending,
                            tone: status.pending == 0
                                ? StatusTone.neutral
                                : StatusTone.warning,
                          ),
                          _CountPill(
                            label: 'Tertahan',
                            value: status.blocked,
                            tone: status.blocked == 0
                                ? StatusTone.neutral
                                : StatusTone.info,
                          ),
                          _CountPill(
                            label: 'Konflik',
                            value: status.conflicts,
                            tone: status.conflicts == 0
                                ? StatusTone.neutral
                                : StatusTone.danger,
                          ),
                          _CountPill(
                            label: 'Ditolak',
                            value: status.rejected,
                            tone: status.rejected == 0
                                ? StatusTone.neutral
                                : StatusTone.danger,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Terkirim terakhir: ${relativeTime(status.lastPushedAt)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.inkMuted,
                        ),
                      ),
                      Text(
                        'Diperbarui terakhir: ${relativeTime(status.lastPulledAt)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.inkMuted,
                        ),
                      ),
                      Text(
                        'Katalog: ${relativeTime(status.catalogSyncedAt)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.inkMuted,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      FilledButton.icon(
                        onPressed: _running || !online ? null : _syncNow,
                        icon: _running
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.sync_rounded),
                        label: Text(
                          _running ? 'Menyinkronkan…' : 'Sinkron sekarang',
                        ),
                      ),
                      if (!online)
                        const Padding(
                          padding: EdgeInsets.only(top: AppSpacing.sm),
                          child: Text(
                            'Sambungkan ke internet untuk memulai sinkronisasi.',
                            style: TextStyle(
                              color: AppColors.inkMuted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Peristiwa lokal',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  Text(
                    '${_issues.length} item',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              if (!canViewIssues)
                const InfoBanner(
                  message:
                      'Rincian antrean hanya tersedia untuk akun dengan izin '
                      'melihat sinkronisasi.',
                  tone: StatusTone.neutral,
                  icon: Icons.lock_outline_rounded,
                )
              else if (_issues.isEmpty)
                const AppEmptyState(
                  icon: Icons.cloud_done_outlined,
                  title: 'Tidak ada peristiwa tertunda',
                  message: 'Semua perubahan lokal sudah dikirim ke server.',
                )
              else
                for (final issue in _issues)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _IssueTile(issue: issue),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({
    required this.label,
    required this.value,
    required this.tone,
  });

  final String label;
  final int value;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: switch (tone) {
                StatusTone.success => AppColors.forest,
                StatusTone.warning => AppColors.amber,
                StatusTone.danger => AppColors.danger,
                StatusTone.info => AppColors.info,
                StatusTone.neutral => AppColors.inkMuted,
              },
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$value',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
          ),
        ],
      ),
    );
  }
}

class _IssueTile extends StatelessWidget {
  const _IssueTile({required this.issue});

  final OutboxIssue issue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '#${issue.sequence} · ${issue.eventType}',
                    style: theme.textTheme.labelLarge,
                  ),
                ),
                StatusChip(
                  label: outboxStatusLabel(issue.status),
                  tone: outboxStatusTone(issue.status),
                  compact: true,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${formatDateTime(issue.occurredAt)} · '
              '${issue.attempts}x percobaan',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.inkMuted,
              ),
            ),
            if (issue.lastError != null && issue.lastError!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                issue.lastError!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.danger,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LeaseCredentials {
  const _LeaseCredentials({this.pin, this.password});

  final String? pin;
  final String? password;
}

class _LeaseDialog extends StatefulWidget {
  const _LeaseDialog();

  @override
  State<_LeaseDialog> createState() => _LeaseDialogState();
}

class _LeaseDialogState extends State<_LeaseDialog> {
  final TextEditingController _pin = TextEditingController();
  final TextEditingController _password = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _pin.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    final pin = _pin.text.trim();
    final password = _password.text;
    if (pin.isEmpty && password.isEmpty) {
      setState(() => _error = 'Masukkan PIN atau kata sandi Anda.');
      return;
    }
    Navigator.of(context).pop(
      _LeaseCredentials(
        pin: pin.isEmpty ? null : pin,
        password: password.isEmpty ? null : password,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Perbarui lisensi offline'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Lisensi offline diperlukan untuk transaksi tanpa internet. '
            'Verifikasi dengan PIN kasir atau kata sandi akun.',
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _pin,
            keyboardType: TextInputType.number,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'PIN kasir'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Kata sandi akun'),
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
        FilledButton(onPressed: _submit, child: const Text('Perbarui')),
      ],
    );
  }
}
