class AppConfig {
  const AppConfig._();

  /// Android emulator reaches the host machine through 10.0.2.2.
  /// Override for a physical device:
  /// flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000/api/v1
  static const String defaultApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue:
        'http://192.168.100.11/Rujak%20In%20Siak/Backend/public/api/v1',
  );

  static const String appVersion = '1.0.0';
  static const Duration requestTimeout = Duration(seconds: 25);
  static const Duration uploadTimeout = Duration(seconds: 60);
  static const Duration catalogWarnAfter = Duration(hours: 24);
  static const Duration catalogBlockAfter = Duration(hours: 72);
  static const Duration lockAfterBackground = Duration(minutes: 5);

  static String normalizeBaseUrl(String input) {
    var value = input.trim();
    if (value.isEmpty) return defaultApiBaseUrl;
    if (!RegExp(r'^https?://', caseSensitive: false).hasMatch(value)) {
      value = 'http://$value';
    }
    while (value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }
    if (value.endsWith('/api/v1')) return value;
    if (value.endsWith('/api')) return '$value/v1';
    return '$value/api/v1';
  }
}
