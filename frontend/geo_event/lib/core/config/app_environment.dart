import 'package:flutter/foundation.dart';

class AppEnvironment {
  const AppEnvironment._();

  static const String _apiBaseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  static const String _mapboxAccessToken =
      String.fromEnvironment('MAPBOX_ACCESS_TOKEN', defaultValue: '');

  static const String _appDeepLinkScheme =
      String.fromEnvironment('APP_DEEP_LINK_SCHEME', defaultValue: 'geoevent');

  static const String _appDeepLinkHost =
      String.fromEnvironment('APP_DEEP_LINK_HOST', defaultValue: 'open');

  static String get apiBaseUrl {
    final value = _apiBaseUrl.trim();
    if (value.isNotEmpty) {
      return value;
    }

    if (kDebugMode) {
      return 'http://10.0.2.2:5000';
    }

    throw StateError(
      'API_BASE_URL is missing. Pass it using --dart-define=API_BASE_URL=https://your-api-url',
    );
  }

  static String get mapboxAccessToken {
    final value = _mapboxAccessToken.trim();
    if (value.isEmpty) {
      throw StateError(
        'MAPBOX_ACCESS_TOKEN is missing. Pass it using --dart-define=MAPBOX_ACCESS_TOKEN=your_token',
      );
    }

    return value;
  }

  static String get appDeepLinkScheme {
    final value = _appDeepLinkScheme.trim();
    if (value.isEmpty) {
      throw StateError(
        'APP_DEEP_LINK_SCHEME is missing. Pass it using --dart-define=APP_DEEP_LINK_SCHEME=geoevent',
      );
    }
    return value;
  }

  static String get appDeepLinkHost {
    final value = _appDeepLinkHost.trim();
    if (value.isEmpty) {
      throw StateError(
        'APP_DEEP_LINK_HOST is missing. Pass it using --dart-define=APP_DEEP_LINK_HOST=open',
      );
    }
    return value;
  }

  static String get resetPasswordUrlBase =>
      '$appDeepLinkScheme://$appDeepLinkHost/reset-password';

  static String get payPalReturnUrlBase =>
      '$appDeepLinkScheme://$appDeepLinkHost/paypal/return';

  static String get payPalCancelUrlBase =>
      '$appDeepLinkScheme://$appDeepLinkHost/paypal/cancel';

  static void validateCore() {
    apiBaseUrl;
    appDeepLinkScheme;
    appDeepLinkHost;
  }

  static void validateMaps() {
    mapboxAccessToken;
  }

  static void validateAll() {
    validateCore();
    validateMaps();
  }
}