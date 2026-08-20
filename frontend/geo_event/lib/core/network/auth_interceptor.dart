import 'package:dio/dio.dart';

import '../../shared/auth/models/auth_response.dart';
import 'api_endpoints.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required Dio dio,
    required Future<String?> Function() accessTokenReader,
    required Future<String?> Function() refreshTokenReader,
    required Future<AuthResponse> Function(String refreshToken) refreshCall,
    required Future<void> Function(AuthResponse response) onRefreshSuccess,
    required Future<void> Function() onSessionExpired,
  })  : _dio = dio,
        _accessTokenReader = accessTokenReader,
        _refreshTokenReader = refreshTokenReader,
        _refreshCall = refreshCall,
        _onRefreshSuccess = onRefreshSuccess,
        _onSessionExpired = onSessionExpired;

  final Dio _dio;
  final Future<String?> Function() _accessTokenReader;
  final Future<String?> Function() _refreshTokenReader;
  final Future<AuthResponse> Function(String refreshToken) _refreshCall;
  final Future<void> Function(AuthResponse response) _onRefreshSuccess;
  final Future<void> Function() _onSessionExpired;

  Future<AuthResponse>? _refreshFuture;

  static const requiresAuthKey = 'requiresAuth';
  static const retriedKey = 'retried';
  static const allowRefreshKey = 'allowRefresh';

  static const Set<String> excludedPaths = {
    ApiEndpoints.login,
    ApiEndpoints.register,
    ApiEndpoints.forgotPassword,
    ApiEndpoints.refresh,
    ApiEndpoints.logout,
    ApiEndpoints.resetPassword,
  };

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final requiresAuth = (options.extra[requiresAuthKey] as bool?) ?? true;

    if (!requiresAuth || _isExcluded(options.path)) {
      handler.next(options);
      return;
    }

    final token = await _accessTokenReader();
    if (token != null && token.trim().isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final requestOptions = err.requestOptions;
    final statusCode = err.response?.statusCode;
    final requiresAuth =
        (requestOptions.extra[requiresAuthKey] as bool?) ?? true;
    final alreadyRetried =
        (requestOptions.extra[retriedKey] as bool?) ?? false;
    final allowRefresh =
        (requestOptions.extra[allowRefreshKey] as bool?) ?? true;

    final shouldHandleRefresh = statusCode == 401 &&
        requiresAuth &&
        allowRefresh &&
        !alreadyRetried &&
        !_isExcluded(requestOptions.path);

    if (!shouldHandleRefresh) {
      handler.next(err);
      return;
    }

    final refreshToken = await _refreshTokenReader();
    if (refreshToken == null || refreshToken.trim().isEmpty) {
      await _safeExpireSession();
      handler.next(err);
      return;
    }

    try {
      final refreshFuture = _refreshFuture ??= _refreshCall(refreshToken);
      final refreshed = await refreshFuture;

      if (!refreshed.hasTokens || refreshed.accessToken.trim().isEmpty) {
        await _safeExpireSession();
        handler.next(err);
        return;
      }

      await _onRefreshSuccess(refreshed);

      final retryOptions = requestOptions.copyWith(
        headers: {
          ...requestOptions.headers,
          'Authorization': 'Bearer ${refreshed.accessToken}',
        },
        extra: {
          ...requestOptions.extra,
          retriedKey: true,
        },
      );

      final response = await _dio.fetch<dynamic>(retryOptions);
      handler.resolve(response);
    } catch (_) {
      await _safeExpireSession();
      handler.next(err);
    } finally {
      _refreshFuture = null;
    }
  }

  bool _isExcluded(String path) {
    final normalized = _normalizePath(path);
    return excludedPaths.any((value) => _normalizePath(value) == normalized);
  }

  String _normalizePath(String path) {
    final uri = Uri.tryParse(path);
    final normalized = uri?.path ?? path;
    return normalized.startsWith('/') ? normalized : '/$normalized';
  }

  Future<void> _safeExpireSession() async {
    try {
      await _onSessionExpired();
    } catch (_) {}
  }
}