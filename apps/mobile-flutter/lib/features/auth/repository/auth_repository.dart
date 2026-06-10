import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/onmu_api_client.dart';
import '../domain/auth_user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return ApiAuthRepository(ref.watch(onmuApiClientProvider));
});

abstract interface class AuthRepository {
  Future<AuthUser?> fetchCurrentUser();
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
}

AuthUser authUserFromJson(Map<String, dynamic> json) {
  final databaseId = OnmuJson.readString(json, 'databaseId');
  final publicId = OnmuJson.readString(json, 'id');
  return AuthUser(
    id: databaseId.isNotEmpty ? databaseId : publicId,
    publicId: publicId.isEmpty ? null : publicId,
    provider: OnmuJson.readString(json, 'authProvider', 'dev'),
    displayName: OnmuJson.readString(json, 'displayName', '사용자'),
    email: OnmuJson.readString(json, 'email'),
    profileImageUrl: OnmuJson.readString(json, 'profileImageUrl'),
    onboardingStatus: OnmuJson.readString(json, 'onboardingStatus', 'PENDING'),
  );
}
