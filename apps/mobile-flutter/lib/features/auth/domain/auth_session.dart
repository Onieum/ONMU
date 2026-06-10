import '../../../core/api/onmu_api_client.dart';
import 'auth_user.dart';

class AuthSession {
  const AuthSession({required this.user, required this.tokens});

  final AuthUser user;
  final OnmuAuthTokens tokens;
}

class OnmuAuthTokens {
  const OnmuAuthTokens({
    required this.accessToken,
    required this.refreshToken,
    this.accessTokenExpiresAt,
    this.refreshTokenExpiresAt,
    this.tokenType = 'Bearer',
  });

  final String accessToken;
  final String refreshToken;
  final String? accessTokenExpiresAt;
  final String? refreshTokenExpiresAt;
  final String tokenType;

  factory OnmuAuthTokens.fromJson(Map<String, dynamic> json) {
    return OnmuAuthTokens(
      accessToken: OnmuJson.readString(json, 'accessToken'),
      refreshToken: OnmuJson.readString(json, 'refreshToken'),
      accessTokenExpiresAt: _readNullableString(json, 'accessTokenExpiresAt'),
      refreshTokenExpiresAt: _readNullableString(json, 'refreshTokenExpiresAt'),
      tokenType: OnmuJson.readString(json, 'tokenType', 'Bearer'),
    );
  }

  Map<String, String> toStorageJson() {
    final json = {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'tokenType': tokenType,
    };
    final accessTokenExpiresAt = this.accessTokenExpiresAt;
    if (accessTokenExpiresAt != null) {
      json['accessTokenExpiresAt'] = accessTokenExpiresAt;
    }
    final refreshTokenExpiresAt = this.refreshTokenExpiresAt;
    if (refreshTokenExpiresAt != null) {
      json['refreshTokenExpiresAt'] = refreshTokenExpiresAt;
    }
    return json;
  }

  static String? _readNullableString(Map<String, dynamic> json, String key) {
    final value = OnmuJson.readString(json, key);
    return value.isEmpty ? null : value;
  }
}
