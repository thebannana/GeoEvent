import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_roles.dart';
import '../models/auth_response.dart';
import '../models/auth_state.dart';
import '../models/auth_user.dart';

class AuthLocalStorage {
  AuthLocalStorage(this._prefs);

  final SharedPreferences _prefs;

  static const _accessTokenKey = 'auth.access_token';
  static const _refreshTokenKey = 'auth.refresh_token';
  static const _expiresAtKey = 'auth.expires_at';
  static const _userKey = 'auth.user';
  static const _rememberMeKey = 'auth.remember_me';

  bool get shouldPersistSession => _prefs.getBool(_rememberMeKey) ?? false;

  Future<void> saveSession(
    AuthResponse response, {
    required bool rememberMe,
  }) async {
    await Future.wait([
      _prefs.setString(_accessTokenKey, response.accessToken.trim()),
      _prefs.setString(_refreshTokenKey, response.refreshToken.trim()),
      _prefs.setBool(_rememberMeKey, rememberMe),
      if (response.expiresAt != null)
        _prefs.setString(
          _expiresAtKey,
          response.expiresAt!.toUtc().toIso8601String(),
        )
      else
        Future.value(_prefs.remove(_expiresAtKey)),
      if (response.user != null)
        _prefs.setString(_userKey, jsonEncode(response.user!.toJson()))
      else
        Future.value(_prefs.remove(_userKey)),
    ]);
  }

  Future<AuthState> readSession() async {
    final shouldRestore = shouldPersistSession;
    if (!shouldRestore) {
      await clearSession();
      return const AuthState.unauthenticated(isInitialized: true);
    }

    final accessToken = _normalize(_prefs.getString(_accessTokenKey));
    final refreshToken = _normalize(_prefs.getString(_refreshTokenKey));
    final expiresAtRaw = _prefs.getString(_expiresAtKey);
    final userRaw = _prefs.getString(_userKey);
    final user = _parseUser(userRaw);

    final isAdmin = user != null &&
        user.role.trim().toLowerCase() ==
            AppRoles.admin.trim().toLowerCase();

    if (!isAdmin || refreshToken == null || refreshToken.isEmpty) {
      await clearSession();
      return const AuthState.unauthenticated(isInitialized: true);
    }

    return AuthState(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: _parseDate(expiresAtRaw),
      user: user,
      isLoading: false,
      isInitialized: true,
    );
  }

  Future<void> clearSession() async {
    await Future.wait([
      _prefs.remove(_accessTokenKey),
      _prefs.remove(_refreshTokenKey),
      _prefs.remove(_expiresAtKey),
      _prefs.remove(_userKey),
      _prefs.remove(_rememberMeKey),
    ]);
  }

  String? _normalize(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  DateTime? _parseDate(String? raw) {
    final normalized = _normalize(raw);
    if (normalized == null) {
      return null;
    }

    return DateTime.tryParse(normalized);
  }

  AuthUser? _parseUser(String? raw) {
    final normalized = _normalize(raw);
    if (normalized == null) {
      return null;
    }

    try {
      final decoded = jsonDecode(normalized);

      if (decoded is Map<String, dynamic>) {
        return AuthUser.fromJson(decoded);
      }

      if (decoded is Map) {
        return AuthUser.fromJson(Map<String, dynamic>.from(decoded));
      }

      return null;
    } catch (_) {
      return null;
    }
  }
}