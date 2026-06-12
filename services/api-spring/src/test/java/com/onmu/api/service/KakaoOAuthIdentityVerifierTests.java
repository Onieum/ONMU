package com.onmu.api.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.onmu.api.web.dto.OAuthLoginRequest;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

class KakaoOAuthIdentityVerifierTests {
  @Test
  void verifiesKakaoProviderAccessTokenWithUserInfoClient() {
    StubKakaoUserInfoClient userInfoClient = new StubKakaoUserInfoClient(new KakaoUserInfo(
      "123456789",
      "카카오 사용자",
      "kakao-user@example.test",
      "https://example.test/kakao.png"
    ));
    KakaoOAuthIdentityVerifier verifier = new KakaoOAuthIdentityVerifier(
      userInfoClient,
      new StubAuthorizationCodeExchanger(Optional.empty())
    );

    VerifiedOAuthIdentity identity = verifier.verify(
      "KAKAO",
      new OAuthLoginRequest(null, " kakao-provider-token ", null, null, null, null)
    );

    assertThat(userInfoClient.requestedToken).isEqualTo("kakao-provider-token");
    assertThat(identity.provider()).isEqualTo("KAKAO");
    assertThat(identity.providerSubject()).isEqualTo("123456789");
    assertThat(identity.displayName()).isEqualTo("카카오 사용자");
    assertThat(identity.email()).isEqualTo("kakao-user@example.test");
    assertThat(identity.profileImageUrl()).isEqualTo("https://example.test/kakao.png");
  }

  @Test
  void missingKakaoProviderAccessTokenFailsClosed() {
    KakaoOAuthIdentityVerifier verifier = new KakaoOAuthIdentityVerifier(
      new StubKakaoUserInfoClient(new KakaoUserInfo("123", null, null, null)),
      new StubAuthorizationCodeExchanger(Optional.empty())
    );

    assertThatThrownBy(() -> verifier.verify("KAKAO", new OAuthLoginRequest(null, null, null, null, null, null)))
      .isInstanceOfSatisfying(ResponseStatusException.class, exception -> {
        assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
        assertThat(exception.getReason()).isEqualTo("missing_kakao_provider_access_token");
      });
  }

  @Test
  void invalidKakaoProviderAccessTokenFailsClosed() {
    StubKakaoUserInfoClient userInfoClient = new StubKakaoUserInfoClient(null);
    userInfoClient.failure = new ResponseStatusException(HttpStatus.UNAUTHORIZED, "invalid_kakao_provider_access_token");
    KakaoOAuthIdentityVerifier verifier = new KakaoOAuthIdentityVerifier(
      userInfoClient,
      new StubAuthorizationCodeExchanger(Optional.empty())
    );

    assertThatThrownBy(() -> verifier.verify(
      "KAKAO",
      new OAuthLoginRequest(null, "bad-token", null, null, null, null)
    ))
      .isInstanceOfSatisfying(ResponseStatusException.class, exception -> {
        assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
        assertThat(exception.getReason()).isEqualTo("invalid_kakao_provider_access_token");
      });
  }

  @Test
  void authorizationCodePathIsExplicitExchangeSeam() {
    StubKakaoUserInfoClient userInfoClient = new StubKakaoUserInfoClient(new KakaoUserInfo("123", null, null, null));
    StubAuthorizationCodeExchanger exchanger = new StubAuthorizationCodeExchanger(Optional.of("exchanged-token"));
    KakaoOAuthIdentityVerifier verifier = new KakaoOAuthIdentityVerifier(userInfoClient, exchanger);

    verifier.verify("KAKAO", new OAuthLoginRequest("auth-code", null, null, null, null, null, "state-123"));

    assertThat(exchanger.requestedProvider).isEqualTo("KAKAO");
    assertThat(exchanger.requestedAuthorizationCode).isEqualTo("auth-code");
    assertThat(exchanger.requestedState).isEqualTo("state-123");
    assertThat(userInfoClient.requestedToken).isEqualTo("exchanged-token");
  }

  private static class StubKakaoUserInfoClient implements KakaoUserInfoClient {
    private final KakaoUserInfo response;
    private String requestedToken;
    private ResponseStatusException failure;

    private StubKakaoUserInfoClient(KakaoUserInfo response) {
      this.response = response;
    }

    @Override
    public KakaoUserInfo fetch(String providerAccessToken) {
      requestedToken = providerAccessToken;
      if (failure != null) {
        throw failure;
      }
      return response;
    }
  }

  private static class StubAuthorizationCodeExchanger implements OAuthAuthorizationCodeExchanger {
    private final Optional<String> response;
    private String requestedProvider;
    private String requestedAuthorizationCode;
    private String requestedState;

    private StubAuthorizationCodeExchanger(Optional<String> response) {
      this.response = response;
    }

    @Override
    public Optional<String> exchange(String provider, String authorizationCode) {
      return exchange(provider, authorizationCode, null);
    }

    @Override
    public Optional<String> exchange(String provider, String authorizationCode, String state) {
      requestedProvider = provider;
      requestedAuthorizationCode = authorizationCode;
      requestedState = state;
      return response;
    }
  }
}
