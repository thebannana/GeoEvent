import 'package:flutter/foundation.dart';

class AppEnvironment {
  const AppEnvironment._();

  static const String _apiBaseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  static const String _mapboxAccessToken =
      String.fromEnvironment('MAPBOX_ACCESS_TOKEN', defaultValue: '');

  static const String _appDeepLinkScheme =
      String.fromEnvironment('APP_DEEP_LINK_SCHEME', defaultValue: '');

  static const String _appDeepLinkHost =
      String.fromEnvironment('APP_DEEP_LINK_HOST', defaultValue: '');

  static String get apiBaseUrl {
    final value = _apiBaseUrl.trim();
    if (value.isNotEmpty) {
      return value;
    }

    if (kDebugMode) {
      return 'http://localhost:5000';
    }

    throw StateError(
      'API_BASE_URL is missing. Pass it using --dart-define=API_BASE_URL=http://localhost:5000',
    );
  }

  static String? get mapboxAccessToken {
    final value = _mapboxAccessToken.trim();
    return value.isEmpty ? null : value;
  }

  static String? get appDeepLinkScheme {
    final value = _appDeepLinkScheme.trim();
    return value.isEmpty ? null : value;
  }

  static String? get appDeepLinkHost {
    final value = _appDeepLinkHost.trim();
    return value.isEmpty ? null : value;
  }

  static String? get resetPasswordUrlBase {
    final scheme = appDeepLinkScheme;
    final host = appDeepLinkHost;

    if (scheme == null || host == null) {
      return null;
    }

    return '$scheme://$host/reset-password';
  }

  static String? get payPalReturnUrlBase {
    final scheme = appDeepLinkScheme;
    final host = appDeepLinkHost;

    if (scheme == null || host == null) {
      return null;
    }

    return '$scheme://$host/paypal/return';
  }

  static String? get payPalCancelUrlBase {
    final scheme = appDeepLinkScheme;
    final host = appDeepLinkHost;

    if (scheme == null || host == null) {
      return null;
    }

    return '$scheme://$host/paypal/cancel';
  }

  static bool get hasMapbox => mapboxAccessToken != null;
  static bool get hasDeepLinkConfig =>
      appDeepLinkScheme != null && appDeepLinkHost != null;

  static void validateCore() {
    apiBaseUrl;
  }

  static void validateMaps() {
    final token = mapboxAccessToken;
    if (token == null || token.isEmpty) {
      throw StateError(
        'MAPBOX_ACCESS_TOKEN is missing. Pass it using --dart-define=MAPBOX_ACCESS_TOKEN=your_token',
      );
    }
  }

  static void validateDeepLinks() {
    final scheme = appDeepLinkScheme;
    final host = appDeepLinkHost;

    if (scheme == null || scheme.isEmpty) {
      throw StateError(
        'APP_DEEP_LINK_SCHEME is missing. Pass it using --dart-define=APP_DEEP_LINK_SCHEME=geoevent',
      );
    }

    if (host == null || host.isEmpty) {
      throw StateError(
        'APP_DEEP_LINK_HOST is missing. Pass it using --dart-define=APP_DEEP_LINK_HOST=open',
      );
    }
  }

  static void validateAll() {
    validateCore();
    validateMaps();
  }
}