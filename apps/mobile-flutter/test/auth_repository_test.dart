import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/core/api/onmu_api_client.dart';
import 'package:onmu_mobile/features/auth/domain/oauth_provider_credential.dart';
import 'package:onmu_mobile/features/auth/repository/auth_repository.dart';

void main() {
  test('maps the current dev user from users me API', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://dev-api.onmu.cloud'));
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
                'nickname': '나',
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
    expect(user.nickname, '나');
    expect(
      user.profileImageUrl,
      'https://dev-api.onmu.cloud/api/v1/media/public?key=dev%2Favatars%2Fuser-me.png',
    );
    expect(user.onboardingStatus, 'COMPLETED');
    expect(user.hasCompletedOnboarding, isTrue);
  });

  test('maps nickname from current user API', () async {
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
    expect(user!.nickname, '지무');
  });

  test('treats unauthorized current user response as signed out', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://dev-api.onmu.cloud'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.badResponse,
              response: Response<Object?>(
                requestOptions: options,
                statusCode: 401,
              ),
            ),
          );
        },
      ),
    );
    final repository = ApiAuthRepository(OnmuApiClient(dio));

    final user = await repository.fetchCurrentUser();

    expect(user, isNull);
  });

  test('uses canonical nickname from auth response', () {
    final user = authUserFromJson({
      'databaseId': '00000000-0000-0000-0000-000000000001',
      'id': 'user-me',
      'nickname': '나',
      'authProvider': 'NAVER',
    });

    expect(user.nickname, '나');
  });

  test('falls back to non-default name when nickname is default', () {
    final user = authUserFromJson({
      'databaseId': '00000000-0000-0000-0000-000000000001',
      'id': 'user-me',
      'nickname': 'ONMU User',
      'name': '카카오 사용자',
      'authProvider': 'KAKAO',
    });

    expect(user.nickname, '카카오 사용자');
  });

  test('falls back when nickname and name are default values', () {
    final user = authUserFromJson({
      'databaseId': '00000000-0000-0000-0000-000000000001',
      'id': 'user-me',
      'nickname': '사용자',
      'name': 'ONMU User',
      'authProvider': 'KAKAO',
    });

    expect(user.nickname, '사용자');
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
                    'nickname': '카카오 사용자',
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
      expect(session.user.nickname, '카카오 사용자');
    },
  );

  test(
    'exchanges Kakao authorization code and state for ONMU tokens',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://dev-api.onmu.cloud'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.path, '/api/v1/auth/oauth/kakao');
            expect(options.headers['Authorization'], isNull);
            expect(options.data, {
              'authorizationCode': 'kakao-auth-code',
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
                    'id': 'usr_kakao_code',
                    'nickname': 'Kakao User',
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
          authorizationCode: 'kakao-auth-code',
          state: 'state-123',
        ),
      );

      expect(session.tokens.accessToken, 'onmu-access-jwt');
      expect(session.user.publicId, 'usr_kakao_code');
      expect(session.user.provider, 'KAKAO');
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
                    'nickname': '네이버 사용자',
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
      expect(session.user.nickname, '네이버 사용자');
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
                    'nickname': '네이버 사용자',
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

  test(
    'exchanges Google idToken for ONMU tokens without using it as bearer',
    () async {
      const googleIdToken = 'google-provider-id-token';
      final dio = Dio(BaseOptions(baseUrl: 'https://dev-api.onmu.cloud'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.path, '/api/v1/auth/oauth/google');
            expect(
              options.headers['Authorization'],
              isNot('Bearer $googleIdToken'),
            );
            expect(options.data, {'providerIdToken': googleIdToken});
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
                    'id': 'usr_google',
                    'nickname': 'Google User',
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
          provider: 'google',
          providerIdToken: googleIdToken,
        ),
      );

      expect(session.tokens.accessToken, 'onmu-access-jwt');
      expect(session.tokens.refreshToken, 'onmu-refresh-token');
      expect(session.user.publicId, 'usr_google');
      expect(session.user.provider, 'GOOGLE');
      expect(session.user.nickname, 'Google User');
    },
  );

  test('refreshes tokens via refresh endpoint without bearer header', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://dev-api.onmu.cloud'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.path, '/api/v1/auth/refresh');
          expect(options.headers['Authorization'], isNull);
          expect(options.data, {'refreshToken': 'stored-refresh'});
          handler.resolve(
            Response<Object?>(
              requestOptions: options,
              data: {
                'ok': true,
                'authenticated': true,
                'tokens': {
                  'accessToken': 'onmu-access-jwt-refreshed',
                  'refreshToken': 'onmu-refresh-token-rotated',
                  'tokenType': 'Bearer',
                  'accessTokenExpiresAt': '2026-06-11T11:00:00Z',
                  'refreshTokenExpiresAt': '2026-08-11T10:00:00Z',
                },
              },
            ),
          );
        },
      ),
    );
    final repository = ApiAuthRepository(OnmuApiClient(dio));

    final tokens = await repository.refreshTokens('stored-refresh');

    expect(tokens, isNotNull);
    expect(tokens!.accessToken, 'onmu-access-jwt-refreshed');
    expect(tokens.refreshToken, 'onmu-refresh-token-rotated');
  });

  test('treats invalid refresh token response as unrecoverable', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://dev-api.onmu.cloud'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.badResponse,
              response: Response<Object?>(
                requestOptions: options,
                statusCode: 401,
              ),
            ),
          );
        },
      ),
    );
    final repository = ApiAuthRepository(OnmuApiClient(dio));

    final tokens = await repository.refreshTokens('stored-refresh');

    expect(tokens, isNull);
  });
}
