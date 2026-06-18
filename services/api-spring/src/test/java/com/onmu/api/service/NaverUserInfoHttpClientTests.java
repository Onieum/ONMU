package com.onmu.api.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.header;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.method;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.requestTo;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withStatus;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess;

import org.junit.jupiter.api.Test;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.RestClient;
import org.springframework.web.server.ResponseStatusException;

class NaverUserInfoHttpClientTests {
  @Test
  void fetchesNaverProfileFromConfiguredUserInfoEndpoint() {
    RestClient.Builder builder = RestClient.builder();
    MockRestServiceServer server = MockRestServiceServer.bindTo(builder).build();
    RestClient restClient = builder.build();
    NaverUserInfoHttpClient client = new NaverUserInfoHttpClient(
      restClient,
      "https://openapi.naver.com/v1/nid/me"
    );

    server.expect(requestTo("https://openapi.naver.com/v1/nid/me"))
      .andExpect(method(HttpMethod.GET))
      .andExpect(header(HttpHeaders.AUTHORIZATION, "Bearer provider-token"))
      .andRespond(withSuccess("""
        {
          "resultcode": "00",
          "message": "success",
          "response": {
            "id": "naver-subject",
            "name": "네이버 사용자",
            "email": "naver-user@example.test",
            "profile_image": "https://example.test/naver.png"
          }
        }
        """, MediaType.APPLICATION_JSON));

    NaverUserInfo userInfo = client.fetch("provider-token");

    server.verify();
    assertThat(userInfo.id()).isEqualTo("naver-subject");
    assertThat(userInfo.providerProfileName()).isEqualTo("네이버 사용자");
    assertThat(userInfo.email()).isEqualTo("naver-user@example.test");
    assertThat(userInfo.profileImageUrl()).isEqualTo("https://example.test/naver.png");
  }

  @Test
  void unauthorizedNaverProfileResponseFailsClosed() {
    RestClient.Builder builder = RestClient.builder();
    MockRestServiceServer server = MockRestServiceServer.bindTo(builder).build();
    NaverUserInfoHttpClient client = new NaverUserInfoHttpClient(builder.build(), "https://example.test/naver/me");

    server.expect(requestTo("https://example.test/naver/me"))
      .andRespond(withStatus(HttpStatus.UNAUTHORIZED));

    assertThatThrownBy(() -> client.fetch("provider-token"))
      .isInstanceOfSatisfying(ResponseStatusException.class, exception -> {
        assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
        assertThat(exception.getReason()).isEqualTo("invalid_naver_provider_access_token");
      });
  }
}
