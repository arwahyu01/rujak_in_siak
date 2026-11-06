import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/format/dates.dart';
import '../../../core/providers.dart';
import '../../../core/security/pin_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../data/bootstrap/bootstrap_controller.dart';
import '../../../data/session/app_lock_controller.dart';
import '../../../data/session/session_controller.dart';
import '../../../data/sync/sync_controller.dart';
import '../../../features/pos/state/cart_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final PinService _pins = PinService();
  String? _serverUrl;
  bool _hasPin = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final store = ref.read(secureStoreProvider);
    final url = await store.serverUrl();
    final verifier = await store.readPinVerifier();
    if (!mounted) return;
    setState(() {
      _serverUrl = url;
      _hasPin = verifier != null;
    });
  }

  Future<void> _refreshLease() async {
    final credentials = await showDialog<_Credentials>(
      context: context,
      builder: (context) => const _CredentialsDialog(),
    );
    if (credentials == null) return;
    setState(() => _busy = true);
    try {
      final session = await ref
          .read(sessionProvider.notifier)
          .refreshLease(pin: credentials.pin, password: credentials.password);
      await ref.read(syncProvider.notifier).refreshStatus();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            session.lease?.expiresAt == null
                ? 'Lisensi offline diperbarui.'
                : 'Lisensi offline berlaku sampai '
                      '${formatDateTime(session.lease!.expiresAt)}.',
          ),
        ),
      );
    } on AppException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppException.unknown(error).message)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _managePin() async {
    final store = ref.read(secureStoreProvider);
    final existing = await store.readPinVerifier();
    if (!mounted) return;

    if (existing != null) {
      final current = await _askPin('Verifikasi PIN', 'PIN lokal saat ini');
      if (current == null) return;
      final valid = await _pins.verify(
        pin: current,
        hash: existing.hash,
        salt: existing.salt,
      );
      if (!valid) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('PIN lama tidak sesuai.')));
        return;
      }
      if (!mounted) return;
      final action = await showDialog<String>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('Keamanan PIN'),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop('change'),
              child: const Text('Ganti PIN'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop('remove'),
              child: const Text('Hapus PIN lokal'),
            ),
          ],
        ),
      );
      if (action == 'remove') {
        await store.clearPin();
        await ref.read(appLockProvider.notifier).refreshPinState();
        if (!mounted) return;
        setState(() => _hasPin = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('PIN lokal dihapus.')));
        return;
      }
      if (action != 'change') return;
    }

    final pin = await _newPinDialog();
    if (pin == null) return;
    final salt = await _pins.newSalt();
    final hash = await _pins.hash(pin, salt);
    await store.savePinVerifier(hash, salt);
    await ref.read(appLockProvider.notifier).refreshPinState();
    if (!mounted) return;
    setState(() => _hasPin = true);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('PIN lokal tersimpan.')));
  }

  Future<String?> _askPin(String title, String label) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          obscureText: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Lanjut'),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }

  Future<String?> _newPinDialog() {
    final first = TextEditingController();
    final second = TextEditingController();
    String? error;
    return showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Atur PIN lokal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'PIN lokal mengunci layar kasir dan tidak dikirim ke server.',
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: first,
                autofocus: true,
                obscureText: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'PIN baru (4-6 digit)',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: second,
                obscureText: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'Ulangi PIN'),
              ),
              if (error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  error!,
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
              onPressed: () {
                final pin = first.text.trim();
                if (pin.length < 4 || pin.length > 6) {
                  setDialogState(() => error = 'PIN harus 4-6 digit.');
                  return;
                }
                if (pin != second.text.trim()) {
                  setDialogState(() => error = 'Konfirmasi PIN tidak sama.');
                  return;
                }
                Navigator.of(context).pop(pin);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      first.dispose();
      second.dispose();
    });
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari akun'),
        content: const Text(
          'Transaksi offline yang belum tersinkron tetap tersimpan di perangkat '
          'dan akan dikirim saat akun berikutnya masuk. Lanjutkan keluar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final notifier = ref.read(sessionProvider.notifier);
    try {
      await notifier.logout();
    } catch (_) {
      await notifier.logout(notifyServer: false);
    }
    ref.read(appLockProvider.notifier).clear();
    ref.read(cartProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider).value;
    final user = session?.user;
    final device = session?.device;
    final data = ref.watch(bootstrapProvider).value?.data;
    final lease = session?.lease;

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          _SectionLabel('Akun & perangkat'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline_rounded),
                  title: Text(user?.name ?? 'Pengguna'),
                  subtitle: Text(
                    [
                      if (user != null && user.roles.isNotEmpty)
                        user.roles.join(', '),
                      if (user?.email != null) user!.email!,
                    ].join(' · '),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.storefront_outlined),
                  title: Text(data?.outlet.name ?? 'Outlet'),
                  subtitle: Text(
                    [
                      if (device != null) 'Terminal ${device.terminalCode}',
                      if (device != null) device.name,
                    ].join(' · '),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.dns_outlined),
                  title: const Text('Server'),
                  subtitle: Text(_serverUrl ?? '-'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionLabel('Lisensi offline'),
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
                          session?.leaseValid == true
                              ? 'Lisensi aktif'
                              : 'Lisensi tidak valid',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      StatusChip(
                        label: session?.leaseValid == true
                            ? 'Aktif'
                            : 'Kedaluwarsa',
                        tone: session?.leaseValid == true
                            ? StatusTone.success
                            : StatusTone.danger,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    lease?.expiresAt == null
                        ? 'Belum ada lisensi offline pada perangkat ini.'
                        : 'Berlaku sampai ${formatDateTime(lease!.expiresAt)}.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _refreshLease,
                    icon: _busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.autorenew_rounded),
                    label: const Text('Perbarui lisensi'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionLabel('Keamanan'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.pin_outlined),
              title: Text(
                _hasPin ? 'Ubah atau hapus PIN lokal' : 'Atur PIN lokal',
              ),
              subtitle: Text(
                _hasPin
                    ? 'Layar terkunci otomatis setelah aplikasi di latar belakang.'
                    : 'PIN lokal melindungi perangkat saat ditinggalkan.',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: _managePin,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionLabel('Perangkat & data'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.bluetooth_rounded),
                  title: const Text('Printer Bluetooth'),
                  subtitle: const Text('Pilih printer struk ESC/POS'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/settings/printer'),
                ),
                ListTile(
                  leading: const Icon(Icons.print_outlined),
                  title: const Text('Antrean cetak'),
                  subtitle: const Text('Cetak ulang struk yang tertunda'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/settings/print-queue'),
                ),
                ListTile(
                  leading: const Icon(Icons.sync_rounded),
                  title: const Text('Sinkronisasi'),
                  subtitle: const Text('Kirim transaksi offline ke server'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/sync'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            onPressed: _logout,
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Keluar dari akun'),
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: Text(
              'RUJAK.IN.SIAK POS · v1.0.0',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.inkMuted,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Credentials {
  const _Credentials({this.pin, this.password});

  final String? pin;
  final String? password;
}

class _CredentialsDialog extends StatefulWidget {
  const _CredentialsDialog();

  @override
  State<_CredentialsDialog> createState() => _CredentialsDialogState();
}

class _CredentialsDialogState extends State<_CredentialsDialog> {
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
      setState(() => _error = 'Masukkan PIN atau kata sandi.');
      return;
    }
    Navigator.of(context).pop(
      _Credentials(
        pin: pin.isEmpty ? null : pin,
        password: password.isEmpty ? null : password,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Perbarui lisensi'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
