import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/core/api/onmu_api_client.dart';
import 'package:onmu_mobile/features/auth/data/auth_token_store.dart';
import 'package:onmu_mobile/features/auth/data/kakao_oauth_credential_loader.dart';
import 'package:onmu_mobile/features/auth/data/naver_oauth_credential_loader.dart';
import 'package:onmu_mobile/features/auth/data/social_auth_service.dart';
import 'package:onmu_mobile/features/auth/domain/auth_session.dart';
import 'package:onmu_mobile/features/auth/domain/auth_user.dart';
import 'package:onmu_mobile/features/auth/domain/oauth_provider_credential.dart';
import 'package:onmu_mobile/features/auth/providers/auth_providers.dart';
import 'package:onmu_mobile/features/auth/repository/auth_repository.dart';

void main() {
  test(
    'Kakao action stores Spring ONMU tokens and applies ONMU access JWT',
    () async {
      const providerToken = 'kakao-provider-token';
      final tokenStore = InMemoryAuthTokenStore();
      final apiClient = OnmuApiClient(Dio());
      final repository = RecordingAuthRepository();
      final socialAuthService = SocialAuthService(
        kakaoCredentialLoader: () async => const OAuthProviderCredential(
          provider: 'kakao',
          providerAccessToken: providerToken,
        ),
      );
      final container = ProviderContainer(
        overrides: [
          socialAuthServiceProvider.overrideWithValue(socialAuthService),
          authRepositoryProvider.overrideWithValue(repository),
          authTokenStoreProvider.overrideWithValue(tokenStore),
          onmuApiClientProvider.overrideWithValue(apiClient),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authActionProvider).signInWithKakao();

      expect(repository.lastCredential?.provider, 'kakao');
      expect(repository.lastCredential?.providerAccessToken, providerToken);
      expect(container.read(authUserProvider)?.publicId, 'usr_kakao');
      expect((await tokenStore.read())?.accessToken, 'onmu-access-jwt');
      expect(apiClient.authorizationHeader, startsWith('Bearer '));
      expect(apiClient.authorizationHeader, contains('onmu-access-jwt'));
      expect(apiClient.authorizationHeader, isNot('Bearer $providerToken'));
    },
  );

  test(
    'OAuth login refreshes current user profile display name after token save',
    () async {
      const providerToken = 'kakao-provider-token';
      final tokenStore = InMemoryAuthTokenStore();
      final apiClient = OnmuApiClient(Dio());
      final repository = RecordingAuthRepository()
        ..currentUser = const AuthUser(
          id: 'usr_kakao',
          publicId: 'usr_kakao',
          provider: 'KAKAO',
          nickname: '카카오 프로필',
        );
      final socialAuthService = SocialAuthService(
        kakaoCredentialLoader: () async => const OAuthProviderCredential(
          provider: 'kakao',
          providerAccessToken: providerToken,
        ),
      );
      final container = ProviderContainer(
        overrides: [
          socialAuthServiceProvider.overrideWithValue(socialAuthService),
          authRepositoryProvider.overrideWithValue(repository),
          authTokenStoreProvider.overrideWithValue(tokenStore),
          onmuApiClientProvider.overrideWithValue(apiClient),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authActionProvider).signInWithKakao();

      expect(container.read(authUserProvider)?.nickname, '카카오 프로필');
      expect(apiClient.authorizationHeader, contains('onmu-access-jwt'));
    },
  );

  test('Kakao action fails safe when REST API key is missing', () async {
    final tokenStore = InMemoryAuthTokenStore();
    final apiClient = OnmuApiClient(Dio());
    final container = ProviderContainer(
      overrides: [
        authTokenStoreProvider.overrideWithValue(tokenStore),
        onmuApiClientProvider.overrideWithValue(apiClient),
      ],
    );
    addTearDown(container.dispose);

    await expectLater(
      container.read(authActionProvider).signInWithKakao(),
      throwsA(isA<KakaoSignInMissingClientIdException>()),
    );
    expect(container.read(authUserProvider), isNull);
    expect(apiClient.authorizationHeader, isNull);
    expect(await tokenStore.read(), isNull);
  });

  test(
    'Naver action exchanges provider token for Spring ONMU tokens',
    () async {
      const providerToken = 'naver-provider-token';
      final tokenStore = InMemoryAuthTokenStore();
      final apiClient = OnmuApiClient(Dio());
      final repository = RecordingAuthRepository();
      final socialAuthService = SocialAuthService(
        naverCredentialLoader: () async => const OAuthProviderCredential(
          provider: 'naver',
          providerAccessToken: providerToken,
        ),
      );
      final container = ProviderContainer(
        overrides: [
          socialAuthServiceProvider.overrideWithValue(socialAuthService),
          authRepositoryProvider.overrideWithValue(repository),
          authTokenStoreProvider.overrideWithValue(tokenStore),
          onmuApiClientProvider.overrideWithValue(apiClient),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authActionProvider).signInWithNaver();

      expect(repository.lastCredential?.provider, 'naver');
      expect(repository.lastCredential?.providerAccessToken, providerToken);
      expect(container.read(authUserProvider)?.publicId, 'usr_naver');
      expect((await tokenStore.read())?.accessToken, 'onmu-access-jwt');
      expect(apiClient.authorizationHeader, startsWith('Bearer '));
      expect(apiClient.authorizationHeader, contains('onmu-access-jwt'));
      expect(apiClient.authorizationHeader, isNot('Bearer $providerToken'));
    },
  );

  test('Naver action fails safe when client id is missing', () async {
    final tokenStore = InMemoryAuthTokenStore();
    final apiClient = OnmuApiClient(Dio());
    final container = ProviderContainer(
      overrides: [
        authTokenStoreProvider.overrideWithValue(tokenStore),
        onmuApiClientProvider.overrideWithValue(apiClient),
      ],
    );
    addTearDown(container.dispose);

    await expectLater(
      container.read(authActionProvider).signInWithNaver(),
      throwsA(isA<NaverSignInMissingClientIdException>()),
    );
    expect(container.read(authUserProvider), isNull);
    expect(apiClient.authorizationHeader, isNull);
    expect(await tokenStore.read(), isNull);
  });

  test(
    'Google action sends idToken to Spring and applies ONMU access JWT',
    () async {
      const googleIdToken = 'google-provider-id-token';
      final tokenStore = InMemoryAuthTokenStore();
      final apiClient = OnmuApiClient(Dio());
      final repository = RecordingAuthRepository();
      final socialAuthService = SocialAuthService(
        googleCredentialLoader: () async => const OAuthProviderCredential(
          provider: 'google',
          providerIdToken: googleIdToken,
        ),
      );
      final container = ProviderContainer(
        overrides: [
          socialAuthServiceProvider.overrideWithValue(socialAuthService),
          authRepositoryProvider.overrideWithValue(repository),
          authTokenStoreProvider.overrideWithValue(tokenStore),
          onmuApiClientProvider.overrideWithValue(apiClient),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authActionProvider).signInWithGoogle();

      expect(repository.lastCredential?.provider, 'google');
      expect(repository.lastCredential?.providerIdToken, googleIdToken);
      expect(repository.lastCredential?.providerAccessToken, isNull);
      expect(container.read(authUserProvider)?.publicId, 'usr_google');
      expect((await tokenStore.read())?.accessToken, 'onmu-access-jwt');
      expect(apiClient.authorizationHeader, startsWith('Bearer '));
      expect(apiClient.authorizationHeader, contains('onmu-access-jwt'));
      expect(apiClient.authorizationHeader, isNot('Bearer $googleIdToken'));
    },
  );

  test('Google action fails safe when idToken is unavailable', () async {
    final tokenStore = InMemoryAuthTokenStore();
    final apiClient = OnmuApiClient(Dio());
    final socialAuthService = SocialAuthService(
      googleCredentialLoader: () async =>
          throw const GoogleCredentialUnavailableException(),
    );
    final container = ProviderContainer(
      overrides: [
        socialAuthServiceProvider.overrideWithValue(socialAuthService),
        authTokenStoreProvider.overrideWithValue(tokenStore),
        onmuApiClientProvider.overrideWithValue(apiClient),
      ],
    );
    addTearDown(container.dispose);

    await expectLater(
      container.read(authActionProvider).signInWithGoogle(),
      throwsA(isA<GoogleCredentialUnavailableException>()),
    );
    expect(container.read(authUserProvider), isNull);
    expect(apiClient.authorizationHeader, isNull);
    expect(await tokenStore.read(), isNull);
  });

  test('Google web sign-in start failure keeps auth state empty', () async {
    final tokenStore = InMemoryAuthTokenStore();
    final apiClient = OnmuApiClient(Dio());
    final socialAuthService = SocialAuthService(
      googleCredentialLoader: () async =>
          throw const GoogleSignInWebButtonRequiredException(),
    );
    final container = ProviderContainer(
      overrides: [
        socialAuthServiceProvider.overrideWithValue(socialAuthService),
        authTokenStoreProvider.overrideWithValue(tokenStore),
        onmuApiClientProvider.overrideWithValue(apiClient),
      ],
    );
    addTearDown(container.dispose);

    await expectLater(
      container.read(authActionProvider).signInWithGoogle(),
      throwsA(isA<GoogleSignInWebButtonRequiredException>()),
    );
    expect(container.read(authUserProvider), isNull);
    expect(apiClient.authorizationHeader, isNull);
    expect(await tokenStore.read(), isNull);
  });

  test(
    'Google credential acquisition timeout keeps auth state empty',
    () async {
      final tokenStore = InMemoryAuthTokenStore();
      final apiClient = OnmuApiClient(Dio());
      final pendingCredential = Completer<OAuthProviderCredential>();
      final socialAuthService = SocialAuthService(
        googleCredentialLoader: () => pendingCredential.future,
      );
      final container = ProviderContainer(
        overrides: [
          socialAuthServiceProvider.overrideWithValue(socialAuthService),
          googleSignInTimeoutProvider.overrideWithValue(
            const Duration(milliseconds: 10),
          ),
          authTokenStoreProvider.overrideWithValue(tokenStore),
          onmuApiClientProvider.overrideWithValue(apiClient),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(authActionProvider).signInWithGoogle(),
        throwsA(isA<GoogleSignInTimeoutException>()),
      );
      expect(container.read(authUserProvider), isNull);
      expect(apiClient.authorizationHeader, isNull);
      expect(await tokenStore.read(), isNull);
    },
  );

  test(
    'signOut clears local session without touching provider session',
    () async {
      final tokenStore = InMemoryAuthTokenStore();
      final apiClient = OnmuApiClient(
        Dio(BaseOptions(baseUrl: defaultOnmuApiBaseUrl)),
      );
      final repository = RecordingAuthRepository();
      final socialAuthService = RecordingSignOutSocialAuthService();
      final container = ProviderContainer(
        overrides: [
          socialAuthServiceProvider.overrideWithValue(socialAuthService),
          authRepositoryProvider.overrideWithValue(repository),
          authTokenStoreProvider.overrideWithValue(tokenStore),
          onmuApiClientProvider.overrideWithValue(apiClient),
        ],
      );
      addTearDown(container.dispose);

      await tokenStore.save(
        const OnmuAuthTokens(
          accessToken: 'onmu-access-jwt',
          refreshToken: 'onmu-refresh-token',
        ),
      );
      apiClient.setAccessToken('onmu-access-jwt');
      container.read(authUserProvider.notifier).state = const AuthUser(
        id: 'usr_kakao',
        publicId: 'usr_kakao',
        provider: 'KAKAO',
        nickname: '카카오 사용자',
      );

      await container.read(authActionProvider).signOut();

      expect(repository.lastLogoutRefreshToken, 'onmu-refresh-token');
      expect(socialAuthService.signOutCallCount, 0);
      expect(container.read(authUserProvider), isNull);
      expect(apiClient.authorizationHeader, isNull);
      expect(await tokenStore.read(), isNull);
    },
  );
}

class RecordingAuthRepository implements AuthRepository {
  OAuthProviderCredential? lastCredential;
  AuthUser? currentUser;
  String? lastLogoutRefreshToken;

  @override
  Future<AuthUser?> fetchCurrentUser() async => currentUser;

  @override
  Future<AuthSession> exchangeOAuthLogin(
    OAuthProviderCredential credential,
  ) async {
    lastCredential = credential;
    final provider = credential.provider.toUpperCase();
    final userId = 'usr_${credential.provider.toLowerCase()}';
    return AuthSession(
      user: AuthUser(
        id: userId,
        publicId: userId,
        provider: provider,
        nickname: '$provider 사용자',
      ),
      tokens: OnmuAuthTokens(
        accessToken: 'onmu-access-jwt',
        refreshToken: 'onmu-refresh-token',
      ),
    );
  }

  @override
  Future<void> logout(String? refreshToken) async {
    lastLogoutRefreshToken = refreshToken;
  }

  @override
  Future<void> withdraw() async {}
}

class RecordingSignOutSocialAuthService extends SocialAuthService {
  int signOutCallCount = 0;

  @override
  Future<void> signOut({String? provider, String? onmuApiBaseUrl}) async {
    signOutCallCount += 1;
  }
}
