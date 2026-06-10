import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../shared/auth/providers/auth_providers.dart';
import '../config/app_config.dart';
import '../errors/error_mapper.dart';
import '../utils/logger.dart';
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
  AppLogger.debug(
    '${options.method} ${options.baseUrl}${options.path} | query=${options.queryParameters} | body=${options.data}',
    tag: 'HTTP',
  );
}

void _logResponse(Response response) {
  AppLogger.info(
    '${response.statusCode} ${response.requestOptions.method} ${response.requestOptions.baseUrl}${response.requestOptions.path}',
    tag: 'HTTP',
  );
}

void _logError(DioException error) {
  AppLogger.error(
    '${error.response?.statusCode} ${error.requestOptions.method} ${error.requestOptions.baseUrl}${error.requestOptions.path}',
    tag: 'HTTP',
    error: error.response?.data ?? error,
    stackTrace: error.stackTrace,
  );
}