package com.onmu.api.place;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.time.Duration;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;

@Component
public class RedisPlaceSearchCache implements PlaceSearchCache {
  private static final Duration TTL = Duration.ofMinutes(10);
  private static final TypeReference<List<Map<String, Object>>> RESULT_TYPE = new TypeReference<>() {
  };

  private final ObjectMapper objectMapper;
  private final ObjectProvider<StringRedisTemplate> redisTemplateProvider;

  public RedisPlaceSearchCache(ObjectMapper objectMapper, ObjectProvider<StringRedisTemplate> redisTemplateProvider) {
    this.objectMapper = objectMapper;
    this.redisTemplateProvider = redisTemplateProvider;
  }

  @Override
  public Optional<List<Map<String, Object>>> get(String key) {
    StringRedisTemplate redisTemplate = redisTemplateProvider.getIfAvailable();
    if (redisTemplate == null) {
      return Optional.empty();
    }
    try {
      String value = redisTemplate.opsForValue().get(key);
      if (value == null || value.isBlank()) {
        return Optional.empty();
      }
      return Optional.of(objectMapper.readValue(value, RESULT_TYPE));
    } catch (RuntimeException | JsonProcessingException ignored) {
      return Optional.empty();
    }
  }

  @Override
  public void put(String key, List<Map<String, Object>> results) {
    StringRedisTemplate redisTemplate = redisTemplateProvider.getIfAvailable();
    if (redisTemplate == null) {
      return;
    }
    try {
      redisTemplate.opsForValue().set(key, objectMapper.writeValueAsString(results), TTL);
    } catch (RuntimeException | JsonProcessingException ignored) {
      // Redis cache 실패는 검색 API 응답을 막지 않는다.
    }
  }
}
