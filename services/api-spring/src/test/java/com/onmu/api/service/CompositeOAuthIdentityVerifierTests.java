package com.onmu.api.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.onmu.api.web.dto.OAuthLoginRequest;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.mock.env.MockEnvironment;
import org.springframework.web.server.ResponseStatusException;

class CompositeOAuthIdentityVerifierTests {
  @Test
  void routesProviderToMatchingVerifier() {
    CompositeOAuthIdentityVerifier verifier = new CompositeOAuthIdentityVerifier(List.of(
      new FixedProviderVerifier("KAKAO", new VerifiedOAuthIdentity("KAKAO", "kakao-subject", null, null, null))
    ));

    VerifiedOAuthIdentity identity = verifier.verify(
      "kakao",
      new OAuthLoginRequest(null, "provider-token", null, null, null, null)
    );

    assertThat(identity.provider()).isEqualTo("KAKAO");
    assertThat(identity.providerSubject()).isEqualTo("kakao-subject");
  }

  @Test
  void unsupportedProviderRemainsBadRequest() {
    CompositeOAuthIdentityVerifier verifier = new CompositeOAuthIdentityVerifier(List.of());

    assertThatThrownBy(() -> verifier.verify(
      "google",
      new OAuthLoginRequest(null, "provider-token", null, null, null, null)
    ))
      .isInstanceOfSatisfying(ResponseStatusException.class, exception -> {
        assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(exception.getReason()).isEqualTo("unsupported_oauth_provider");
      });
  }

  @Test
  void naverDevVerifierPreservesDevSubjectScaffold() {
    MockEnvironment environment = new MockEnvironment()
      .withProperty("onmu.auth.dev-oauth-enabled", "true");
    DevOAuthIdentityVerifier verifier = new DevOAuthIdentityVerifier(environment);

    VerifiedOAuthIdentity identity = verifier.verify(
      "NAVER",
      new OAuthLoginRequest(null, null, "naver-dev-subject", "네이버 사용자", "naver@example.test", null)
    );

    assertThat(verifier.supports("NAVER")).isTrue();
    assertThat(verifier.supports("KAKAO")).isFalse();
    assertThat(identity.provider()).isEqualTo("NAVER");
    assertThat(identity.providerSubject()).isEqualTo("naver-dev-subject");
    assertThat(identity.displayName()).isEqualTo("네이버 사용자");
  }

  @Test
  void naverDevSubjectIsNotTrustedWhenDevVerifierIsDisabled() {
    DevOAuthIdentityVerifier verifier = new DevOAuthIdentityVerifier(new MockEnvironment());

    assertThatThrownBy(() -> verifier.verify(
      "NAVER",
      new OAuthLoginRequest(null, null, "naver-dev-subject", null, null, null)
    ))
      .isInstanceOfSatisfying(ResponseStatusException.class, exception -> {
        assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
        assertThat(exception.getReason()).isEqualTo("oauth_provider_verification_unavailable");
      });
  }

  private record FixedProviderVerifier(
    String provider,
    VerifiedOAuthIdentity identity
  ) implements OAuthProviderVerifier {
    @Override
    public boolean supports(String provider) {
      return this.provider.equals(provider);
    }

    @Override
    public VerifiedOAuthIdentity verify(String normalizedProvider, OAuthLoginRequest request) {
      return identity;
    }
  }
}
