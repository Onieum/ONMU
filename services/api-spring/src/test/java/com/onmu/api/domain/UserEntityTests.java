package com.onmu.api.domain;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;

class UserEntityTests {
  @Test
  void lifecycleSetsUpdatedAtBeforePersistAndUpdate() {
    UserEntity user = new UserEntity("usr-test", "테스트", null, null);

    user.touchUpdatedAt();
    assertThat(user.getUpdatedAt()).isNotNull();

    var persistedUpdatedAt = user.getUpdatedAt();
    user.updateProfile("테스트 수정", null, null, null, null);
    user.touchUpdatedAt();

    assertThat(user.getUpdatedAt()).isNotNull();
    assertThat(user.getUpdatedAt()).isAfterOrEqualTo(persistedUpdatedAt);
  }
}
