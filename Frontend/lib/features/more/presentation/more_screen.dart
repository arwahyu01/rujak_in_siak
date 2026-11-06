import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/dates.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../data/bootstrap/bootstrap_controller.dart';
import '../../../data/session/session_controller.dart';
import '../../../data/sync/sync_controller.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider).value;
    final user = session?.user;
    final data = ref.watch(bootstrapProvider).value?.data;
    final sync = ref.watch(syncProvider).value;

    final items = <_MenuItem>[
      if (user?.canAny(const [
            'payments.view_pending',
            'payments.verify',
            'payments.reject',
          ]) ??
          false)
        _MenuItem(
          icon: Icons.verified_user_outlined,
          title: 'Verifikasi pembayaran',
          subtitle: 'Konfirmasi pembayaran non-tunai',
          route: '/payments/verification',
        ),
      if (user?.can('reports.view') ?? false)
        _MenuItem(
          icon: Icons.insights_outlined,
          title: 'Laporan',
          subtitle: 'Penjualan, produk, dan pembayaran',
          route: '/reports',
        ),
      _MenuItem(
        icon: Icons.sync_rounded,
        title: 'Sinkronisasi',
        subtitle: sync == null
            ? 'Status antrean data'
            : '${sync.pending} antre · ${sync.conflicts} konflik',
        route: '/sync',
      ),
      _MenuItem(
        icon: Icons.print_outlined,
        title: 'Antrean cetak',
        subtitle: 'Struk yang menunggu dicetak',
        route: '/settings/print-queue',
      ),
      _MenuItem(
        icon: Icons.bluetooth_rounded,
        title: 'Printer Bluetooth',
        subtitle: 'Atur printer struk ESC/POS',
        route: '/settings/printer',
      ),
      _MenuItem(
        icon: Icons.settings_outlined,
        title: 'Pengaturan',
        subtitle: 'Akun, perangkat, lisensi, dan keamanan',
        route: '/settings',
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.forestSoft,
                  child: Text(
                    (user?.name.isNotEmpty ?? false)
                        ? user!.name.characters.first.toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: AppColors.forest,
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'Pengguna',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        (user?.roles.isNotEmpty ?? false)
                            ? user!.roles.join(', ')
                            : 'Tanpa peran',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.inkMuted,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (data != null)
                            StatusChip(
                              label: data.outlet.name,
                              tone: StatusTone.info,
                              compact: true,
                            ),
                          if (session?.device != null)
                            StatusChip(
                              label: session!.device!.terminalCode,
                              tone: StatusTone.neutral,
                              compact: true,
                            ),
                          StatusChip(
                            label: session?.leaseValid == true
                                ? 'Lisensi ${formatDate(session!.lease?.expiresAt)}'
                                : 'Lisensi kedaluwarsa',
                            tone: session?.leaseValid == true
                                ? StatusTone.success
                                : StatusTone.warning,
                            compact: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                onTap: () => context.push(item.route),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(item.icon, color: AppColors.forest, size: 20),
                ),
                title: Text(item.title),
                subtitle: Text(item.subtitle),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.inkMuted,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MenuItem {
  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
}
