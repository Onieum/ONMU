import 'package:dio/dio.dart';

import '../../features/auth/domain/auth_session.dart';

/// 순환 의존을 피하기 위해 OnmuApiClient/Repository를 거치지 않고
/// Dio로 직접 refresh endpoint를 호출하는 서비스.
class TokenRefreshService {
  TokenRefreshService({required String baseUrl})
      : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 8),
            receiveTimeout: const Duration(seconds: 12),
            headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
          ),
        );

  final Dio _dio;

  /// refresh 토큰으로 새 토큰 쌍을 갱신.
  /// permitAll 엔드포인트이므로 Authorization 헤더 없이 호출.
  Future<OnmuAuthTokens?> refreshTokens(String refreshToken) async {
    if (refreshToken.trim().isEmpty) {
      return null;
    }

    try {
      final response = await _dio.post<Object?>(
        '/api/v1/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      final json = response.data;
      if (json is! Map<String, dynamic>) {
        return null;
      }

      final tokensData = json['tokens'];
      if (tokensData is! Map<String, dynamic>) {
        return null;
      }

      return OnmuAuthTokens.fromJson(tokensData);
    } on DioException catch (error) {
      // 401/403은 갱신 불가로 처리
      if (error.response?.statusCode == 401 ||
          error.response?.statusCode == 403) {
        return null;
      }
      rethrow;
    }
  }
}
