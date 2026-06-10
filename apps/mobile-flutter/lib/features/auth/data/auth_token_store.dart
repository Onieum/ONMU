import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/auth_session.dart';

final authTokenStoreProvider = Provider<AuthTokenStore>((ref) {
  return SecureAuthTokenStore();
});

abstract interface class AuthTokenStore {
  Future<OnmuAuthTokens?> read();

  Future<void> save(OnmuAuthTokens tokens);

  Future<void> clear();
}

class SecureAuthTokenStore implements AuthTokenStore {
  SecureAuthTokenStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _accessTokenKey = 'onmu.accessToken';
  static const _refreshTokenKey = 'onmu.refreshToken';
  static const _accessTokenExpiresAtKey = 'onmu.accessTokenExpiresAt';
  static const _refreshTokenExpiresAtKey = 'onmu.refreshTokenExpiresAt';
  static const _tokenTypeKey = 'onmu.tokenType';

  final FlutterSecureStorage _storage;

  @override
  Future<OnmuAuthTokens?> read() async {
    final accessToken = await _storage.read(key: _accessTokenKey);
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    if (accessToken == null ||
        accessToken.trim().isEmpty ||
        refreshToken == null ||
        refreshToken.trim().isEmpty) {
      return null;
    }

    return OnmuAuthTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      accessTokenExpiresAt: await _storage.read(key: _accessTokenExpiresAtKey),
      refreshTokenExpiresAt: await _storage.read(
        key: _refreshTokenExpiresAtKey,
      ),
      tokenType: await _storage.read(key: _tokenTypeKey) ?? 'Bearer',
    );
  }

  @override
  Future<void> save(OnmuAuthTokens tokens) async {
    await _storage.write(key: _accessTokenKey, value: tokens.accessToken);
    await _storage.write(key: _refreshTokenKey, value: tokens.refreshToken);
    await _writeOptional(_accessTokenExpiresAtKey, tokens.accessTokenExpiresAt);
    await _writeOptional(
      _refreshTokenExpiresAtKey,
      tokens.refreshTokenExpiresAt,
    );
    await _storage.write(key: _tokenTypeKey, value: tokens.tokenType);
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _accessTokenExpiresAtKey);
    await _storage.delete(key: _refreshTokenExpiresAtKey);
    await _storage.delete(key: _tokenTypeKey);
  }

  Future<void> _writeOptional(String key, String? value) {
    if (value == null || value.trim().isEmpty) {
      return _storage.delete(key: key);
    }
    return _storage.write(key: key, value: value);
  }
}

class InMemoryAuthTokenStore implements AuthTokenStore {
  OnmuAuthTokens? _tokens;

  @override
  Future<OnmuAuthTokens?> read() async => _tokens;

  @override
  Future<void> save(OnmuAuthTokens tokens) async {
    _tokens = tokens;
  }

  @override
  Future<void> clear() async {
    _tokens = null;
  }
}
