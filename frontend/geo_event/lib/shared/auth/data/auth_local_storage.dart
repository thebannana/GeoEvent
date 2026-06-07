import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
    await _storage.write(key: _accessTokenKey, value: response.accessToken);
    await _storage.write(key: _refreshTokenKey, value: response.refreshToken);
    await _storage.write(
      key: _expiresAtKey,
      value: response.expiresAt?.toUtc().toIso8601String(),
    );

    if (response.user != null) {
      await _storage.write(
        key: _userKey,
        value: jsonEncode(response.user!.toJson()),
      );
    } else {
      await _storage.delete(key: _userKey);
    }
  }

  Future<AuthState> readSession() async {
    final accessToken = await _storage.read(key: _accessTokenKey);
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    final expiresAtRaw = await _storage.read(key: _expiresAtKey);
    final userRaw = await _storage.read(key: _userKey);

    AuthUser? user;
    if (userRaw != null && userRaw.isNotEmpty) {
      final decoded = jsonDecode(userRaw);
      if (decoded is Map<String, dynamic>) {
        user = AuthUser.fromJson(decoded);
      } else if (decoded is Map) {
        user = AuthUser.fromJson(Map<String, dynamic>.from(decoded));
      }
    }

    return AuthState(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAtRaw != null && expiresAtRaw.isNotEmpty
          ? DateTime.tryParse(expiresAtRaw)
          : null,
      user: user,
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
}