import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_exception.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/bootstrap/bootstrap_controller.dart';
import '../../data/session/app_lock_controller.dart';
import '../../data/session/session_controller.dart';
import '../../data/sync/sync_controller.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  bool _bootstrapped = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureBootstrap());
  }

  Future<void> _ensureBootstrap() async {
    if (_bootstrapped) return;
    _bootstrapped = true;
    final state = ref.read(bootstrapProvider).value;
    if (state == null || !state.snapshot.hasData) {
      try {
        await ref.read(bootstrapProvider.notifier).refresh();
      } on AppException {
        // The POS screen surfaces the error with a retry action.
      }
    }
  }

  Future<void> _autoSync() async {
    final session = ref.read(sessionProvider).value;
    if (session == null || !session.leaseValid) return;
    final status = ref.read(syncProvider).value;
    if (status == null || status.pending == 0) return;
    if (ref.read(syncProvider.notifier).isRunning) return;
    try {
      await ref.read(syncProvider.notifier).syncNow();
    } on AppException {
      // Background sync must never interrupt cashier input.
    }
  }

  Future<void> _lock() async {
    final verifier = await ref.read(secureStoreProvider).readPinVerifier();
    if (!mounted) return;
    if (verifier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Atur PIN lokal terlebih dahulu di menu Pengaturan.'),
        ),
      );
      return;
    }
    ref.read(appLockProvider.notifier).lock();
  }

  int get _index {
    if (widget.location.startsWith('/history') ||
        widget.location.startsWith('/sales')) {
      return 1;
    }
    if (widget.location.startsWith('/shift')) return 2;
    if (widget.location.startsWith('/pos')) return 0;
    return 3;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(connectivityProvider, (previous, next) {
      final wasOnline = previous?.value ?? false;
      final isOnline = next.value ?? false;
      if (isOnline && !wasOnline) _autoSync();
    });

    final session = ref.watch(sessionProvider).value;
    final business = ref.watch(bootstrapProvider).value?.data?.business;
    final data = ref.watch(bootstrapProvider).value?.data;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        leadingWidth: 60,
        leading: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.md),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.forest,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(Icons.eco_rounded, color: Colors.white, size: 22),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              business?.name ?? 'RUJAK.IN.SIAK',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.forestDark,
                letterSpacing: 0.3,
              ),
            ),
            Text(
              [
                if (data != null) data.outlet.name,
                if (session != null) session.user.name,
              ].join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
            ),
          ],
        ),
        actions: [
          const _SyncPill(),
          IconButton(
            onPressed: _lock,
            tooltip: 'Kunci layar',
            icon: const Icon(Icons.lock_outline_rounded),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/pos');
            case 1:
              context.go('/history');
            case 2:
              context.go('/shift');
            default:
              context.go('/more');
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.point_of_sale_outlined),
            selectedIcon: Icon(Icons.point_of_sale_rounded),
            label: 'Kasir',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Riwayat',
          ),
          NavigationDestination(
            icon: Icon(Icons.schedule_outlined),
            selectedIcon: Icon(Icons.schedule_rounded),
            label: 'Shift',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'Lainnya',
          ),
        ],
      ),
    );
  }
}

class _SyncPill extends ConsumerWidget {
  const _SyncPill();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(syncProvider);
    final pending = status.value?.pending ?? 0;
    final conflicts = status.value?.conflicts ?? 0;
    final clean = status.value?.isClean ?? false;

    final (label, color, icon) = switch (true) {
      _ when status.hasError => (
        'Sinyal',
        AppColors.danger,
        Icons.cloud_off_rounded,
      ),
      _ when conflicts > 0 => (
        '$conflicts konflik',
        AppColors.danger,
        Icons.report_gmailerrorred_rounded,
      ),
      _ when pending > 0 => (
        '$pending antre',
        AppColors.amber,
        Icons.cloud_upload_outlined,
      ),
      _ when clean => ('Sinkron', AppColors.forest, Icons.cloud_done_outlined),
      _ => ('Memuat', AppColors.inkMuted, Icons.cloud_queue_rounded),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: TextButton.icon(
        onPressed: () => context.go('/sync'),
        style: TextButton.styleFrom(
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        ),
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
