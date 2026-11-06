import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/app_config.dart';
import '../utils/app_uuid.dart';

/// Small secrets only: tokens, lease, database key, PIN verifier and the
/// device identity. Business data lives in the encrypted Drift database.
class SecureStore {
  SecureStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _sessionKey = 'session_json';
  static const _dbKey = 'database_key';
  static const _deviceUuidKey = 'device_uuid';
  static const _deviceFingerprintKey = 'device_fingerprint';
  static const _serverUrlKey = 'server_url';
  static const _pinHashKey = 'pin_hash';
  static const _pinSaltKey = 'pin_salt';

  Future<String?> read(String key) => _storage.read(key: key);

  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  Future<void> delete(String key) => _storage.delete(key: key);

  Future<String> databaseKey() async {
    final existing = await read(_dbKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final generated = randomSecretBase64(32);
    await write(_dbKey, generated);
    return generated;
  }

  Future<String> deviceUuid() async {
    final existing = await read(_deviceUuidKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final generated = newUuid();
    await write(_deviceUuidKey, generated);
    return generated;
  }

  Future<String> deviceFingerprint() async {
    final existing = await read(_deviceFingerprintKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final generated = randomSecretBase64(24);
    await write(_deviceFingerprintKey, generated);
    return generated;
  }

  Future<Map<String, dynamic>?> readSession() async {
    final raw = await read(_sessionKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveSession(Map<String, dynamic> session) =>
      write(_sessionKey, jsonEncode(session));

  Future<void> clearSession() => delete(_sessionKey);

  Future<String> serverUrl() async {
    final stored = await read(_serverUrlKey);
    final value = stored?.trim();
    return value == null || value.isEmpty ? AppConfig.defaultApiBaseUrl : value;
  }

  Future<void> saveServerUrl(String url) => write(_serverUrlKey, url.trim());

  Future<void> savePinVerifier(String hash, String salt) async {
    await write(_pinHashKey, hash);
    await write(_pinSaltKey, salt);
  }

  Future<({String hash, String salt})?> readPinVerifier() async {
    final hash = await read(_pinHashKey);
    final salt = await read(_pinSaltKey);
    if (hash == null || salt == null) return null;
    return (hash: hash, salt: salt);
  }

  Future<void> clearPin() async {
    await delete(_pinHashKey);
    await delete(_pinSaltKey);
  }

  /// Logout removes authorization material but keeps the device identity and
  /// the local outbox so pending transactions are never silently discarded.
  Future<void> clearAuthorization() async {
    await clearSession();
    await clearPin();
  }
}
