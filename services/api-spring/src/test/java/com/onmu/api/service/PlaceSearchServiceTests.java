package com.onmu.api.service;

import static org.assertj.core.api.Assertions.assertThat;

import com.onmu.api.place.DevMockPlaceSearchProvider;
import com.onmu.api.place.PlaceSearchCache;
import com.onmu.api.place.PlaceSearchProvider;
import com.onmu.api.place.PlaceSearchQuery;
import com.onmu.api.place.PlaceSearchResult;
import java.time.Instant;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.springframework.mock.env.MockEnvironment;

class PlaceSearchServiceTests {
  @Test
  void searchReturnsNeutralDevCandidatesWhenExternalCredentialsAreUnavailable() {
    PlaceSearchService service = new PlaceSearchService(
      List.of(new FakeProvider("naver", false, List.of())),
      new DevMockPlaceSearchProvider(),
      new NoopCache(),
      localEnvironment()
    );

    var results = service.search("카페", "1", "101");

    assertThat(results).hasSize(3);
    assertThat(results.get(0))
      .containsEntry("category", "cafe")
      .containsEntry("canAddCandidate", true)
      .containsEntry("source", "dev-mock")
      .containsEntry("myHearted", false)
      .containsEntry("lat", 37.5665)
      .containsEntry("lng", 126.9780)
      .containsEntry("provider", "dev-mock")
      .containsEntry("providerPlaceId", "mock-place-1");
    assertThat(results.getFirst()).containsKey("heartCount");
    assertThat(results.getFirst()).doesNotContainKeys("sco" + "re", "risk" + "Label", "risk" + "Tone");
  }

  @Test
  void searchUsesNaverFirstAndKakaoSupplement() {
    PlaceSearchService service = new PlaceSearchService(
      List.of(
        new FakeProvider("kakao", true, List.of(result("kakao", "kakao-1", "카카오 후보", "서울 강남구", 37.5, 127.0))),
        new FakeProvider("naver", true, List.of(result("naver", "naver-1", "네이버 후보", "서울 종로구", null, null)))
      ),
      new DevMockPlaceSearchProvider(),
      new NoopCache(),
      localEnvironment()
    );

    var results = service.search("카페", "1", "101");

    assertThat(results).hasSize(2);
    assertThat(results.get(0))
      .containsEntry("provider", "naver")
      .containsEntry("providerPlaceId", "naver-1")
      .containsEntry("lat", null)
      .containsEntry("lng", null);
    assertThat(results.get(1))
      .containsEntry("provider", "kakao")
      .containsEntry("providerPlaceId", "kakao-1")
      .containsEntry("lat", 37.5)
      .containsEntry("lng", 127.0);
  }

  @Test
  void searchCanLimitToRequestedProvider() {
    PlaceSearchService service = new PlaceSearchService(
      List.of(
        new FakeProvider("naver", true, List.of(result("naver", "naver-1", "네이버 후보", "서울", null, null))),
        new FakeProvider("kakao", true, List.of(result("kakao", "kakao-1", "카카오 후보", "서울", 37.5, 127.0)))
      ),
      new DevMockPlaceSearchProvider(),
      new NoopCache(),
      localEnvironment()
    );

    var results = service.search("카페", "1", "101", null, null, null, null, List.of("kakao"), true);

    assertThat(results).singleElement()
      .satisfies(result -> assertThat(result).containsEntry("provider", "kakao"));
  }

  @Test
  void searchFallsBackToDevMockInLocalWhenExternalProviderReturnsNoResults() {
    PlaceSearchService service = new PlaceSearchService(
      List.of(new FakeProvider("naver", true, List.of())),
      new DevMockPlaceSearchProvider(),
      new NoopCache(),
      localEnvironment()
    );

    var results = service.search("홍대 카페", "1", "104");

    assertThat(results).hasSize(3);
    assertThat(results.getFirst())
      .containsEntry("provider", "dev-mock")
      .containsEntry("source", "dev-mock")
      .containsEntry("category", "cafe")
      .containsEntry("lat", 37.5665)
      .containsEntry("lng", 126.9780);
    assertThat(results.getFirst()).extracting("context")
      .isInstanceOfSatisfying(Map.class, context ->
        assertThat(context)
          .containsEntry("groupId", "1")
          .containsEntry("planId", "104")
          .containsEntry("source", "dev-mock"));
  }

  @Test
  void searchDoesNotMixDevMockInProdWhenExternalProviderReturnsNoResults() {
    MockEnvironment environment = new MockEnvironment()
      .withProperty("spring.datasource.url", "jdbc:postgresql://prod-db.internal/onmu");
    environment.setActiveProfiles("prod");
    PlaceSearchService service = new PlaceSearchService(
      List.of(new FakeProvider("naver", true, List.of())),
      new DevMockPlaceSearchProvider(),
      new NoopCache(),
      environment
    );

    var results = service.search("홍대 카페", "1", "104");

    assertThat(results).isEmpty();
  }

  @Test
  void searchFallsBackWhenUppercaseEnvOptInIsSetAndAvailableProviderFails() {
    MockEnvironment environment = prodEnvironment()
      .withProperty("ONMU_PLACE_DEV_MOCK_FALLBACK_ENABLED", "true");
    PlaceSearchService service = new PlaceSearchService(
      List.of(new ThrowingProvider("kakao", true)),
      new DevMockPlaceSearchProvider(),
      new NoopCache(),
      environment
    );

    var results = service.search("홍대 카페", "1", "104");

    assertThat(results).hasSize(3);
    assertThat(results.getFirst())
      .containsEntry("provider", "dev-mock")
      .containsEntry("source", "dev-mock")
      .containsEntry("lat", 37.5665)
      .containsEntry("lng", 126.9780);
    assertThat(results.getFirst()).extracting("context")
      .isInstanceOfSatisfying(Map.class, context ->
        assertThat(context).containsEntry("source", "dev-mock"));
  }

