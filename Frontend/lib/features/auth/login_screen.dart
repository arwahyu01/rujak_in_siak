import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/errors/app_exception.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/status_chip.dart';
import '../../data/session/session_controller.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.footer,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: constraints.maxWidth >= 720
                    ? (constraints.maxWidth - 520) / 2
                    : AppSpacing.xl,
                vertical: AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.forest,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: const Icon(
                          Icons.eco_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'RUJAK.IN.SIAK',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  letterSpacing: 0.6,
                                  color: AppColors.forestDark,
                                ),
                          ),
                          Text(
                            'Kasir buah segar',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.inkMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl + AppSpacing.sm),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    subtitle,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: AppColors.inkMuted),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  child,
                  if (footer != null) ...[
                    const SizedBox(height: AppSpacing.xl),
                    footer!,
                  ],
                  const SizedBox(height: AppSpacing.xxl),
                  Text(
                    'v${AppConfig.appVersion} · Offline-first',
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: AppColors.inkMuted),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  final _serverUrl = TextEditingController();
  bool _showServer = false;
  bool _obscure = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadServerUrl();
  }

  Future<void> _loadServerUrl() async {
    final url = await ref.read(secureStoreProvider).serverUrl();
    if (!mounted) return;
    _serverUrl.text = url;
    if (url != AppConfig.defaultApiBaseUrl) {
      setState(() => _showServer = true);
    }
  }

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    _serverUrl.dispose();
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
          .login(
            identifier: _identifier.text,
            password: _password.text,
            baseUrl: AppConfig.normalizeBaseUrl(_serverUrl.text),
          );
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() => _error = _messageFor(error));
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _error = 'Login gagal. Periksa koneksi dan alamat server.',
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _messageFor(AppException error) {
    return switch (error.code) {
      'AUTH_INVALID_CREDENTIALS' => 'Username/email atau password salah.',
      'AUTH_LOCKED' => 'Akun terkunci sementara. Coba lagi beberapa menit.',
      'DEVICE_REVOKED' => 'Perangkat ini telah dicabut oleh admin.',
      _ => error.message,
    };
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Masuk ke kasir',
      subtitle:
          'Gunakan akun kasir yang terdaftar. Data transaksi tersimpan aman di perangkat.',
      footer: Text(
        'Pastikan perangkat sudah terhubung ke jaringan outlet untuk login pertama.',
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
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
            TextFormField(
              controller: _identifier,
              autofillHints: const [AutofillHints.username],
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Username atau email',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Masukkan username atau email'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _password,
              obscureText: _obscure,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Masukkan password' : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => _showServer = !_showServer),
                icon: Icon(
                  _showServer
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 18,
                ),
                label: const Text('Alamat server'),
              ),
            ),
            if (_showServer) ...[
              const SizedBox(height: AppSpacing.xs),
              TextFormField(
                controller: _serverUrl,
                keyboardType: TextInputType.url,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'URL API',
                  hintText: 'http://192.168.1.10:8000/api/v1',
                  prefixIcon: Icon(Icons.dns_outlined),
                  helperText:
                      'Emulator: 10.0.2.2. Perangkat fisik: IP komputer server.',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  final normalized = AppConfig.normalizeBaseUrl(value);
                  final uri = Uri.tryParse(normalized);
                  if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
                    return 'Alamat server tidak valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            const SizedBox(height: AppSpacing.lg),
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
                  : const Text('Masuk'),
            ),
          ],
        ),
      ),
    );
  }
}
