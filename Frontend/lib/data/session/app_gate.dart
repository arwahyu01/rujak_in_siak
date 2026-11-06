import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_lock_controller.dart';
import 'session_controller.dart';

enum AppGate { loading, login, deviceSetup, locked, ready }

final appGateProvider = Provider<AppGate>((ref) {
  final session = ref.watch(sessionProvider);
  final lock = ref.watch(appLockProvider);

  if (session.isLoading && !session.hasValue) return AppGate.loading;
  if (!lock.checked) return AppGate.loading;

  final value = session.value;
  if (value == null) return AppGate.login;
  if (value.device == null) return AppGate.deviceSetup;
  if (lock.locked) return AppGate.locked;
  return AppGate.ready;
});
