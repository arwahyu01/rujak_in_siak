import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/security/pin_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/status_chip.dart';
import '../../data/session/app_lock_controller.dart';
import '../../data/session/session_controller.dart';

class UnlockScreen extends ConsumerStatefulWidget {
  const UnlockScreen({super.key});

  @override
  ConsumerState<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends ConsumerState<UnlockScreen> {
  final _pin = TextEditingController();
  final _focus = FocusNode();
  bool _checking = false;
  String? _error;

  @override
  void dispose() {
    _pin.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    final value = _pin.text.trim();
    if (value.isEmpty || _checking) return;
    setState(() {
      _checking = true;
      _error = null;
    });

    final verifier = await ref.read(secureStoreProvider).readPinVerifier();
    if (verifier == null) {
      ref.read(appLockProvider.notifier).unlock();
      return;
    }

    final valid = await PinService().verify(
      pin: value,
      hash: verifier.hash,
      salt: verifier.salt,
    );
    if (!mounted) return;
    if (valid) {
      _pin.clear();
      ref.read(appLockProvider.notifier).unlock();
    } else {
      setState(() {
        _error = 'PIN tidak sesuai.';
        _checking = false;
      });
      _pin.clear();
      _focus.requestFocus();
    }
  }

  Future<void> _logout() async {
    await ref.read(sessionProvider.notifier).logout();
    ref.read(appLockProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(sessionProvider).value?.user;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: AppColors.forestSoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_outline_rounded,
                      size: 34,
                      color: AppColors.forest,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Selamat datang kembali',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    user?.name ?? 'Kasir',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (_error != null) ...[
                    InfoBanner(
                      message: _error!,
                      tone: StatusTone.danger,
                      icon: Icons.error_outline_rounded,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  TextField(
                    controller: _pin,
                    focusNode: _focus,
                    autofocus: true,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                    ],
                    style: Theme.of(
                      context,
                    ).textTheme.headlineSmall?.copyWith(letterSpacing: 8),
                    onSubmitted: (_) => _unlock(),
                    decoration: const InputDecoration(
                      labelText: 'PIN',
                      hintText: '••••••',
                      prefixIcon: Icon(Icons.pin_outlined),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton(
                    onPressed: _checking ? null : _unlock,
                    child: _checking
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Buka kasir'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextButton(
                    onPressed: _checking ? null : _logout,
                    child: const Text('Lupakan sesi di perangkat ini'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