  @Test
  void searchFallsBackWhenSystemPropertyOptInIsSetInProdLikeEnvironment() {
    String previous = System.getProperty("onmu.place.dev-mock-fallback-enabled");
    System.setProperty("onmu.place.dev-mock-fallback-enabled", "true");
    try {
      PlaceSearchService service = new PlaceSearchService(
        List.of(new FakeProvider("kakao", true, List.of())),
        new DevMockPlaceSearchProvider(),
        new NoopCache(),
        prodEnvironment()
      );

      var results = service.search("성수동 카페", "1", "105");

      assertThat(results).hasSize(3);
      assertThat(results.getFirst()).containsEntry("provider", "dev-mock");
    } finally {
      if (previous == null) {
        System.clearProperty("onmu.place.dev-mock-fallback-enabled");
      } else {
        System.setProperty("onmu.place.dev-mock-fallback-enabled", previous);
      }
    }
  }

  @Test
  void enablingExplicitFallbackDoesNotReuseCachedEmptyExternalResults() {
    MockEnvironment environment = prodEnvironment();
    MemoryCache cache = new MemoryCache();
    PlaceSearchService service = new PlaceSearchService(
      List.of(new FakeProvider("kakao", true, List.of())),
      new DevMockPlaceSearchProvider(),
      cache,
      environment
    );

    var externalOnlyResults = service.search("홍대 카페", "1", "104");
    environment.withProperty("ONMU_PLACE_DEV_MOCK_FALLBACK_ENABLED", "true");
    var fallbackResults = service.search("홍대 카페", "1", "104");

    assertThat(externalOnlyResults).isEmpty();
    assertThat(fallbackResults).hasSize(3);
    assertThat(fallbackResults.getFirst()).containsEntry("provider", "dev-mock");
    assertThat(cache.keys()).hasSize(1);
  }

  @Test
  void cachedDevMockFromUnavailableProviderDoesNotMaskRecoveredProvider() {
    MutableProvider naver = new MutableProvider("naver", false, List.of());
    MemoryCache cache = new MemoryCache();
    PlaceSearchService service = new PlaceSearchService(
      List.of(naver),
      new DevMockPlaceSearchProvider(),
      cache,
      localEnvironment()
    );

    var fallbackResults = service.search("홍대 카페", "1", "104");
    naver.available = true;
    naver.results = List.of(result("naver", "naver-1", "네이버 후보", "서울", 37.5, 127.0));
    var recoveredResults = service.search("홍대 카페", "1", "104");

    assertThat(fallbackResults.getFirst()).containsEntry("provider", "dev-mock");
    assertThat(recoveredResults).singleElement()
      .satisfies(result -> assertThat(result)
        .containsEntry("provider", "naver")
        .containsEntry("source", "naver")
        .containsEntry("lat", 37.5)
        .containsEntry("lng", 127.0));
    assertThat(cache.keys()).hasSize(2);
  }

  private static PlaceSearchResult result(
    String provider,
    String providerPlaceId,
    String name,
    String address,
    Double lat,
    Double lng
  ) {
    return new PlaceSearchResult(provider, providerPlaceId, name, "카페", address, address, lat, lng, null, Instant.parse("2026-06-10T00:00:00Z"));
  }

  private static MockEnvironment localEnvironment() {
    return new MockEnvironment()
      .withProperty("spring.datasource.url", "jdbc:postgresql://localhost:15432/onmu");
  }

  private static MockEnvironment prodEnvironment() {
    MockEnvironment environment = new MockEnvironment()
      .withProperty("spring.datasource.url", "jdbc:postgresql://prod-db.internal/onmu");
    environment.setActiveProfiles("prod");
    return environment;
  }

  private record FakeProvider(String provider, boolean available, List<PlaceSearchResult> results) implements PlaceSearchProvider {
    @Override
    public boolean isAvailable() {
      return available;
    }

    @Override
    public List<PlaceSearchResult> search(PlaceSearchQuery query) {
      return results;
    }
  }

  private record ThrowingProvider(String provider, boolean available) implements PlaceSearchProvider {
    @Override
    public boolean isAvailable() {
      return available;
    }

    @Override
    public List<PlaceSearchResult> search(PlaceSearchQuery query) {
      throw new IllegalStateException("Forbidden");
    }
  }

  private static class MutableProvider implements PlaceSearchProvider {
    private final String provider;
    private boolean available;
    private List<PlaceSearchResult> results;

    private MutableProvider(String provider, boolean available, List<PlaceSearchResult> results) {
      this.provider = provider;
      this.available = available;
      this.results = results;
    }

    @Override
    public String provider() {
      return provider;
    }

    @Override
    public boolean isAvailable() {
      return available;
    }

    @Override
    public List<PlaceSearchResult> search(PlaceSearchQuery query) {
      return results;
    }
  }

  private static class NoopCache implements PlaceSearchCache {
    @Override
    public Optional<List<Map<String, Object>>> get(String key) {
      return Optional.empty();
    }

    @Override
    public void put(String key, List<Map<String, Object>> results) {
    }
  }

  private static class MemoryCache implements PlaceSearchCache {
    private final Map<String, List<Map<String, Object>>> values = new HashMap<>();

    @Override
    public Optional<List<Map<String, Object>>> get(String key) {
      return Optional.ofNullable(values.get(key));
    }

    @Override
    public void put(String key, List<Map<String, Object>> results) {
      values.put(key, results);
    }

    List<String> keys() {
      return values.keySet().stream().toList();
    }
  }
}
