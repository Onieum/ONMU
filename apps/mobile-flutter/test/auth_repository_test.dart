import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/core/api/onmu_api_client.dart';
import 'package:onmu_mobile/features/auth/domain/oauth_provider_credential.dart';
import 'package:onmu_mobile/features/auth/repository/auth_repository.dart';

void main() {
  test('maps the current dev user from users me API', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.path, '/api/v1/users/me');
          handler.resolve(
            Response<Object?>(
              requestOptions: options,
              data: {
                'databaseId': '00000000-0000-0000-0000-000000000001',
                'id': 'user-me',
                'displayName': '나',
                'email': 'me@example.test',
                'profileImageUrl': 'dev/avatars/user-me.png',
                'onboardingStatus': 'COMPLETED',
                'authProvider': 'NAVER',
              },
            ),
          );
        },
      ),
    );
    final repository = ApiAuthRepository(OnmuApiClient(dio));

    final user = await repository.fetchCurrentUser();

    expect(user, isNotNull);
    expect(user!.id, '00000000-0000-0000-0000-000000000001');
    expect(user.publicId, 'user-me');
    expect(user.displayName, '나');
    expect(user.onboardingStatus, 'COMPLETED');
    expect(user.hasCompletedOnboarding, isTrue);
  });

  test('maps fallback user name fields when displayName is absent', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response<Object?>(
              requestOptions: options,
              data: {
                'databaseId': '00000000-0000-0000-0000-000000000001',
                'id': 'user-me',
                'nickname': '지무',
                'email': 'me@example.test',
                'authProvider': 'NAVER',
              },
            ),
          );
        },
      ),
    );
    final repository = ApiAuthRepository(OnmuApiClient(dio));

    final user = await repository.fetchCurrentUser();

    expect(user, isNotNull);
    expect(user!.displayName, '지무');
  });

  test(
    'exchanges Kakao provider token for ONMU tokens without using it as bearer',
    () async {
      const providerToken = 'kakao-provider-token';
      final dio = Dio(BaseOptions(baseUrl: 'https://dev-api.onmu.cloud'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.path, '/api/v1/auth/oauth/kakao');
            expect(
              options.headers['Authorization'],
              isNot('Bearer $providerToken'),
            );
            expect(options.data, {'providerAccessToken': providerToken});
            handler.resolve(
              Response<Object?>(
                requestOptions: options,
                data: {
                  'ok': true,
                  'authenticated': true,
                  'tokens': {
                    'accessToken': 'onmu-access-jwt',
                    'refreshToken': 'onmu-refresh-token',
                    'tokenType': 'Bearer',
                    'accessTokenExpiresAt': '2026-06-11T10:00:00Z',
                    'refreshTokenExpiresAt': '2026-07-11T10:00:00Z',
                  },
                  'user': {
                    'id': 'usr_kakao',
                    'displayName': '카카오 사용자',
                    'onboardingStatus': 'PENDING',
                  },
                },
              ),
            );
          },
        ),
      );
      final repository = ApiAuthRepository(OnmuApiClient(dio));

      final session = await repository.exchangeOAuthLogin(
        const OAuthProviderCredential(
          provider: 'kakao',
          providerAccessToken: providerToken,
        ),
      );

      expect(session.tokens.accessToken, 'onmu-access-jwt');
      expect(session.tokens.refreshToken, 'onmu-refresh-token');
      expect(session.user.publicId, 'usr_kakao');
      expect(session.user.provider, 'KAKAO');
      expect(session.user.displayName, '카카오 사용자');
    },
  );

  test(
    'exchanges Naver provider token for ONMU tokens without using it as bearer',
    () async {
      const providerToken = 'naver-provider-token';
      final dio = Dio(BaseOptions(baseUrl: 'https://dev-api.onmu.cloud'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.path, '/api/v1/auth/oauth/naver');
            expect(
              options.headers['Authorization'],
              isNot('Bearer $providerToken'),
            );
            expect(options.data, {'providerAccessToken': providerToken});
            handler.resolve(
              Response<Object?>(
                requestOptions: options,
                data: {
                  'ok': true,
                  'authenticated': true,
                  'tokens': {
                    'accessToken': 'onmu-access-jwt',
                    'refreshToken': 'onmu-refresh-token',
                    'tokenType': 'Bearer',
                    'accessTokenExpiresAt': '2026-06-11T10:00:00Z',
                    'refreshTokenExpiresAt': '2026-07-11T10:00:00Z',
                  },
                  'user': {
                    'id': 'usr_naver',
                    'displayName': '네이버 사용자',
                    'onboardingStatus': 'PENDING',
                  },
                },
              ),
            );
          },
        ),
      );
      final repository = ApiAuthRepository(OnmuApiClient(dio));

      final session = await repository.exchangeOAuthLogin(
        const OAuthProviderCredential(
          provider: 'naver',
          providerAccessToken: providerToken,
        ),
      );

      expect(session.tokens.accessToken, 'onmu-access-jwt');
      expect(session.tokens.refreshToken, 'onmu-refresh-token');
      expect(session.user.publicId, 'usr_naver');
      expect(session.user.provider, 'NAVER');
      expect(session.user.displayName, '네이버 사용자');
    },
  );

  test(
    'exchanges Naver authorization code and state for ONMU tokens',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://dev-api.onmu.cloud'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.path, '/api/v1/auth/oauth/naver');
            expect(options.headers['Authorization'], isNull);
            expect(options.data, {
              'authorizationCode': 'naver-auth-code',
              'state': 'state-123',
            });
            handler.resolve(
              Response<Object?>(
                requestOptions: options,
                data: {
                  'ok': true,
                  'authenticated': true,
                  'tokens': {
                    'accessToken': 'onmu-access-jwt',
                    'refreshToken': 'onmu-refresh-token',
                    'tokenType': 'Bearer',
                    'accessTokenExpiresAt': '2026-06-11T10:00:00Z',
                    'refreshTokenExpiresAt': '2026-07-11T10:00:00Z',
                  },
                  'user': {
                    'id': 'usr_naver_code',
                    'displayName': '네이버 사용자',
                    'onboardingStatus': 'PENDING',
                  },
                },
              ),
            );
          },
        ),
      );
      final repository = ApiAuthRepository(OnmuApiClient(dio));

      final session = await repository.exchangeOAuthLogin(
        const OAuthProviderCredential(
          provider: 'naver',
          authorizationCode: 'naver-auth-code',
          state: 'state-123',
        ),
      );

      expect(session.tokens.accessToken, 'onmu-access-jwt');
      expect(session.user.publicId, 'usr_naver_code');
      expect(session.user.provider, 'NAVER');
    },
  );
}
