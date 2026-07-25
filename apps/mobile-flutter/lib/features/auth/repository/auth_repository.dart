import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/onmu_api_client.dart';
import '../../../core/error/onmu_exception.dart';
import '../../../shared/utils/onmu_display_name.dart';
import '../../../shared/utils/onmu_profile_image.dart';
import '../domain/auth_session.dart';
import '../domain/auth_user.dart';
import '../domain/oauth_provider_credential.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return ApiAuthRepository(ref.watch(onmuApiClientProvider));
});

abstract interface class AuthRepository {
  Future<AuthUser?> fetchCurrentUser();

  Future<AuthSession> exchangeOAuthLogin(OAuthProviderCredential credential);

  Future<OnmuAuthTokens?> refreshTokens(String refreshToken);

  Future<void> logout(String? refreshToken);

  Future<void> withdraw();
}

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._client);

  final OnmuApiClient _client;

  @override
  Future<AuthUser?> fetchCurrentUser() async {
    try {
      final json = await _client.getObject('/api/v1/users/me');
      return authUserFromJson(json, mediaBaseUrl: _client.baseUrl);
    } on OnmuApiException catch (error) {
      final statusCode = error.statusCode;
      if (statusCode == 401 || statusCode == 403) {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<AuthSession> exchangeOAuthLogin(
    OAuthProviderCredential credential,
  ) async {
    final provider = credential.provider.trim().toLowerCase();
    final json = await _client.postObject(
      '/api/v1/auth/oauth/$provider',
      body: credential.toRequestBody(),
    );
    final tokens = OnmuAuthTokens.fromJson(OnmuJson.asMap(json['tokens']));
    final userJson = OnmuJson.asMap(json['user']);
    final user = authUserFromJson({
      ...userJson,
      if (OnmuJson.readString(userJson, 'authProvider').isEmpty)
        'authProvider': provider.toUpperCase(),
    }, mediaBaseUrl: _client.baseUrl);
    return AuthSession(user: user, tokens: tokens);
  }

  @override
  Future<OnmuAuthTokens?> refreshTokens(String refreshToken) async {
    final token = refreshToken.trim();
    if (token.isEmpty) {
      return null;
    }
    // /api/v1/auth/refresh 는 permitAll 이므로 만료된 access bearer 를 보내면
    // 토큰 검증 필터가 401 을 줄 수 있다. refresh 호출 전 authorization 헤더를 비운다.
    _client.clearAccessToken();
    try {
      final json = await _client.postObject(
        '/api/v1/auth/refresh',
        body: {'refreshToken': token},
      );
      return OnmuAuthTokens.fromJson(OnmuJson.asMap(json['tokens']));
    } on OnmuApiException catch (error) {
      final statusCode = error.statusCode;
      if (statusCode == 401 || statusCode == 403) {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<void> logout(String? refreshToken) async {
    await _client.postObject(
      '/api/v1/auth/logout',
      body: {
        if (refreshToken != null && refreshToken.trim().isNotEmpty)
          'refreshToken': refreshToken.trim(),
      },
    );
  }

  @override
  Future<void> withdraw() async {
    await _client.deleteObject('/api/v1/users/me');
  }
}

AuthUser authUserFromJson(
  Map<String, dynamic> json, {
  String mediaBaseUrl = defaultOnmuApiBaseUrl,
}) {
  final databaseId = OnmuJson.readString(json, 'databaseId');
  final publicId = OnmuJson.readString(json, 'id');
  final nickname = OnmuJson.readString(json, 'nickname');
  final name = OnmuJson.readString(json, 'name');
  final username = OnmuJson.readString(json, 'username');
  return AuthUser(
    id: databaseId.isNotEmpty ? databaseId : publicId,
    publicId: publicId.isEmpty ? null : publicId,
    provider: OnmuJson.readString(json, 'authProvider', 'dev'),
    nickname: resolveOnmuDisplayName([
      nickname,
      name,
      username,
    ], fallback: '사용자'),
    email: OnmuJson.readString(json, 'email'),
    profileImageUrl: resolveOnmuProfileImageUrl(json, baseUrl: mediaBaseUrl),
    onboardingStatus: OnmuJson.readString(json, 'onboardingStatus', 'PENDING'),
  );
}
