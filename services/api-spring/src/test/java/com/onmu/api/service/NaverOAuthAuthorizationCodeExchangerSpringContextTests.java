package com.onmu.api.service;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;
import org.springframework.context.annotation.AnnotationConfigApplicationContext;

class NaverOAuthAuthorizationCodeExchangerSpringContextTests {
  @Test
  void springCreatesNaverAuthorizationCodeExchangerBean() {
    try (AnnotationConfigApplicationContext context = new AnnotationConfigApplicationContext()) {
      context.register(NaverOAuthAuthorizationCodeExchanger.class);
      context.refresh();

      assertThat(context.getBean(OAuthAuthorizationCodeExchanger.class))
        .isInstanceOf(NaverOAuthAuthorizationCodeExchanger.class);
    }
  }
}
