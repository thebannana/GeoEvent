import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/utils/json_helpers.dart';
import '../models/auth_response.dart';
import '../models/auth_state.dart';
import '../models/auth_user.dart';

class AuthLocalStorage {
  AuthLocalStorage(this._storage);

  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'auth.access_token';
  static const _refreshTokenKey = 'auth.refresh_token';
  static const _expiresAtKey = 'auth.expires_at';
  static const _userKey = 'auth.user';

  Future<void> saveSession(AuthResponse response) async {
    await Future.wait([
      _storage.write(
        key: _accessTokenKey,
        value: response.accessToken,
      ),
      _storage.write(
        key: _refreshTokenKey,
        value: response.refreshToken,
      ),
      _storage.write(
        key: _expiresAtKey,
        value: response.expiresAt?.toUtc().toIso8601String(),
      ),
      if (response.user != null)
        _storage.write(
          key: _userKey,
          value: jsonEncode(response.user!.toJson()),
        )
      else
        _storage.delete(key: _userKey),
    ]);
  }

  Future<AuthState> readSession() async {
    final values = await Future.wait([
      _storage.read(key: _accessTokenKey),
      _storage.read(key: _refreshTokenKey),
      _storage.read(key: _expiresAtKey),
      _storage.read(key: _userKey),
    ]);

    final accessToken = values[0];
    final refreshToken = values[1];
    final expiresAtRaw = values[2];
    final userRaw = values[3];

    return AuthState(
      accessToken: JsonHelpers.normalize(accessToken),
      refreshToken: JsonHelpers.normalize(refreshToken),
      expiresAt: JsonHelpers.parseDateTime(expiresAtRaw),
      user: _parseUser(userRaw),
      isLoading: false,
      isInitialized: true,
    );
  }

  Future<void> clearSession() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _expiresAtKey),
      _storage.delete(key: _userKey),
    ]);
  }

  AuthUser? _parseUser(String? raw) {
    final normalized = JsonHelpers.normalize(raw);

    if (normalized == null) {
      return null;
    }

    try {
      final decoded = jsonDecode(normalized);

      if (decoded is Map<String, dynamic>) {
        return AuthUser.fromJson(decoded);
      }

      if (decoded is Map) {
        return AuthUser.fromJson(
          Map<String, dynamic>.from(decoded),
        );
      }
    } catch (_) {
    }

    return null;
  }
}