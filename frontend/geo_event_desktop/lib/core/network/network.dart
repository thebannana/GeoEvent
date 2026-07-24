import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../shared/auth/providers/auth_providers.dart';
import '../config/environment.dart';
import '../errors/app_exceptions.dart';
import '../errors/error_mapper.dart';
import '../utils/logger.dart';
import 'auth_interceptor.dart';
import 'network_info.dart';

final networkInfoProvider = Provider<NetworkInfo>((ref) {
  return NetworkInfoImpl();
});

final dioBaseOptionsProvider = Provider<BaseOptions>((ref) {
  return BaseOptions(
    baseUrl: AppEnvironment.apiBaseUrl,
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 20),
    sendTimeout: const Duration(seconds: 20),
    headers: const {
      'Accept': 'application/json',
    },
  );
});

final baseDioProvider = Provider<Dio>((ref) {
  final dio = Dio(ref.watch(dioBaseOptionsProvider));
  _addCommonInterceptors(dio);
  return dio;
});

final authenticatedDioProvider = Provider<Dio>((ref) {
  final dio = Dio(ref.watch(dioBaseOptionsProvider));

  dio.interceptors.add(
    AuthInterceptor(
      dio: dio,
      accessTokenReader: () async => ref.read(authStateProvider).accessToken,
      refreshTokenReader: () async => ref.read(authStateProvider).refreshToken,
      refreshCall: (refreshToken) {
        return ref.read(refreshAuthApiProvider).refresh(refreshToken);
      },
      onRefreshSuccess: (response) async {
        final currentUser = ref.read(authStateProvider).user;
        await ref.read(authStateProvider.notifier).setAuthenticated(
              response,
              preserveUser: currentUser,
            );
      },
      onSessionExpired: () async {
        await ref.read(authStateProvider.notifier).clearSession();
      },
    ),
  );

  _addCommonInterceptors(dio);
  return dio;
});

void _addCommonInterceptors(Dio dio) {
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final data = options.data;

        if (data is FormData) {
          options.headers.remove(Headers.contentTypeHeader);
          options.contentType = 'multipart/form-data';
        } else {
          options.headers[Headers.contentTypeHeader] = Headers.jsonContentType;
          options.contentType = Headers.jsonContentType;
        }

        _logRequest(options);
        handler.next(options);
      },
      onResponse: (response, handler) {
        _logResponse(response);
        handler.next(response);
      },
      onError: (error, handler) {
        _logError(error);

        final mapped = error.error is AppException
            ? error.error as AppException
            : ErrorMapper.toAppException(
                error,
                stackTrace: error.stackTrace,
              );

        handler.reject(
          DioException(
            requestOptions: error.requestOptions,
            response: error.response,
            type: error.type,
            error: mapped,
            message: mapped.message,
            stackTrace: error.stackTrace,
          ),
        );
      },
    ),
  );
}

const _redacted = '***REDACTED***';

const _sensitiveKeys = {
  'authorization',
  'password',
  'currentpassword',
  'newpassword',
  'confirmpassword',
  'refreshtoken',
  'accesstoken',
  'token',
  'secret',
  'apikey',
  'api_key',
};

String _ansi(String code, String text, {bool enabled = false}) {
  if (!enabled) return text;
  return '$code$text\x1B[0m';
}

String _statusBadge(int? status, {bool color = false}) {
  if (status == null) {
    return _ansi('\x1B[35m', 'NO_STATUS', enabled: color);
  }
  if (status >= 500) {
    return _ansi('\x1B[31m', '$status SERVER', enabled: color);
  }
  if (status >= 400) {
    return _ansi('\x1B[33m', '$status CLIENT', enabled: color);
  }
  if (status >= 300) {
    return _ansi('\x1B[34m', '$status REDIRECT', enabled: color);
  }
  return _ansi('\x1B[32m', '$status OK', enabled: color);
}

dynamic _sanitizeValue(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is FormData) {
    return {
      'fields': value.fields.map((e) {
        final key = e.key;
        final normalized = key.toLowerCase();
        final sanitized =
            _sensitiveKeys.contains(normalized) ? _redacted : e.value;
        return MapEntry(key, sanitized);
      }).toList(),
      'files': value.files.map((e) => e.key).toList(),
    };
  }

  if (value is Map) {
    return value.map((key, val) {
      final normalizedKey = key.toString().toLowerCase();
      if (_sensitiveKeys.contains(normalizedKey)) {
        return MapEntry(key, _redacted);
      }
      return MapEntry(key, _sanitizeValue(val));
    });
  }

  if (value is List) {
    return value.map(_sanitizeValue).toList();
  }

  return value;
}

Map<String, dynamic> _sanitizeHeaders(Map<String, dynamic> headers) {
  return headers.map((key, value) {
    final normalizedKey = key.toLowerCase();
    if (_sensitiveKeys.contains(normalizedKey)) {
      return MapEntry(key, _redacted);
    }
    return MapEntry(key, value);
  });
}

void _logRequest(RequestOptions options) {
  if (!kDebugMode) return;
  const useAnsi = false;

  AppLogger.debug(
    '${_ansi('\x1B[36m', 'REQUEST', enabled: useAnsi)}\n'
    'Method : ${options.method}\n'
    'URL    : ${options.uri}\n'
    'Query  : ${options.queryParameters.isEmpty ? '{}' : _sanitizeValue(options.queryParameters)}\n'
    'Headers: ${_sanitizeHeaders(Map<String, dynamic>.from(options.headers))}\n'
    'Body   : ${_sanitizeValue(options.data)}',
    tag: 'HTTP',
  );
}

void _logResponse(Response response) {
  if (!kDebugMode) return;
  const useAnsi = false;
  final req = response.requestOptions;

  AppLogger.info(
    '${_statusBadge(response.statusCode, color: useAnsi)}\n'
    'Method : ${req.method}\n'
    'URL    : ${req.uri}\n'
    'Body   : ${_sanitizeValue(response.data)}',
    tag: 'HTTP',
  );
}

void _logError(DioException error) {
  if (!kDebugMode) return;
  const useAnsi = false;
  final req = error.requestOptions;
  final status = error.response?.statusCode;

  AppLogger.error(
    '${_statusBadge(status, color: useAnsi)}\n'
    'Method   : ${req.method}\n'
    'URL      : ${req.uri}\n'
    'Type     : ${error.type}\n'
    'Message  : ${error.message}\n'
    'Query    : ${req.queryParameters.isEmpty ? '{}' : _sanitizeValue(req.queryParameters)}\n'
    'Request  : ${_sanitizeValue(req.data)}\n'
    'Response : ${_sanitizeValue(error.response?.data)}',
    tag: 'HTTP',
    error: error.error,
    stackTrace: error.stackTrace,
  );
}