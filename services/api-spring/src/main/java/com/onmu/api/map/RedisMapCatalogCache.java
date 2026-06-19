package com.onmu.api.map;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.time.Duration;
import java.util.Map;
import java.util.Optional;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;

@Component
public class RedisMapCatalogCache implements MapCatalogCache {
  private static final Duration TTL = Duration.ofMinutes(5);
  private static final TypeReference<Map<String, Object>> RESPONSE_TYPE = new TypeReference<>() {
  };

  private final ObjectMapper objectMapper;
  private final ObjectProvider<StringRedisTemplate> redisTemplateProvider;

  public RedisMapCatalogCache(ObjectMapper objectMapper, ObjectProvider<StringRedisTemplate> redisTemplateProvider) {
    this.objectMapper = objectMapper;
    this.redisTemplateProvider = redisTemplateProvider;
  }

  @Override
  public Optional<Map<String, Object>> get(String key) {
    StringRedisTemplate redisTemplate = redisTemplateProvider.getIfAvailable();
    if (redisTemplate == null) {
      return Optional.empty();
    }
    try {
      String value = redisTemplate.opsForValue().get(key);
      if (value == null || value.isBlank()) {
        return Optional.empty();
      }
      return Optional.of(objectMapper.readValue(value, RESPONSE_TYPE));
    } catch (RuntimeException | JsonProcessingException ignored) {
      return Optional.empty();
    }
  }

  @Override
  public void put(String key, Map<String, Object> response) {
    StringRedisTemplate redisTemplate = redisTemplateProvider.getIfAvailable();
    if (redisTemplate == null) {
      return;
    }
    try {
      redisTemplate.opsForValue().set(key, objectMapper.writeValueAsString(response), TTL);
    } catch (RuntimeException | JsonProcessingException ignored) {
      // Redis cache 실패는 지도 catalog API 응답을 막지 않는다.
    }
  }
}
