import 'dart:async';

import 'package:dio/dio.dart';

import '../../shared/auth/models/auth_response.dart';
import 'api_endpoints.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required Dio dio,
    required Future<String?> Function() accessTokenReader,
    required Future<String?> Function() refreshTokenReader,
    required Future<AuthResponse> Function(String refreshToken) refreshCall,
    required Future<void> Function() onSessionExpired,
  })  : _dio = dio,
        _accessTokenReader = accessTokenReader,
        _refreshTokenReader = refreshTokenReader,
        _refreshCall = refreshCall,
        _onSessionExpired = onSessionExpired;

  final Dio _dio;
  final Future<String?> Function() _accessTokenReader;
  final Future<String?> Function() _refreshTokenReader;
  final Future<AuthResponse> Function(String refreshToken) _refreshCall;
  final Future<void> Function() _onSessionExpired;

  Future<AuthResponse>? _refreshFuture;

  static const _requiresAuthKey = 'requiresAuth';
  static const _retriedKey = 'retried';

  static const Set<String> _excludedPaths = {
    ApiEndpoints.login,
    ApiEndpoints.register,
    ApiEndpoints.forgotPassword,
    ApiEndpoints.refresh,
    ApiEndpoints.logout,
  };

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final requiresAuth = (options.extra[_requiresAuthKey] as bool?) ?? true;

    if (!requiresAuth || _isExcluded(options.path)) {
      handler.next(options);
      return;
    }

    final token = await _accessTokenReader();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode = err.response?.statusCode;
    final requestOptions = err.requestOptions;

    final requiresAuth = (requestOptions.extra[_requiresAuthKey] as bool?) ?? true;
    final alreadyRetried = (requestOptions.extra[_retriedKey] as bool?) ?? false;

    final shouldHandleRefresh = statusCode == 401 &&
        requiresAuth &&
        !alreadyRetried &&
        !_isExcluded(requestOptions.path);

    if (!shouldHandleRefresh) {
      handler.next(err);
      return;
    }

    final refreshToken = await _refreshTokenReader();
    if (refreshToken == null || refreshToken.isEmpty) {
      await _safeExpireSession();
      handler.next(err);
      return;
    }

    try {
      _refreshFuture ??= _refreshCall(refreshToken);

      final refreshed = await _refreshFuture!;
      _refreshFuture = null;

      if (!refreshed.hasTokens) {
        await _safeExpireSession();
        handler.next(err);
        return;
      }

      final retryToken = refreshed.accessToken;
      final retryOptions = _cloneRequestOptions(requestOptions);
      retryOptions.extra[_retriedKey] = true;
      retryOptions.headers['Authorization'] = 'Bearer $retryToken';

      final response = await _dio.fetch<dynamic>(retryOptions);
      handler.resolve(response);
    } catch (_) {
      _refreshFuture = null;
      await _safeExpireSession();
      handler.next(err);
    }
  }

  bool _isExcluded(String path) {
    final normalized = _normalizePath(path);
    return _excludedPaths.any((value) => _normalizePath(value) == normalized);
  }

  String _normalizePath(String path) {
    final uri = Uri.tryParse(path);
    final normalized = uri?.path ?? path;
    if (normalized.startsWith('/')) return normalized;
    return '/$normalized';
  }

  Future<void> _safeExpireSession() async {
    try {
      await _onSessionExpired();
    } catch (_) {}
  }

  RequestOptions _cloneRequestOptions(RequestOptions options) {
    return RequestOptions(
      path: options.path,
      method: options.method,
      baseUrl: options.baseUrl,
      data: options.data,
      queryParameters: Map<String, dynamic>.from(options.queryParameters),
      headers: Map<String, dynamic>.from(options.headers),
      extra: Map<String, dynamic>.from(options.extra),
      connectTimeout: options.connectTimeout,
      sendTimeout: options.sendTimeout,
      receiveTimeout: options.receiveTimeout,
      responseType: options.responseType,
      contentType: options.contentType,
      validateStatus: options.validateStatus,
      receiveDataWhenStatusError: options.receiveDataWhenStatusError,
      followRedirects: options.followRedirects,
      maxRedirects: options.maxRedirects,
      requestEncoder: options.requestEncoder,
      responseDecoder: options.responseDecoder,
      listFormat: options.listFormat,
      persistentConnection: options.persistentConnection,
    );
  }
}