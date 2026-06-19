package com.onmu.api.map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.time.Duration;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.ValueOperations;

class RedisMapCatalogCacheTests {
  private static final String CACHE_KEY = "map-catalog:v1:test-key";
  private static final TypeReference<Map<String, Object>> RESPONSE_TYPE = new TypeReference<>() {
  };

  private final ObjectMapper objectMapper = new ObjectMapper();

  @Test
  void putStoresMapCatalogResponseWithShortTtl() throws Exception {
    StringRedisTemplate redisTemplate = mock(StringRedisTemplate.class);
    @SuppressWarnings("unchecked")
    ValueOperations<String, String> valueOperations = mock(ValueOperations.class);
    @SuppressWarnings("unchecked")
    ObjectProvider<StringRedisTemplate> provider = mock(ObjectProvider.class);
    when(provider.getIfAvailable()).thenReturn(redisTemplate);
    when(redisTemplate.opsForValue()).thenReturn(valueOperations);
    RedisMapCatalogCache cache = new RedisMapCatalogCache(objectMapper, provider);
    Map<String, Object> response = Map.of(
      "mode", "clusters",
      "clusters", List.of(Map.of("id", "cluster:1", "count", 5)),
      "points", List.of()
    );

    cache.put(CACHE_KEY, response);

    ArgumentCaptor<String> json = ArgumentCaptor.forClass(String.class);
    verify(valueOperations).set(eq(CACHE_KEY), json.capture(), eq(Duration.ofMinutes(5)));
    Map<String, Object> stored = objectMapper.readValue(json.getValue(), RESPONSE_TYPE);
    assertThat(stored).containsEntry("mode", "clusters");
  }

  @Test
  void getRestoresMapCatalogResponseFromRedis() {
    StringRedisTemplate redisTemplate = mock(StringRedisTemplate.class);
    @SuppressWarnings("unchecked")
    ValueOperations<String, String> valueOperations = mock(ValueOperations.class);
    @SuppressWarnings("unchecked")
    ObjectProvider<StringRedisTemplate> provider = mock(ObjectProvider.class);
    when(provider.getIfAvailable()).thenReturn(redisTemplate);
    when(redisTemplate.opsForValue()).thenReturn(valueOperations);
    when(valueOperations.get(CACHE_KEY)).thenReturn("{\"mode\":\"points\",\"point_count\":1}");
    RedisMapCatalogCache cache = new RedisMapCatalogCache(objectMapper, provider);

    Optional<Map<String, Object>> cached = cache.get(CACHE_KEY);

    assertThat(cached).isPresent();
    assertThat(cached.orElseThrow()).containsEntry("mode", "points");
  }

  @Test
  void missingOrFailingRedisKeepsCacheOptional() {
    @SuppressWarnings("unchecked")
    ObjectProvider<StringRedisTemplate> provider = mock(ObjectProvider.class);
    when(provider.getIfAvailable()).thenReturn(null);
    RedisMapCatalogCache cache = new RedisMapCatalogCache(objectMapper, provider);

    assertThat(cache.get(CACHE_KEY)).isEmpty();
    cache.put(CACHE_KEY, Map.of("mode", "clusters"));
  }
}
