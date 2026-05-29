import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

class AppConfig {
  static const String _androidEmulatorBaseUrl = 'http://10.0.2.2:5000';
  static const String _iosSimulatorBaseUrl = 'http://localhost:5000';
  static const String _webBaseUrl = 'http://localhost:5000';
  static const String _defaultBaseUrl = 'http://localhost:5000';

  static String get baseUrl {
    if (kIsWeb) {
      return _webBaseUrl;
    }

    if (Platform.isAndroid) {
      return _androidEmulatorBaseUrl;
    }

    if (Platform.isIOS) {
      return _iosSimulatorBaseUrl;
    }

    return _defaultBaseUrl;
  }
}