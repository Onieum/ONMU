package com.onmu.api.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.hamcrest.Matchers.allOf;
import static org.hamcrest.Matchers.containsString;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.content;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.method;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.requestTo;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withStatus;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess;

import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.mock.env.MockEnvironment;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.RestClient;
import org.springframework.web.server.ResponseStatusException;

class NaverOAuthAuthorizationCodeExchangerTests {
  @Test
  void exchangesNaverAuthorizationCodeWithServerSideSecret() {
    RestClient.Builder builder = RestClient.builder();
    MockRestServiceServer server = MockRestServiceServer.bindTo(builder).build();
    NaverOAuthAuthorizationCodeExchanger exchanger = new NaverOAuthAuthorizationCodeExchanger(
      builder.build(),
      environmentWithNaverConfig()
    );

    server.expect(requestTo("https://example.test/naver/token"))
      .andExpect(method(HttpMethod.POST))
      .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_FORM_URLENCODED))
      .andExpect(content().string(allOf(
        containsString("grant_type=authorization_code"),
        containsString("client_id=test-client-id"),
        containsString("client_secret=stub"),
        containsString("code=auth-code"),
        containsString("state=state-123")
      )))
      .andRespond(withSuccess("{\"access_token\":\"stub-token\"}", MediaType.APPLICATION_JSON));

    Optional<String> result = exchanger.exchange("auth-code", "state-123");

    server.verify();
    assertThat(result).contains("stub-token");
  }

  @Test
  void missingNaverConfigKeepsExchangeUnavailable() {
    NaverOAuthAuthorizationCodeExchanger exchanger = new NaverOAuthAuthorizationCodeExchanger(
      RestClient.builder().build(),
      new MockEnvironment()
    );

    assertThat(exchanger.exchange("auth-code", "state-123")).isEmpty();
  }

  @Test
  void tokenEndpointFailureFailsClosed() {
    RestClient.Builder builder = RestClient.builder();
    MockRestServiceServer server = MockRestServiceServer.bindTo(builder).build();
    NaverOAuthAuthorizationCodeExchanger exchanger = new NaverOAuthAuthorizationCodeExchanger(
      builder.build(),
      environmentWithNaverConfig()
    );

    server.expect(requestTo("https://example.test/naver/token"))
      .andRespond(withStatus(HttpStatus.UNAUTHORIZED));

    assertThatThrownBy(() -> exchanger.exchange("auth-code", "state-123"))
      .isInstanceOfSatisfying(ResponseStatusException.class, exception -> {
        assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
        assertThat(exception.getReason()).isEqualTo("naver_authorization_code_exchange_failed");
      });
  }

  private MockEnvironment environmentWithNaverConfig() {
    return new MockEnvironment()
      .withProperty("NAVER_OAUTH_CLIENT_ID", "test-client-id")
      .withProperty("NAVER_OAUTH_CLIENT_SECRET", "stub")
      .withProperty("NAVER_OAUTH_TOKEN_URL", "https://example.test/naver/token");
  }
}
