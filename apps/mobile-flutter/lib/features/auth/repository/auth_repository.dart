import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/onmu_api_client.dart';
import '../domain/auth_session.dart';
import '../domain/auth_user.dart';
import '../domain/oauth_provider_credential.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return ApiAuthRepository(ref.watch(onmuApiClientProvider));
});

abstract interface class AuthRepository {
  Future<AuthUser?> fetchCurrentUser();

  Future<AuthSession> exchangeOAuthLogin(OAuthProviderCredential credential);
}

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._client);

  final OnmuApiClient _client;

  @override
  Future<AuthUser?> fetchCurrentUser() async {
    try {
      final json = await _client.getObject('/api/v1/users/me');
      return authUserFromJson(json);
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
    });
    return AuthSession(user: user, tokens: tokens);
  }
}

AuthUser authUserFromJson(Map<String, dynamic> json) {
  final databaseId = OnmuJson.readString(json, 'databaseId');
  final publicId = OnmuJson.readString(json, 'id');
  final displayName = OnmuJson.readString(json, 'displayName');
  final nickname = OnmuJson.readString(json, 'nickname');
  final name = OnmuJson.readString(json, 'name');
  final username = OnmuJson.readString(json, 'username');
  return AuthUser(
    id: databaseId.isNotEmpty ? databaseId : publicId,
    publicId: publicId.isEmpty ? null : publicId,
    provider: OnmuJson.readString(json, 'authProvider', 'dev'),
    displayName: [
      displayName,
      nickname,
      name,
      username,
    ].firstWhere((value) => value.trim().isNotEmpty, orElse: () => '사용자'),
    email: OnmuJson.readString(json, 'email'),
    profileImageUrl: OnmuJson.readString(json, 'profileImageUrl'),
    onboardingStatus: OnmuJson.readString(json, 'onboardingStatus', 'PENDING'),
  );
}
