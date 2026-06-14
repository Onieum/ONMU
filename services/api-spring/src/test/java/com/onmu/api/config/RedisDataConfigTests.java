package com.onmu.api.config;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;
import org.springframework.boot.autoconfigure.AutoConfigurations;
import org.springframework.boot.autoconfigure.data.redis.RedisAutoConfiguration;
import org.springframework.boot.autoconfigure.data.redis.RedisReactiveAutoConfiguration;
import org.springframework.boot.test.context.runner.ApplicationContextRunner;
import org.springframework.data.redis.connection.lettuce.LettuceConnectionFactory;

class RedisDataConfigTests {
  private static final String REDIS_URL_MAPPING =
    "spring.data.redis.url=${SPRING_DATA_REDIS_URL:${REDIS_URL:redis://${REDIS_HOST:localhost}:${REDIS_PORT:6379}/0}}";

  private final ApplicationContextRunner contextRunner = new ApplicationContextRunner()
    .withConfiguration(AutoConfigurations.of(RedisAutoConfiguration.class, RedisReactiveAutoConfiguration.class))
    .withPropertyValues(REDIS_URL_MAPPING);

  @Test
  void redisUrlConfiguresSpringDataRedisDatabaseIndexWithoutConnecting() {
    contextRunner
      .withPropertyValues("REDIS_URL=redis://localhost:6379/1")
      .run(context -> {
        LettuceConnectionFactory connectionFactory = context.getBean(LettuceConnectionFactory.class);

        assertThat(connectionFactory.getDatabase()).isEqualTo(1);
      });
  }

  @Test
  void springDataRedisUrlOverridesRedisUrl() {
    contextRunner
      .withPropertyValues(
        "REDIS_URL=redis://localhost:6379/1",
        "SPRING_DATA_REDIS_URL=redis://localhost:6379/2"
      )
      .run(context -> {
        LettuceConnectionFactory connectionFactory = context.getBean(LettuceConnectionFactory.class);

        assertThat(connectionFactory.getDatabase()).isEqualTo(2);
      });
  }
}
