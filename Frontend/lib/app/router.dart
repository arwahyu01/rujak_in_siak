import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/repositories/sale_repository.dart';
import '../data/session/app_gate.dart';
import '../features/auth/device_setup_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/unlock_screen.dart';
import '../features/checkout/presentation/checkout_screen.dart';
import '../features/history/presentation/history_screen.dart';
import '../features/history/presentation/sale_detail_screen.dart';
import '../features/more/presentation/more_screen.dart';
import '../features/payments/presentation/payment_verification_screen.dart';
import '../features/pos/presentation/pos_screen.dart';
import '../features/receipt/presentation/receipt_screen.dart';
import '../features/reports/presentation/reports_screen.dart';
import '../features/settings/presentation/print_queue_screen.dart';
import '../features/settings/presentation/printer_settings_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/shift/presentation/shift_screen.dart';
import '../features/shell/app_shell.dart';
import '../features/splash/splash_screen.dart';
import '../features/sync/presentation/sync_screen.dart';

class _GateListenable extends ChangeNotifier {
  _GateListenable(this.value);

  AppGate value;

  void update(AppGate next) {
    if (value == next) return;
    value = next;
    notifyListeners();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final listenable = _GateListenable(ref.read(appGateProvider));
  ref.listen<AppGate>(appGateProvider, (_, next) {
    listenable.update(next);
  });

  const authRoutes = {'/splash', '/login', '/device-setup', '/unlock'};

  final router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: listenable,
    redirect: (context, state) {
      final gate = ref.read(appGateProvider);
      final path = state.uri.path;
      switch (gate) {
        case AppGate.loading:
          return path == '/splash' ? null : '/splash';
        case AppGate.login:
          return path == '/login' ? null : '/login';
        case AppGate.deviceSetup:
          return path == '/device-setup' ? null : '/device-setup';
        case AppGate.locked:
          return path == '/unlock' ? null : '/unlock';
        case AppGate.ready:
          return authRoutes.contains(path) ? '/pos' : null;
      }
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/device-setup',
        builder: (context, state) => const DeviceSetupScreen(),
      ),
      GoRoute(
        path: '/unlock',
        builder: (context, state) => const UnlockScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(path: '/pos', builder: (context, state) => const PosScreen()),
          GoRoute(
            path: '/history',
            builder: (context, state) => const HistoryScreen(),
          ),
          GoRoute(
            path: '/shift',
            builder: (context, state) => const ShiftScreen(),
          ),
          GoRoute(
            path: '/more',
            builder: (context, state) => const MoreScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/receipt',
        builder: (context, state) {
          final outcome = state.extra is CheckoutOutcome
              ? state.extra as CheckoutOutcome
              : null;
          return ReceiptScreen(outcome: outcome);
        },
      ),
      GoRoute(
        path: '/receipt/:uuid',
        builder: (context, state) =>
            ReceiptScreen(saleUuid: state.pathParameters['uuid']),
      ),
      GoRoute(
        path: '/sales/:uuid',
        builder: (context, state) =>
            SaleDetailScreen(saleUuid: state.pathParameters['uuid']!),
      ),
      GoRoute(
        path: '/payments/verification',
        builder: (context, state) => const PaymentVerificationScreen(),
      ),
      GoRoute(
        path: '/reports',
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(path: '/sync', builder: (context, state) => const SyncScreen()),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/settings/printer',
        builder: (context, state) => const PrinterSettingsScreen(),
      ),
      GoRoute(
        path: '/settings/print-queue',
        builder: (context, state) => const PrintQueueScreen(),
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    listenable.dispose();
  });

  return router;
});
