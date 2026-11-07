import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/providers.dart';
import '../../core/storage/secure_store.dart';
import '../models/auth.dart';

class SessionController extends AsyncNotifier<AuthSession?> {
  late SecureStore _store;
  late ApiClient _api;

  @override
  Future<AuthSession?> build() async {
    _store = ref.read(secureStoreProvider);
    _api = ref.read(apiClientProvider);
    final baseUrl = await _store.serverUrl();
    final deviceUuid = await _store.deviceUuid();

    _api
      ..configure(baseUrl: baseUrl, deviceUuid: deviceUuid)
      ..onUnauthorized = _handleUnauthorized;

    final saved = await _store.readSession();
    if (saved == null) return null;

    final session = AuthSession.fromJson(saved);
    if (session.token.isEmpty || !session.hasToken) {
      await _store.clearSession();
      _api.clearToken();
      return null;
    }

    _api.configure(token: session.token);
    return session;
  }

  Future<AuthSession> login({
    required String identifier,
    required String password,
    required String baseUrl,
  }) async {
    final store = ref.read(secureStoreProvider);
    final api = ref.read(apiClientProvider);
    final repository = ref.read(authRepositoryProvider);

    await store.saveServerUrl(baseUrl);
    final deviceUuid = await store.deviceUuid();
    api.configure(baseUrl: baseUrl, token: null, deviceUuid: deviceUuid);

    final session = await repository.login(
      identifier: identifier,
      password: password,
      deviceUuid: deviceUuid,
      baseUrl: baseUrl,
    );

    await _persist(session);
    return session;
  }

  Future<AuthSession> completeDeviceSetup({
    required String name,
  }) async {
    final current = state.value;
    if (current == null) {
      throw StateError('No authenticated session');
    }

    final store = ref.read(secureStoreProvider);
    final repository = ref.read(authRepositoryProvider);
    final uuid = await store.deviceUuid();
    final fingerprint = await store.deviceFingerprint();

    final registered = await repository.registerDevice(
      uuid: uuid,
      name: name,
      appVersion: '1.0.0',
      fingerprint: fingerprint,
    );

    final updated = current.copyWith(
      device: registered.device,
      lease: registered.lease,
    );
    await _persist(updated);
    return updated;
  }

  Future<AuthSession> refreshLease({
    int hours = 72,
    String? pin,
    String? password,
  }) async {
    final current = state.value;
    if (current == null) throw StateError('No authenticated session');

    final lease = await ref
        .read(authRepositoryProvider)
        .requestLease(hours: hours, pin: pin, password: password);
    final updated = current.copyWith(lease: lease);
    await _persist(updated);
    return updated;
  }

  Future<void> refreshProfile() async {
    final current = state.value;
    if (current == null) return;
    final user = await ref.read(authRepositoryProvider).fetchProfile();
    await _persist(current.copyWith(user: user));
  }

  Future<void> logout({bool notifyServer = true}) async {
    if (notifyServer && state.value != null) {
      await ref.read(authRepositoryProvider).logout();
    }
    await _store.clearAuthorization();
    _api.clearToken();
    state = const AsyncData(null);
  }

  Future<void> _persist(AuthSession session) async {
    await _store.saveSession(session.toJson());
    // The device header must survive sessions where the server does not echo
    // the device object yet (e.g. right after login before registration).
    final deviceUuid = session.device?.uuid ?? await _store.deviceUuid();
    _api.configure(token: session.token, deviceUuid: deviceUuid);
    state = AsyncData(session);
  }

  void _handleUnauthorized() {
    Future.microtask(() async {
      await _store.clearAuthorization();
      _api.clearToken();
      if (state.value != null) {
        state = const AsyncData(null);
      }
    });
  }
}

final sessionProvider = AsyncNotifierProvider<SessionController, AuthSession?>(
  SessionController.new,
);
