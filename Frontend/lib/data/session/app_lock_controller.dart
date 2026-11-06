import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/providers.dart';

class AppLockState {
  const AppLockState({required this.locked, required this.checked});

  final bool locked;
  final bool checked;
}

class AppLockController extends Notifier<AppLockState> {
  DateTime? _backgroundedAt;
  bool _hasPin = false;

  @override
  AppLockState build() {
    Future.microtask(_restore);
    return const AppLockState(locked: false, checked: false);
  }

  Future<void> _restore() async {
    final verifier = await ref.read(secureStoreProvider).readPinVerifier();
    _hasPin = verifier != null;
    state = AppLockState(locked: _hasPin, checked: true);
  }

  void onBackground() {
    _backgroundedAt = DateTime.now();
  }

  void onResume() {
    final since = _backgroundedAt;
    _backgroundedAt = null;
    if (!_hasPin || since == null) return;
    if (DateTime.now().difference(since) >= AppConfig.lockAfterBackground) {
      state = const AppLockState(locked: true, checked: true);
    }
  }

  void unlock() {
    state = const AppLockState(locked: false, checked: true);
  }

  void lock() {
    if (!_hasPin) return;
    state = const AppLockState(locked: true, checked: true);
  }

  Future<void> refreshPinState() async {
    final verifier = await ref.read(secureStoreProvider).readPinVerifier();
    _hasPin = verifier != null;
    state = AppLockState(locked: state.locked && _hasPin, checked: true);
  }

  void clear() {
    _backgroundedAt = null;
    state = AppLockState(locked: false, checked: true);
  }
}

final appLockProvider = NotifierProvider<AppLockController, AppLockState>(
  AppLockController.new,
);
