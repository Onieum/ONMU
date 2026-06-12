package com.onmu.api.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.hamcrest.Matchers.allOf;
import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.not;
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

class KakaoOAuthAuthorizationCodeExchangerTests {
  @Test
  void exchangesKakaoAuthorizationCodeWithoutFlutterSecret() {
    RestClient.Builder builder = RestClient.builder();
    MockRestServiceServer server = MockRestServiceServer.bindTo(builder).build();
    KakaoOAuthAuthorizationCodeExchanger exchanger = new KakaoOAuthAuthorizationCodeExchanger(
      builder.build(),
      environmentWithKakaoConfig()
    );

    server.expect(requestTo("https://example.test/kakao/token"))
      .andExpect(method(HttpMethod.POST))
      .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_FORM_URLENCODED))
      .andExpect(content().string(allOf(
        containsString("grant_type=authorization_code"),
        containsString("client_id=kakao-rest-client"),
        containsString("redirect_uri=https%3A%2F%2Fdev-api.onmu.cloud%2Fapi%2Fv1%2Fauth%2Foauth%2Fkakao%2Fcallback"),
        containsString("code=auth-code"),
        not(containsString("client_secret="))
      )))
      .andRespond(withSuccess("{\"access_token\":\"stub-token\"}", MediaType.APPLICATION_JSON));

    Optional<String> result = exchanger.exchange("auth-code", "state-123");

    server.verify();
    assertThat(result).contains("stub-token");
  }

  @Test
  void usesServerSideClientSecretWhenConfigured() {
    RestClient.Builder builder = RestClient.builder();
    MockRestServiceServer server = MockRestServiceServer.bindTo(builder).build();
    MockEnvironment environment = environmentWithKakaoConfig()
      .withProperty("KAKAO_CLIENT_SECRET", "stub");
    KakaoOAuthAuthorizationCodeExchanger exchanger = new KakaoOAuthAuthorizationCodeExchanger(
      builder.build(),
      environment
    );

    server.expect(requestTo("https://example.test/kakao/token"))
      .andExpect(content().string(containsString("client_secret=stub")))
      .andRespond(withSuccess("{\"access_token\":\"stub-token\"}", MediaType.APPLICATION_JSON));

    Optional<String> result = exchanger.exchange("auth-code", "state-123");

    server.verify();
    assertThat(result).contains("stub-token");
  }

  @Test
  void missingKakaoClientIdKeepsExchangeUnavailable() {
    KakaoOAuthAuthorizationCodeExchanger exchanger = new KakaoOAuthAuthorizationCodeExchanger(
      RestClient.builder().build(),
      new MockEnvironment()
    );

    assertThat(exchanger.exchange("auth-code", "state-123")).isEmpty();
  }

  @Test
  void tokenEndpointFailureFailsClosed() {
    RestClient.Builder builder = RestClient.builder();
    MockRestServiceServer server = MockRestServiceServer.bindTo(builder).build();
    KakaoOAuthAuthorizationCodeExchanger exchanger = new KakaoOAuthAuthorizationCodeExchanger(
      builder.build(),
      environmentWithKakaoConfig()
    );

    server.expect(requestTo("https://example.test/kakao/token"))
      .andRespond(withStatus(HttpStatus.UNAUTHORIZED));

    assertThatThrownBy(() -> exchanger.exchange("auth-code", "state-123"))
      .isInstanceOfSatisfying(ResponseStatusException.class, exception -> {
        assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
        assertThat(exception.getReason()).isEqualTo("kakao_authorization_code_exchange_failed");
      });
  }

  private MockEnvironment environmentWithKakaoConfig() {
    return new MockEnvironment()
      .withProperty("KAKAO_REST_API_KEY", "kakao-rest-client")
      .withProperty("KAKAO_OAUTH_TOKEN_URL", "https://example.test/kakao/token")
      .withProperty("KAKAO_OAUTH_REDIRECT_URI", "https://dev-api.onmu.cloud/api/v1/auth/oauth/kakao/callback");
  }
}
