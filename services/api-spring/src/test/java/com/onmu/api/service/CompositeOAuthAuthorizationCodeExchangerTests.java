package com.onmu.api.service;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.Test;

class CompositeOAuthAuthorizationCodeExchangerTests {
  @Test
  void dispatchesByProviderWithoutCallingOtherExchangers() {
    StubProviderExchanger kakao = new StubProviderExchanger("KAKAO", "kakao-token");
    StubProviderExchanger naver = new StubProviderExchanger("NAVER", "naver-token");
    CompositeOAuthAuthorizationCodeExchanger exchanger = new CompositeOAuthAuthorizationCodeExchanger(
      List.of(kakao, naver)
    );

    Optional<String> kakaoResult = exchanger.exchange("KAKAO", "kakao-code", "kakao-state");
    Optional<String> naverResult = exchanger.exchange("NAVER", "naver-code", "naver-state");

    assertThat(kakaoResult).contains("kakao-token");
    assertThat(naverResult).contains("naver-token");
    assertThat(kakao.requestedAuthorizationCode).isEqualTo("kakao-code");
    assertThat(kakao.requestedState).isEqualTo("kakao-state");
    assertThat(naver.requestedAuthorizationCode).isEqualTo("naver-code");
    assertThat(naver.requestedState).isEqualTo("naver-state");
  }

  @Test
  void unsupportedProviderReturnsEmpty() {
    CompositeOAuthAuthorizationCodeExchanger exchanger = new CompositeOAuthAuthorizationCodeExchanger(
      List.of(new StubProviderExchanger("KAKAO", "kakao-token"))
    );

    assertThat(exchanger.exchange("GOOGLE", "auth-code", "state-123")).isEmpty();
  }

  private static class StubProviderExchanger implements OAuthProviderAuthorizationCodeExchanger {
    private final String provider;
    private final String response;
    private String requestedAuthorizationCode;
    private String requestedState;

    private StubProviderExchanger(String provider, String response) {
      this.provider = provider;
      this.response = response;
    }

    @Override
    public boolean supports(String provider) {
      return this.provider.equalsIgnoreCase(provider);
    }

    @Override
    public Optional<String> exchange(String authorizationCode, String state) {
      this.requestedAuthorizationCode = authorizationCode;
      this.requestedState = state;
      return Optional.of(response);
    }
  }
}
