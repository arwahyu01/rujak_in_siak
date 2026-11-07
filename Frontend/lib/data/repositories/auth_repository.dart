import '../../core/errors/app_exception.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/json_utils.dart';
import '../models/auth.dart';

class AuthRepository {
  AuthRepository(this._api);

  final ApiClient _api;

  Future<AuthSession> login({
    required String identifier,
    required String password,
    String? deviceUuid,
    String? baseUrl,
  }) async {
    final result = await _api.post(
      'auth/login',
      authenticated: false,
      body: {
        'identifier': identifier.trim(),
        'password': password,
        if (deviceUuid != null && deviceUuid.isNotEmpty)
          'device_uuid': deviceUuid,
        'token_name': 'flutter-pos',
      },
    );

    final data = asMap(result.data);
    final session = AuthSession.fromJson({...data, 'base_url': baseUrl});
    if (session.token.isEmpty) {
      throw const AppException(
        'AUTH_INVALID_RESPONSE',
        'Server tidak mengembalikan token sesi.',
      );
    }
    return session;
  }

  Future<({AppDevice device, OfflineLease? lease})> registerDevice({
    required String uuid,
    required String name,
    required String appVersion,
    required String fingerprint,
  }) async {
    final result = await _api.post(
      'devices/register',
      body: {
        'uuid': uuid,
        'name': name.trim(),
        'platform': 'android',
        'app_version': appVersion,
        'device_fingerprint': fingerprint,
      },
    );

    final data = asMap(result.data);
    final deviceJson = asMap(data['device']);
    if (deviceJson.isEmpty) {
      throw const AppException(
        'DEVICE_INVALID_RESPONSE',
        'Server tidak mengembalikan data perangkat.',
      );
    }
    final leaseJson = asMapOrNull(data['offline_lease']);
    return (
      device: AppDevice.fromJson(deviceJson),
      lease: leaseJson == null ? null : OfflineLease.fromJson(leaseJson),
    );
  }

  Future<OfflineLease> requestLease({
    int hours = 72,
    String? pin,
    String? password,
  }) async {
    final result = await _api.post(
      'auth/offline-lease',
      body: {
        'hours': hours.clamp(1, 72),
        if (pin != null && pin.isNotEmpty) 'pin': pin,
        if (password != null && password.isNotEmpty) 'password': password,
      },
    );

    final data = asMap(result.data);
    final lease = OfflineLease.fromJson(data);
    if (lease.token.isEmpty || lease.expiresAt == null) {
      throw const AppException(
        'LEASE_INVALID_RESPONSE',
        'Server tidak mengembalikan lease offline yang valid.',
      );
    }
    return lease;
  }

  Future<AppUser> fetchProfile() async {
    final result = await _api.get('me');
    return AppUser.fromJson(asMap(result.data));
  }

  Future<void> updatePin({
    required String currentPassword,
    required String pin,
    required String confirmation,
  }) async {
    await _api.put(
      'me/pin',
      body: {
        'current_password': currentPassword,
        'pin': pin,
        'pin_confirmation': confirmation,
      },
    );
  }

  Future<void> logout() async {
    try {
      await _api.post('auth/logout');
    } on AppException {
      // A local logout must succeed even when the server is unreachable.
    }
  }
}
