import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/core/api/onmu_api_client.dart';
import 'package:onmu_mobile/features/auth/data/auth_token_store.dart';
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

  test(
    'Naver action fails safe until SDK credential acquisition is wired',
    () async {
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
        throwsA(isA<NaverSignInUnavailableException>()),
      );
      expect(container.read(authUserProvider), isNull);
      expect(apiClient.authorizationHeader, isNull);
      expect(await tokenStore.read(), isNull);
    },
  );

  test('Google action fails safe without Spring idToken verifier', () async {
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
      container.read(authActionProvider).signInWithGoogle(),
      throwsA(isA<GoogleSpringOAuthUnavailableException>()),
    );
    expect(container.read(authUserProvider), isNull);
    expect(apiClient.authorizationHeader, isNull);
    expect(await tokenStore.read(), isNull);
  });

  test('Google provider account event is not treated as ONMU session', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final accepted = container
        .read(authActionProvider)
        .applyGoogleAuthUser(
          const AuthUser(
            id: 'google-provider-subject',
            provider: 'GOOGLE',
            displayName: 'Google User',
          ),
        );

    expect(accepted, isFalse);
    expect(container.read(authUserProvider), isNull);
  });
}

class RecordingAuthRepository implements AuthRepository {
  OAuthProviderCredential? lastCredential;

  @override
  Future<AuthUser?> fetchCurrentUser() async => null;

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
        displayName: '$provider 사용자',
      ),
      tokens: OnmuAuthTokens(
        accessToken: 'onmu-access-jwt',
        refreshToken: 'onmu-refresh-token',
      ),
    );
  }
}
