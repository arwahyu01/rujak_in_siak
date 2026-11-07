import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/status_chip.dart';
import '../../data/session/session_controller.dart';
import 'login_screen.dart';

class DeviceSetupScreen extends ConsumerStatefulWidget {
  const DeviceSetupScreen({super.key});

  @override
  ConsumerState<DeviceSetupScreen> createState() => _DeviceSetupScreenState();
}

class _DeviceSetupScreenState extends ConsumerState<DeviceSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController(text: 'Kasir 1');
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(sessionProvider.notifier)
          .completeDeviceSetup(name: _name.text);
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Registrasi perangkat gagal. Coba lagi.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider).value;

    return AuthScaffold(
      title: 'Daftarkan perangkat',
      subtitle:
          'Perangkat ini belum terdaftar. Beri nama agar mudah dikenali di laporan. Kode POS dibuat otomatis.',
      footer: TextButton.icon(
        onPressed: () => ref.read(sessionProvider.notifier).logout(),
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: const Text('Batalkan dan keluar'),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) ...[
              InfoBanner(
                message: _error!,
                tone: StatusTone.danger,
                icon: Icons.error_outline_rounded,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.outline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session?.user.name ?? 'Pengguna',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Terminal baru untuk outlet ini',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _name,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nama perangkat',
                prefixIcon: Icon(Icons.tablet_android_outlined),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Nama perangkat wajib diisi'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
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
                  : const Text('Daftarkan perangkat'),
            ),
          ],
        ),
      ),
    );
  }
}
