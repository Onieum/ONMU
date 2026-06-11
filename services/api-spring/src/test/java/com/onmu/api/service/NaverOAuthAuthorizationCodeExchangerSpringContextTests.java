package com.onmu.api.service;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;
import org.springframework.context.annotation.AnnotationConfigApplicationContext;

class NaverOAuthAuthorizationCodeExchangerSpringContextTests {
  @Test
  void springCreatesCompositeAuthorizationCodeExchangerBean() {
    try (AnnotationConfigApplicationContext context = new AnnotationConfigApplicationContext()) {
      context.register(CompositeOAuthAuthorizationCodeExchanger.class);
      context.register(NaverOAuthAuthorizationCodeExchanger.class);
      context.register(KakaoOAuthAuthorizationCodeExchanger.class);
      context.refresh();

      assertThat(context.getBean(OAuthAuthorizationCodeExchanger.class))
        .isInstanceOf(CompositeOAuthAuthorizationCodeExchanger.class);
      assertThat(context.getBean(NaverOAuthAuthorizationCodeExchanger.class).supports("NAVER")).isTrue();
      assertThat(context.getBean(KakaoOAuthAuthorizationCodeExchanger.class).supports("KAKAO")).isTrue();
    }
  }
}
