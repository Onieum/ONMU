package com.onmu.api.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.method;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.requestTo;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withStatus;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess;

import java.time.Instant;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.RestClient;
import org.springframework.web.server.ResponseStatusException;

class GoogleIdTokenInfoHttpClientTests {
  @Test
  void fetchesGoogleIdTokenInfo() {
    RestClient.Builder builder = RestClient.builder();
    MockRestServiceServer server = MockRestServiceServer.bindTo(builder).build();
    GoogleIdTokenInfoHttpClient client = new GoogleIdTokenInfoHttpClient(
      builder.build(),
      "https://example.test/google/tokeninfo"
    );

    server.expect(requestTo("https://example.test/google/tokeninfo?id_token=id-token"))
      .andExpect(method(HttpMethod.GET))
      .andRespond(withSuccess("""
        {
          "iss": "https://accounts.google.com",
          "aud": "google-client-id",
          "sub": "google-subject",
          "exp": "1781309400",
          "name": "Google User",
          "email": "google@example.test",
          "picture": "https://example.test/google.png"
        }
        """, MediaType.APPLICATION_JSON));

    GoogleIdTokenInfo tokenInfo = client.fetch("id-token");

    server.verify();
    assertThat(tokenInfo.issuer()).isEqualTo("https://accounts.google.com");
    assertThat(tokenInfo.audience()).isEqualTo("google-client-id");
    assertThat(tokenInfo.subject()).isEqualTo("google-subject");
    assertThat(tokenInfo.expiresAt()).isEqualTo(Instant.ofEpochSecond(1781309400L));
    assertThat(tokenInfo.providerProfileName()).isEqualTo("Google User");
  }

  @Test
  void invalidGoogleIdTokenFailsClosed() {
    RestClient.Builder builder = RestClient.builder();
    MockRestServiceServer server = MockRestServiceServer.bindTo(builder).build();
    GoogleIdTokenInfoHttpClient client = new GoogleIdTokenInfoHttpClient(
      builder.build(),
      "https://example.test/google/tokeninfo"
    );

    server.expect(requestTo("https://example.test/google/tokeninfo?id_token=id-token"))
      .andRespond(withStatus(HttpStatus.BAD_REQUEST));

    assertThatThrownBy(() -> client.fetch("id-token"))
      .isInstanceOfSatisfying(ResponseStatusException.class, exception -> {
        assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
        assertThat(exception.getReason()).isEqualTo("invalid_google_provider_id_token");
      });
  }
}
