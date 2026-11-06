class AppException implements Exception {
  const AppException(
    this.code,
    this.message, {
    this.statusCode,
    this.retryable = false,
    this.details,
  });

  final String code;
  final String message;
  final int? statusCode;
  final bool retryable;
  final Map<String, dynamic>? details;

  bool get isNetwork => code == 'NETWORK_ERROR';
  bool get isUnauthorized => statusCode == 401;
  bool get isConflict => statusCode == 409 || code.contains('CONFLICT');

  static AppException network([String? message]) => AppException(
    'NETWORK_ERROR',
    message ?? 'Tidak dapat terhubung ke server. Periksa jaringan Anda.',
    retryable: true,
  );

  static AppException unknown([Object? error]) => AppException(
    'UNKNOWN_ERROR',
    'Terjadi kesalahan tak terduga.',
    details: error == null ? null : {'error': error.toString()},
  );

  @override
  String toString() => 'AppException($code, $message)';
}
