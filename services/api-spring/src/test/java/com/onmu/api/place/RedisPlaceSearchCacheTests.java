package com.onmu.api.place;

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
import java.util.stream.IntStream;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.ValueOperations;

class RedisPlaceSearchCacheTests {
  private static final String CACHE_KEY = "place-search:v3:test-key";
  private static final TypeReference<List<Map<String, Object>>> RESULT_TYPE = new TypeReference<>() {
  };

  private final ObjectMapper objectMapper = new ObjectMapper();

  @Test
  void putStoresPlaceSearchResultsInRedisWithTtl() throws Exception {
    StringRedisTemplate redisTemplate = mock(StringRedisTemplate.class);
    @SuppressWarnings("unchecked")
    ValueOperations<String, String> valueOperations = mock(ValueOperations.class);
    @SuppressWarnings("unchecked")
    ObjectProvider<StringRedisTemplate> provider = mock(ObjectProvider.class);
    when(provider.getIfAvailable()).thenReturn(redisTemplate);
    when(redisTemplate.opsForValue()).thenReturn(valueOperations);
    RedisPlaceSearchCache cache = new RedisPlaceSearchCache(objectMapper, provider);
    List<Map<String, Object>> results = IntStream.rangeClosed(1, 20)
      .mapToObj(index -> Map.<String, Object>of(
        "id", "place-" + index,
        "name", "후보 " + index,
        "provider", index <= 5 ? "naver" : "kakao",
        "lat", 37.50 + index / 100.0,
        "lng", 127.00 + index / 100.0
      ))
      .toList();

    cache.put(CACHE_KEY, results);

    ArgumentCaptor<String> json = ArgumentCaptor.forClass(String.class);
    verify(valueOperations).set(eq(CACHE_KEY), json.capture(), eq(Duration.ofMinutes(10)));
    List<Map<String, Object>> storedResults = objectMapper.readValue(json.getValue(), RESULT_TYPE);
    assertThat(storedResults).hasSize(20);
    assertThat(storedResults).isEqualTo(results);
  }

  @Test
  void getRestoresPlaceSearchResultsFromRedis() {
    StringRedisTemplate redisTemplate = mock(StringRedisTemplate.class);
    @SuppressWarnings("unchecked")
    ValueOperations<String, String> valueOperations = mock(ValueOperations.class);
    @SuppressWarnings("unchecked")
    ObjectProvider<StringRedisTemplate> provider = mock(ObjectProvider.class);
    when(provider.getIfAvailable()).thenReturn(redisTemplate);
    when(redisTemplate.opsForValue()).thenReturn(valueOperations);
    when(valueOperations.get(CACHE_KEY))
      .thenReturn("[{\"id\":\"kakao-1\",\"name\":\"후보 1\",\"provider\":\"kakao\",\"lat\":37.61,\"lng\":127.11}]");
    RedisPlaceSearchCache cache = new RedisPlaceSearchCache(objectMapper, provider);

    Optional<List<Map<String, Object>>> cached = cache.get(CACHE_KEY);

    assertThat(cached).isPresent();
    assertThat(cached.orElseThrow()).singleElement()
      .satisfies(result -> assertThat(result)
        .containsEntry("id", "kakao-1")
        .containsEntry("provider", "kakao")
        .containsEntry("lat", 37.61)
        .containsEntry("lng", 127.11));
  }

  @Test
  void missingRedisTemplateKeepsSearchCacheOptional() {
    @SuppressWarnings("unchecked")
    ObjectProvider<StringRedisTemplate> provider = mock(ObjectProvider.class);
    when(provider.getIfAvailable()).thenReturn(null);
    RedisPlaceSearchCache cache = new RedisPlaceSearchCache(objectMapper, provider);

    assertThat(cache.get(CACHE_KEY)).isEmpty();
    cache.put(CACHE_KEY, List.of(Map.of("id", "naver-1")));
  }
}
