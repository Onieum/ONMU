package com.onmu.api.security;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.onmu.api.config.AuthProperties;
import com.onmu.api.domain.UserEntity;
import java.time.Duration;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

class AccessTokenIssuerVerifierTests {
  private final AuthProperties properties = new AuthProperties(
    "test-access-token-secret-with-enough-length",
    "onmu-api-test",
    "onmu-mobile-test",
    Duration.ofMinutes(30),
    Duration.ofDays(30),
    Duration.ofSeconds(0),
    List.of("http://localhost:*")
  );
  private final ObjectMapper objectMapper = new ObjectMapper();

  @Test
  void issuedTokenVerifiesBackToUserPublicId() {
    AccessTokenIssuer issuer = new AccessTokenIssuer(properties, objectMapper);
    AccessTokenVerifier verifier = new AccessTokenVerifier(properties, objectMapper);
    UserEntity user = new UserEntity("usr_test123", "ONMU User", null, null);

    String token = issuer.issue(user).token();

    assertThat(verifier.verify(token)).isEqualTo("usr_test123");
  }

  @Test
  void tamperedTokenIsRejected() {
    AccessTokenIssuer issuer = new AccessTokenIssuer(properties, objectMapper);
    AccessTokenVerifier verifier = new AccessTokenVerifier(properties, objectMapper);
    UserEntity user = new UserEntity("usr_test123", "ONMU User", null, null);
    String token = issuer.issue(user).token();

    assertThatThrownBy(() -> verifier.verify(token + "x"))
      .isInstanceOfSatisfying(ResponseStatusException.class, exception ->
        assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED));
  }
}
