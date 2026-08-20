import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw StateError(
    'sharedPreferencesProvider must be overridden during application startup.',
  );
});

final themeModeControllerProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

class ThemeModeController extends Notifier<ThemeMode> {
  static const String _storageKey = 'theme_mode';

  @override
  ThemeMode build() {
    final preferences = ref.read(sharedPreferencesProvider);
    final storedValue = preferences.getString(_storageKey);

    return _decode(storedValue);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;

    final preferences = ref.read(sharedPreferencesProvider);
    await preferences.setString(_storageKey, _encode(mode));
  }

  Future<void> setDarkMode(bool isDark) {
    return setThemeMode(
      isDark ? ThemeMode.dark : ThemeMode.light,
    );
  }

  Future<void> useSystem() {
    return setThemeMode(ThemeMode.system);
  }

  bool get isSystemMode => state == ThemeMode.system;

  bool get isLightMode => state == ThemeMode.light;

  bool get isDarkMode => state == ThemeMode.dark;

  static ThemeMode _decode(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  static String _encode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}