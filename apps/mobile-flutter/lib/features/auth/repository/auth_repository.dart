import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/onmu_api_client.dart';
import '../../../core/api/onmu_media_url.dart';
import '../../../shared/utils/onmu_display_name.dart';
import '../domain/auth_session.dart';
import '../domain/auth_user.dart';
import '../domain/oauth_provider_credential.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return ApiAuthRepository(ref.watch(onmuApiClientProvider));
});

abstract interface class AuthRepository {
  Future<AuthUser?> fetchCurrentUser();

  Future<AuthSession> exchangeOAuthLogin(OAuthProviderCredential credential);

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
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
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
    profileImageUrl: resolveOnmuMediaUrl(
      OnmuJson.readString(json, 'profileImageUrl'),
      baseUrl: mediaBaseUrl,
    ),
    onboardingStatus: OnmuJson.readString(json, 'onboardingStatus', 'PENDING'),
  );
}
