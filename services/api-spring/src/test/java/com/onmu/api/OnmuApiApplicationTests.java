package com.onmu.api;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;

class OnmuApiApplicationTests {
  @Test
  void applicationEntrypointExists() {
    assertThat(OnmuApiApplication.class).isNotNull();
  }
}
