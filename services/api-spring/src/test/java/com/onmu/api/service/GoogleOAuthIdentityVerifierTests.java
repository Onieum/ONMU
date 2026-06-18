package com.onmu.api.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.onmu.api.web.dto.OAuthLoginRequest;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

class GoogleOAuthIdentityVerifierTests {
  private static final Clock FIXED_CLOCK = Clock.fixed(Instant.parse("2026-06-13T00:00:00Z"), ZoneOffset.UTC);

  @Test
  void verifiesGoogleIdTokenClaims() {
    GoogleOAuthIdentityVerifier verifier = newVerifier(new GoogleIdTokenInfo(
      "https://accounts.google.com",
      "google-client-id",
      "google-subject",
      Instant.parse("2026-06-13T00:10:00Z"),
      "Google User",
      "google@example.test",
      "https://example.test/google.png"
    ));

    VerifiedOAuthIdentity identity = verifier.verify(
      "GOOGLE",
      new OAuthLoginRequest(null, null, "google-id-token", null, null, null, null, null)
    );

    assertThat(identity.provider()).isEqualTo("GOOGLE");
    assertThat(identity.providerSubject()).isEqualTo("google-subject");
    assertThat(identity.providerProfileName()).isEqualTo("Google User");
    assertThat(identity.email()).isEqualTo("google@example.test");
    assertThat(identity.profileImageUrl()).isEqualTo("https://example.test/google.png");
  }

  @Test
  void missingGoogleIdTokenFailsClosed() {
    GoogleOAuthIdentityVerifier verifier = newVerifier(validTokenInfo());

    assertThatThrownBy(() -> verifier.verify("GOOGLE", new OAuthLoginRequest(null, null, null, null, null, null)))
      .isInstanceOfSatisfying(ResponseStatusException.class, exception -> {
        assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
        assertThat(exception.getReason()).isEqualTo("missing_google_provider_id_token");
      });
  }

  @Test
  void invalidIssuerFailsClosed() {
    assertRejected(
      new GoogleIdTokenInfo("https://evil.example", "google-client-id", "google-subject", future(), null, null, null),
      "invalid_google_id_token_issuer"
    );
  }

  @Test
  void invalidAudienceFailsClosed() {
    assertRejected(
      new GoogleIdTokenInfo("https://accounts.google.com", "other-client-id", "google-subject", future(), null, null, null),
      "invalid_google_id_token_audience"
    );
  }

  @Test
  void missingSubjectFailsClosed() {
    assertRejected(
      new GoogleIdTokenInfo("https://accounts.google.com", "google-client-id", null, future(), null, null, null),
      "invalid_google_id_token_subject"
    );
  }

  @Test
  void expiredTokenFailsClosed() {
    assertRejected(
      new GoogleIdTokenInfo("https://accounts.google.com", "google-client-id", "google-subject", Instant.parse("2026-06-12T23:59:59Z"), null, null, null),
      "google_id_token_expired"
    );
  }

  @Test
  void missingServerClientIdFailsClosed() {
    GoogleOAuthIdentityVerifier verifier = new GoogleOAuthIdentityVerifier(
      token -> validTokenInfo(),
      "",
      FIXED_CLOCK
    );

    assertThatThrownBy(() -> verifier.verify(
      "GOOGLE",
      new OAuthLoginRequest(null, null, "google-id-token", null, null, null, null, null)
    ))
      .isInstanceOfSatisfying(ResponseStatusException.class, exception -> {
        assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
        assertThat(exception.getReason()).isEqualTo("google_oauth_client_id_unavailable");
      });
  }

  private void assertRejected(GoogleIdTokenInfo tokenInfo, String reason) {
    GoogleOAuthIdentityVerifier verifier = newVerifier(tokenInfo);

    assertThatThrownBy(() -> verifier.verify(
      "GOOGLE",
      new OAuthLoginRequest(null, null, "google-id-token", null, null, null, null, null)
    ))
      .isInstanceOfSatisfying(ResponseStatusException.class, exception -> {
        assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
        assertThat(exception.getReason()).isEqualTo(reason);
      });
  }

  private GoogleOAuthIdentityVerifier newVerifier(GoogleIdTokenInfo tokenInfo) {
    return new GoogleOAuthIdentityVerifier(
      token -> tokenInfo,
      "google-client-id",
      FIXED_CLOCK
    );
  }

  private GoogleIdTokenInfo validTokenInfo() {
    return new GoogleIdTokenInfo(
      "https://accounts.google.com",
      "google-client-id",
      "google-subject",
      future(),
      "Google User",
      "google@example.test",
      null
    );
  }

  private Instant future() {
    return Instant.parse("2026-06-13T00:10:00Z");
  }
}
