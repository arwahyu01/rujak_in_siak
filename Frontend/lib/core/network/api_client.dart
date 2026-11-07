import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../errors/app_exception.dart';
import '../utils/json_utils.dart';

class ApiResult {
  const ApiResult(this.data, {this.meta = const {}});

  final dynamic data;
  final Map<String, dynamic> meta;
}

class ApiClient {
  ApiClient({String? baseUrl, Dio? dio})
    : _baseUrl = _normalize(baseUrl ?? AppConfig.defaultApiBaseUrl),
      _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: AppConfig.requestTimeout,
              receiveTimeout: AppConfig.requestTimeout,
              sendTimeout: AppConfig.requestTimeout,
              responseType: ResponseType.json,
              headers: const {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
              },
            ),
          );

  final Dio _dio;
  String _baseUrl;
  String? _token;
  String? _deviceUuid;

  /// Called once when an authenticated request receives a 401.
  void Function()? onUnauthorized;

  String get baseUrl => _baseUrl;
  String? get deviceUuid => _deviceUuid;

  static String _normalize(String value) {
    var url = value.trim();
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  static const Object _unset = Object();

  /// Only the arguments provided are updated. Passing `null` explicitly still
  /// clears a value, so callers must rely on the named argument being omitted
  /// to keep the current token/device.
  void configure({
    String? baseUrl,
    Object? token = _unset,
    Object? deviceUuid = _unset,
  }) {
    if (baseUrl != null && baseUrl.trim().isNotEmpty) {
      _baseUrl = _normalize(baseUrl);
    }
    if (!identical(token, _unset)) {
      _token = token as String?;
    }
    if (!identical(deviceUuid, _unset)) {
      _deviceUuid = deviceUuid as String?;
    }
    _log(
      '[CFG] base=$_baseUrl · token=${_token == null ? 'none' : 'set'} '
      '· device=${_hasDevice ? 'set' : 'missing'}',
    );
  }

  void clearToken() => _token = null;

  Map<String, String> _headers({bool authenticated = true}) {
    final headers = <String, String>{};
    if (authenticated && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    if (_deviceUuid != null && _deviceUuid!.isNotEmpty) {
      headers['X-Device-Id'] = _deviceUuid!;
    }
    return headers;
  }

  Future<ApiResult> get(
    String path, {
    Map<String, dynamic>? query,
    bool authenticated = true,
  }) => _send('GET', path, query: query, authenticated: authenticated);

  Future<ApiResult> post(
    String path, {
    Object? body,
    Map<String, String>? headers,
    bool authenticated = true,
  }) => _send(
    'POST',
    path,
    body: body,
    headers: headers,
    authenticated: authenticated,
  );

  Future<ApiResult> put(
    String path, {
    Object? body,
    bool authenticated = true,
  }) => _send('PUT', path, body: body, authenticated: authenticated);

  Future<ApiResult> postMultipart(
    String path, {
    required String field,
    required String filePath,
    String? filename,
    Map<String, String> fields = const {},
    bool authenticated = true,
  }) async {
    final url = '$_baseUrl/${path.replaceFirst(RegExp(r'^/+'), '')}';
    final stopwatch = Stopwatch()..start();
    _log(
      '[REQ] POST(multipart) $url · auth=${_token == null ? 'none' : 'bearer'}',
    );
    try {
      final form = FormData.fromMap({
        ...fields,
        field: await MultipartFile.fromFile(filePath, filename: filename),
      });
      final response = await _dio.post<dynamic>(
        url,
        data: form,
        options: Options(
          headers: _headers(authenticated: authenticated),
          contentType: 'multipart/form-data',
          sendTimeout: AppConfig.uploadTimeout,
          receiveTimeout: AppConfig.uploadTimeout,
        ),
      );
      stopwatch.stop();
      _log(
        '[RES] ${response.statusCode} POST(multipart) $url '
        '· ${stopwatch.elapsedMilliseconds}ms',
      );
      final envelope = asMap(response.data);
      return ApiResult(envelope['data'], meta: asMap(envelope['meta']));
    } on DioException catch (error) {
      stopwatch.stop();
      final mapped = _mapError(error);
      _log(
        '[ERR] POST(multipart) $url · '
        '${error.response?.statusCode ?? error.type.name} · '
        '${stopwatch.elapsedMilliseconds}ms · ${mapped.code}: ${mapped.message}',
        error: error,
      );
      if (mapped.isUnauthorized && authenticated) {
        onUnauthorized?.call();
      }
      throw mapped;
    } on AppException {
      rethrow;
    } catch (error) {
      stopwatch.stop();
      _log('[ERR] POST(multipart) $url · unexpected error', error: error);
      throw AppException.unknown(error);
    }
  }

  Future<Uint8List> getBytes(String path, {bool authenticated = true}) async {
    final url = '$_baseUrl/${path.replaceFirst(RegExp(r'^/+'), '')}';
    try {
      final response = await _dio.get<List<int>>(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          headers: _headers(authenticated: authenticated),
        ),
      );
      final data = response.data;
      return data is Uint8List
          ? data
          : Uint8List.fromList(data ?? const <int>[]);
    } on DioException catch (error) {
      final mapped = _mapError(error);
      if (mapped.isUnauthorized && authenticated) {
        onUnauthorized?.call();
      }
      throw mapped;
    } on AppException {
      rethrow;
    } catch (error) {
      throw AppException.unknown(error);
    }
  }

  bool get _hasDevice => _deviceUuid != null && _deviceUuid!.isNotEmpty;

  /// Debug-only diagnostics. Never logs tokens or request bodies (login
  /// payloads contain credentials).
  static void _log(String message, {Object? error}) {
    if (!kDebugMode) return;
    developer.log(message, name: 'ApiClient', error: error);
  }

  Future<ApiResult> _send(
    String method,
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    bool authenticated = true,
  }) async {
    final url = '$_baseUrl/${path.replaceFirst(RegExp(r'^/+'), '')}';
    final stopwatch = Stopwatch()..start();
    _log(
      '[REQ] $method $url · auth=${_token == null ? 'none' : 'bearer'} '
      '· device=${_hasDevice ? 'set' : 'MISSING'}',
    );
    try {
      final response = await _dio.request<dynamic>(
        url,
        data: body,
        queryParameters: query,
        options: Options(
          method: method,
          headers: {
            ..._headers(authenticated: authenticated),
            ...?headers,
          },
        ),
      );
      stopwatch.stop();
      _log(
        '[RES] ${response.statusCode} $method $url '
        '· ${stopwatch.elapsedMilliseconds}ms',
      );

      final envelope = asMap(response.data);
      return ApiResult(envelope['data'], meta: asMap(envelope['meta']));
    } on DioException catch (error) {
      stopwatch.stop();
      final mapped = _mapError(error);
      final response = error.response;
      final payload = asMap(asMap(response?.data)['error']);
      _log(
        '[ERR] $method $url · ${response?.statusCode ?? error.type.name} '
        '· ${stopwatch.elapsedMilliseconds}ms · ${mapped.code}: '
        '${mapped.message}'
        '${payload.isEmpty ? '' : ' · body=${payload['code']}:${payload['message']}'}'
        '${response == null ? ' · ${error.message}' : ''}',
        error: error,
      );
      if (mapped.isUnauthorized && authenticated) {
        onUnauthorized?.call();
      }
      throw mapped;
    } on AppException {
      rethrow;
    } catch (error) {
      stopwatch.stop();
      _log('[ERR] $method $url · unexpected error', error: error);
      throw AppException.unknown(error);
    }
  }

  AppException _mapError(DioException error) {
    final response = error.response;
    if (response != null) {
      final envelope = asMap(response.data);
      final payload = asMap(envelope['error']);
      if (payload.isNotEmpty) {
        return AppException(
          asStringOr(payload['code'], 'API_ERROR'),
          asStringOr(payload['message'], 'Permintaan tidak dapat diproses.'),
          statusCode: response.statusCode,
          retryable: asBool(payload['retryable']),
          details: asMapOrNull(payload['details']),
        );
      }
      if (response.statusCode == 401) {
        return const AppException(
          'UNAUTHENTICATED',
          'Sesi Anda telah berakhir. Silakan login kembali.',
          statusCode: 401,
        );
      }
      if (response.statusCode == 403) {
        return const AppException(
          'FORBIDDEN',
          'Anda tidak memiliki akses untuk tindakan ini.',
          statusCode: 403,
        );
      }
      if (response.statusCode == 404) {
        return const AppException(
          'NOT_FOUND',
          'Data tidak ditemukan.',
          statusCode: 404,
        );
      }
      if (response.statusCode == 429) {
        return const AppException(
          'RATE_LIMITED',
          'Terlalu banyak permintaan. Coba lagi sebentar.',
          statusCode: 429,
          retryable: true,
        );
      }
      if ((response.statusCode ?? 0) >= 500) {
        return const AppException(
          'SERVER_ERROR',
          'Server sedang bermasalah. Coba lagi.',
          retryable: true,
        );
      }
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return AppException.network();
      case DioExceptionType.cancel:
        return const AppException(
          'REQUEST_CANCELLED',
          'Permintaan dibatalkan.',
        );
      default:
        return AppException.network(
          'Koneksi ke server gagal. Periksa alamat server dan jaringan.',
        );
    }
  }
}
