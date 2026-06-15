package com.onmu.api.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.runner.ApplicationContextRunner;
import org.springframework.jdbc.core.JdbcTemplate;

class UserCodeServiceSpringContextTests {
  private final ApplicationContextRunner contextRunner = new ApplicationContextRunner()
    .withBean(JdbcTemplate.class, () -> mock(JdbcTemplate.class))
    .withBean(UserCodeService.class);

  @Test
  void createsSpringBeanWithJdbcTemplateConstructor() {
    contextRunner.run(context -> assertThat(context).hasSingleBean(UserCodeService.class));
  }
}
