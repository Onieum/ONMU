package com.onmu.api.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.onmu.api.web.dto.OAuthLoginRequest;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.mock.env.MockEnvironment;
import org.springframework.web.server.ResponseStatusException;

class NaverOAuthIdentityVerifierTests {
  @Test
  void verifiesNaverProviderAccessTokenWithUserInfoClient() {
    StubNaverUserInfoClient userInfoClient = new StubNaverUserInfoClient(new NaverUserInfo(
      "naver-subject",
      "네이버 사용자",
      "naver-user@example.test",
      "https://example.test/naver.png"
    ));
    NaverOAuthIdentityVerifier verifier = newVerifier(
      userInfoClient,
      new StubAuthorizationCodeExchanger(Optional.empty()),
      devVerifier(false)
    );

    VerifiedOAuthIdentity identity = verifier.verify(
      "NAVER",
      new OAuthLoginRequest(null, " naver-provider-token ", "dev-subject", null, null, null)
    );

    assertThat(userInfoClient.requestedToken).isEqualTo("naver-provider-token");
    assertThat(identity.provider()).isEqualTo("NAVER");
    assertThat(identity.providerSubject()).isEqualTo("naver-subject");
    assertThat(identity.displayName()).isEqualTo("네이버 사용자");
    assertThat(identity.email()).isEqualTo("naver-user@example.test");
    assertThat(identity.profileImageUrl()).isEqualTo("https://example.test/naver.png");
  }

  @Test
  void invalidNaverProviderAccessTokenFailsClosed() {
    StubNaverUserInfoClient userInfoClient = new StubNaverUserInfoClient(null);
    userInfoClient.failure = new ResponseStatusException(HttpStatus.UNAUTHORIZED, "invalid_naver_provider_access_token");
    NaverOAuthIdentityVerifier verifier = newVerifier(
      userInfoClient,
      new StubAuthorizationCodeExchanger(Optional.empty()),
      devVerifier(true)
    );

    assertThatThrownBy(() -> verifier.verify(
      "NAVER",
      new OAuthLoginRequest(null, "bad-token", "dev-subject", null, null, null)
    ))
      .isInstanceOfSatisfying(ResponseStatusException.class, exception -> {
        assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
        assertThat(exception.getReason()).isEqualTo("invalid_naver_provider_access_token");
      });
  }

  @Test
  void naverUserInfoWithoutProviderSubjectFailsClosed() {
    NaverOAuthIdentityVerifier verifier = newVerifier(
      new StubNaverUserInfoClient(new NaverUserInfo(null, "네이버 사용자", null, null)),
      new StubAuthorizationCodeExchanger(Optional.empty()),
      devVerifier(true)
    );

    assertThatThrownBy(() -> verifier.verify(
      "NAVER",
      new OAuthLoginRequest(null, "naver-provider-token", null, null, null, null)
    ))
      .isInstanceOfSatisfying(ResponseStatusException.class, exception -> {
        assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
        assertThat(exception.getReason()).isEqualTo("invalid_naver_user_info");
      });
  }

  @Test
  void authorizationCodePathUsesProviderNeutralExchangeSeam() {
    StubNaverUserInfoClient userInfoClient = new StubNaverUserInfoClient(new NaverUserInfo("naver-subject", null, null, null));
    StubAuthorizationCodeExchanger exchanger = new StubAuthorizationCodeExchanger(Optional.of("exchanged-token"));
    NaverOAuthIdentityVerifier verifier = newVerifier(userInfoClient, exchanger, devVerifier(false));

    verifier.verify("NAVER", new OAuthLoginRequest("auth-code", null, "dev-subject", null, null, null));

    assertThat(exchanger.requestedProvider).isEqualTo("NAVER");
    assertThat(exchanger.requestedAuthorizationCode).isEqualTo("auth-code");
    assertThat(userInfoClient.requestedToken).isEqualTo("exchanged-token");
  }

  @Test
  void missingAuthorizationCodeExchangeFailsWithoutUsingDevSubject() {
    NaverOAuthIdentityVerifier verifier = newVerifier(
      new StubNaverUserInfoClient(new NaverUserInfo("naver-subject", null, null, null)),
      new StubAuthorizationCodeExchanger(Optional.empty()),
      devVerifier(true)
    );

    assertThatThrownBy(() -> verifier.verify(
      "NAVER",
      new OAuthLoginRequest("auth-code", null, "dev-subject", null, null, null)
    ))
      .isInstanceOfSatisfying(ResponseStatusException.class, exception -> {
        assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
        assertThat(exception.getReason()).isEqualTo("naver_authorization_code_exchange_unavailable");
      });
  }

  @Test
  void devSubjectFallbackOnlyRunsWhenNoRealProviderCredentialIsPresent() {
    NaverOAuthIdentityVerifier verifier = newVerifier(
      new StubNaverUserInfoClient(new NaverUserInfo("naver-subject", null, null, null)),
      new StubAuthorizationCodeExchanger(Optional.empty()),
      devVerifier(true)
    );

    VerifiedOAuthIdentity identity = verifier.verify(
      "NAVER",
      new OAuthLoginRequest(null, null, "naver-dev-subject", "네이버 dev 사용자", "naver-dev@example.test", null)
    );

    assertThat(identity.provider()).isEqualTo("NAVER");
    assertThat(identity.providerSubject()).isEqualTo("naver-dev-subject");
    assertThat(identity.displayName()).isEqualTo("네이버 dev 사용자");
  }

  private NaverOAuthIdentityVerifier newVerifier(
    NaverUserInfoClient userInfoClient,
    OAuthAuthorizationCodeExchanger exchanger,
    DevOAuthIdentityVerifier devVerifier
  ) {
    return new NaverOAuthIdentityVerifier(userInfoClient, exchanger, devVerifier);
  }

  private DevOAuthIdentityVerifier devVerifier(boolean enabled) {
    MockEnvironment environment = new MockEnvironment();
    if (enabled) {
      environment.withProperty("onmu.auth.dev-oauth-enabled", "true");
    }
    return new DevOAuthIdentityVerifier(environment);
  }

  private static class StubNaverUserInfoClient implements NaverUserInfoClient {
    private final NaverUserInfo response;
    private String requestedToken;
    private ResponseStatusException failure;

    private StubNaverUserInfoClient(NaverUserInfo response) {
      this.response = response;
    }

    @Override
    public NaverUserInfo fetch(String providerAccessToken) {
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

    private StubAuthorizationCodeExchanger(Optional<String> response) {
      this.response = response;
    }

    @Override
    public Optional<String> exchange(String provider, String authorizationCode) {
      requestedProvider = provider;
      requestedAuthorizationCode = authorizationCode;
      return response;
    }
  }
}
