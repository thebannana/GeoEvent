import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../shared/auth/providers/auth_providers.dart';
import '../config/app_config.dart';
import '../errors/error_mapper.dart';
import 'auth_interceptor.dart';
import 'network_info.dart';

final networkInfoProvider = Provider<NetworkInfo>((ref) {
  return const NetworkInfoImpl();
});

final dioBaseOptionsProvider = Provider<BaseOptions>((ref) {
  return BaseOptions(
    baseUrl: AppConfig.baseUrl,
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 20),
    sendTimeout: const Duration(seconds: 20),
    headers: const {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    validateStatus: (status) => status != null && status >= 200 && status < 300,
  );
});

final baseDioProvider = Provider<Dio>((ref) {
  final dio = Dio(ref.watch(dioBaseOptionsProvider));

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        _logRequest(options);
        handler.next(options);
      },
      onResponse: (response, handler) {
        _logResponse(response);
        handler.next(response);
      },
      onError: (error, handler) {
        _logError(error);

        final mapped = ErrorMapper.toAppException(
          error.error ?? error,
          stackTrace: error.stackTrace,
        );

        handler.reject(
          DioException(
            requestOptions: error.requestOptions,
            response: error.response,
            type: error.type,
            error: mapped,
            message: mapped.message,
          ),
        );
      },
    ),
  );

  return dio;
});

final authorizedDioProvider = Provider<Dio>((ref) {
  final dio = Dio(ref.watch(dioBaseOptionsProvider));

  dio.interceptors.add(
    AuthInterceptor(
      dio: dio,
      accessTokenReader: () async => ref.read(authStateProvider).accessToken,
      refreshTokenReader: () async => ref.read(authStateProvider).refreshToken,
      refreshCall: (refreshToken) {
        return ref.read(authRepositoryProvider).refresh(refreshToken);
      },
      onSessionExpired: () async {
        ref.read(authStateProvider.notifier).clearSession();
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        _logRequest(options);
        handler.next(options);
      },
      onResponse: (response, handler) {
        _logResponse(response);
        handler.next(response);
      },
      onError: (error, handler) {
        _logError(error);

        final mapped = ErrorMapper.toAppException(
          error.error ?? error,
          stackTrace: error.stackTrace,
        );

        handler.reject(
          DioException(
            requestOptions: error.requestOptions,
            response: error.response,
            type: error.type,
            error: mapped,
            message: mapped.message,
          ),
        );
      },
    ),
  );

  return dio;
});

void _logRequest(RequestOptions options) {
  debugPrint('➡️ ${options.method} ${options.baseUrl}${options.path}');
  debugPrint('Headers: ${options.headers}');
  debugPrint('Query: ${options.queryParameters}');
  debugPrint('Body: ${options.data}');
}

void _logResponse(Response response) {
  debugPrint(
    '✅ ${response.statusCode} ${response.requestOptions.method} '
    '${response.requestOptions.baseUrl}${response.requestOptions.path}',
  );
  debugPrint('Response: ${response.data}');
}

void _logError(DioException error) {
  debugPrint(
    '❌ ${error.response?.statusCode} ${error.requestOptions.method} '
    '${error.requestOptions.baseUrl}${error.requestOptions.path}',
  );
  debugPrint('Query: ${error.requestOptions.queryParameters}');
  debugPrint('Body: ${error.requestOptions.data}');
  debugPrint('Response: ${error.response?.data}');
}