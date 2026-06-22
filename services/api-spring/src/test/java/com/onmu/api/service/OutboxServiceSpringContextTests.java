package com.onmu.api.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.onmu.api.domain.OutboxEventRepository;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.runner.ApplicationContextRunner;

class OutboxServiceSpringContextTests {
  private final ApplicationContextRunner contextRunner = new ApplicationContextRunner()
    .withBean(OutboxEventRepository.class, () -> mock(OutboxEventRepository.class))
    .withBean(NotificationDeliveryService.class, () -> mock(NotificationDeliveryService.class))
    .withBean(OotdAvatarGenerationCompletionService.class, () -> mock(OotdAvatarGenerationCompletionService.class))
    .withBean(ObjectMapper.class, ObjectMapper::new)
    .withBean(OutboxService.class);

  @Test
  void createsSpringBeanWithRuntimeConstructor() {
    contextRunner.run(context -> assertThat(context).hasSingleBean(OutboxService.class));
  }
}
