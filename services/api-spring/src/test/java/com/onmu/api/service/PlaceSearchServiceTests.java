package com.onmu.api.service;

import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.onmu.api.place.DevMockPlaceSearchProvider;
import com.onmu.api.place.NaverLocalSearchMapper;
import com.onmu.api.place.NaverLocalSearchProvider;
import com.onmu.api.place.PlaceSearchCache;
import com.onmu.api.place.PlaceSearchHttpClient;
import com.onmu.api.place.PlaceSearchProvider;
import com.onmu.api.place.PlaceSearchQuery;
import com.onmu.api.place.PlaceSearchResult;
import java.net.URI;
import java.time.Instant;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.mock.env.MockEnvironment;
import org.springframework.web.client.HttpClientErrorException;

class PlaceSearchServiceTests {
  private static final String SYNTHETIC_NAVER_JSON = """
    {
      "lastBuildDate": "Sun, 14 Jun 2026 00:00:00 +0900",
      "total": 1,
      "start": 1,
      "display": 1,
      "items": [
        {
          "title": "<b>ONMU Cafe</b>",
          "link": "https://example.test/naver-place",
          "category": "Cafe>Brunch",
          "description": "",
          "telephone": "",
          "address": "Seoul Jongno-gu",
          "roadAddress": "Seoul Road 10",
          "mapx": "1269780000",
          "mapy": "375665000"
        }
      ]
    }
    """;

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
  void searchKeepsSupplementingProvidersUntilExpandedResultLimitAndCachesResults() {
    CountingProvider naver = new CountingProvider("naver", true, List.of(
      result("naver", "naver-1", "네이버 후보 1", "서울 종로구 1", 37.51, 127.01),
      result("naver", "naver-2", "네이버 후보 2", "서울 종로구 2", 37.52, 127.02),
      result("naver", "naver-3", "네이버 후보 3", "서울 종로구 3", 37.53, 127.03),
      result("naver", "naver-4", "네이버 후보 4", "서울 종로구 4", 37.54, 127.04),
      result("naver", "naver-5", "네이버 후보 5", "서울 종로구 5", 37.55, 127.05)
    ));
    CountingProvider kakao = new CountingProvider("kakao", true, List.of(
      result("kakao", "kakao-1", "카카오 후보 1", "서울 성동구 1", 37.61, 127.11),
      result("kakao", "kakao-2", "카카오 후보 2", "서울 성동구 2", 37.62, 127.12),
      result("kakao", "kakao-3", "카카오 후보 3", "서울 성동구 3", 37.63, 127.13),
      result("kakao", "kakao-4", "카카오 후보 4", "서울 성동구 4", 37.64, 127.14),
      result("kakao", "kakao-5", "카카오 후보 5", "서울 성동구 5", 37.65, 127.15),
      result("kakao", "kakao-6", "카카오 후보 6", "서울 성동구 6", 37.66, 127.16),
      result("kakao", "kakao-7", "카카오 후보 7", "서울 성동구 7", 37.67, 127.17),
      result("kakao", "kakao-8", "카카오 후보 8", "서울 성동구 8", 37.68, 127.18),
      result("kakao", "kakao-9", "카카오 후보 9", "서울 성동구 9", 37.69, 127.19),
      result("kakao", "kakao-10", "카카오 후보 10", "서울 성동구 10", 37.70, 127.20),
      result("kakao", "kakao-11", "카카오 후보 11", "서울 성동구 11", 37.71, 127.21),
      result("kakao", "kakao-12", "카카오 후보 12", "서울 성동구 12", 37.72, 127.22),
      result("kakao", "kakao-13", "카카오 후보 13", "서울 성동구 13", 37.73, 127.23),
      result("kakao", "kakao-14", "카카오 후보 14", "서울 성동구 14", 37.74, 127.24),
      result("kakao", "kakao-15", "카카오 후보 15", "서울 성동구 15", 37.75, 127.25)
    ));
    MemoryCache cache = new MemoryCache();
    PlaceSearchService service = new PlaceSearchService(
      List.of(kakao, naver),
      new DevMockPlaceSearchProvider(),
      cache,
      localEnvironment()
    );

    var firstResults = service.search("성수 맛집", "1", "101");
    var cachedResults = service.search("성수 맛집", "1", "101");

    assertThat(firstResults).hasSize(20);
    assertThat(cachedResults).hasSize(20);
    assertThat(firstResults).isEqualTo(cachedResults);
    assertThat(firstResults.subList(0, 5))
      .allSatisfy(result -> assertThat(result).containsEntry("provider", "naver"));
    assertThat(firstResults.subList(5, 20))
      .allSatisfy(result -> assertThat(result).containsEntry("provider", "kakao"));
    assertThat(cache.keys()).hasSize(1);
    assertThat(naver.invocations).isEqualTo(5);
    assertThat(kakao.invocations).isEqualTo(1);
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
  void searchKeepsNaverOnlyProviderResultsInsteadOfDevMockFallback() {
    PlaceSearchService service = new PlaceSearchService(
      List.of(
        new FakeProvider("naver", true, List.of(result("naver", "naver-1", "네이버 후보", "서울", 37.5, 127.0))),
        new FakeProvider("kakao", true, List.of(result("kakao", "kakao-1", "카카오 후보", "서울", 37.6, 127.1)))
      ),
      new DevMockPlaceSearchProvider(),
      new NoopCache(),
      localEnvironment()
    );

    var results = service.search("카페", "1", "101", null, null, null, null, List.of("naver"), false);

    assertThat(results).singleElement()
      .satisfies(result -> assertThat(result)
        .containsEntry("provider", "naver")
        .containsEntry("source", "naver")
        .containsEntry("providerPlaceId", "naver-1")
        .containsEntry("lat", 37.5)
        .containsEntry("lng", 127.0));
  }

  @Test
  void searchNaverOnlyThroughNaverProviderReturnsExternalResults() {
    CapturingHttpClient httpClient = new CapturingHttpClient(SYNTHETIC_NAVER_JSON);
    PlaceSearchService service = new PlaceSearchService(
      List.of(naverProvider(httpClient, naverEnvironmentWithCredentials())),
      new DevMockPlaceSearchProvider(),
      new NoopCache(),
      localEnvironment()
    );

    var results = service.search("홍대 카페", "1", "104", null, null, null, null, List.of(" NAVER ", "naver"), false);

    assertThat(results).singleElement()
      .satisfies(result -> {
        assertThat(result)
          .containsEntry("provider", "naver")
          .containsEntry("source", "naver")
          .containsEntry("name", "ONMU Cafe")
          .containsEntry("category", "Cafe > Brunch")
          .containsEntry("address", "Seoul Jongno-gu")
          .containsEntry("roadAddress", "Seoul Road 10")
          .containsEntry("sourceUrl", "https://example.test/naver-place")
          .containsEntry("lat", 37.5665)
          .containsEntry("lng", 126.9780);
        assertThat(result.get("context"))
          .isInstanceOfSatisfying(Map.class, context ->
            assertThat(context)
              .containsEntry("source", "external-provider")
              .containsEntry("providers", List.of("naver")));
      });
    assertThat(httpClient.requestedUris).hasSize(3);
    assertThat(httpClient.requestedUris.stream().map(URI::getRawQuery).toList())
      .anySatisfy(query -> assertThat(query)
        .contains("query=%ED%99%8D%EB%8C%80%20%EC%B9%B4%ED%8E%98")
        .contains("display=5")
        .contains("start=1")
        .contains("sort=random"))
      .anySatisfy(query -> assertThat(query)
        .contains("query=%ED%99%8D%EB%8C%80%20%EB%94%94%EC%A0%80%ED%8A%B8"))
      .anySatisfy(query -> assertThat(query)
        .contains("query=%ED%99%8D%EB%8C%80%20%EB%B2%A0%EC%9D%B4%EC%BB%A4%EB%A6%AC"));
    assertThat(httpClient.headers).containsKeys("X-Naver-Client-Id", "X-Naver-Client-Secret");
  }

  @Test
  void searchFansOutNaverRestaurantCategoryAndDedupesToExpandedLimit() {
    QueryAwareProvider naver = new QueryAwareProvider("naver", true);
    MemoryCache cache = new MemoryCache();
    PlaceSearchService service = new PlaceSearchService(
      List.of(naver),
      new DevMockPlaceSearchProvider(),
      cache,
      localEnvironment()
    );

    var firstResults = service.search("성수", "1", "101", null, null, null, "음식점", List.of("naver"), false);
    var cachedResults = service.search("성수", "1", "101", null, null, null, "음식점", List.of("naver"), false);

    assertThat(firstResults).hasSize(20);
    assertThat(cachedResults).isEqualTo(firstResults);
    assertThat(naver.queries)
      .containsExactly("성수 한식", "성수 양식", "성수 중식", "성수 일식", "성수 아시안식");
    assertThat(cache.keys()).singleElement().asString().startsWith("place-search:v3:");
  }

  @Test
  void searchFallsBackToDevMockWhenNaverHttpClientFails() {
    PlaceSearchService service = new PlaceSearchService(
      List.of(naverProvider(new FailingHttpClient(), naverEnvironmentWithCredentials())),
      new DevMockPlaceSearchProvider(),
      new NoopCache(),
      localEnvironment()
    );

    var results = service.search("홍대 카페", "1", "104", null, null, null, null, List.of("naver"), false);

    assertThat(results).hasSize(3);
    assertThat(results.getFirst())
      .containsEntry("provider", "dev-mock")
      .containsEntry("source", "dev-mock")
      .containsEntry("lat", 37.5665)
      .containsEntry("lng", 126.9780);
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

  private static MockEnvironment naverEnvironmentWithCredentials() {
    return new MockEnvironment()
      .withProperty("NAVER_SEARCH_CLIENT_ID", " synthetic-client-id ")
      .withProperty("NAVER_SEARCH_CLIENT_SECRET", " synthetic-client-secret ");
  }

  private static NaverLocalSearchProvider naverProvider(PlaceSearchHttpClient httpClient, MockEnvironment environment) {
    return new NaverLocalSearchProvider(
      environment,
      httpClient,
      new NaverLocalSearchMapper(new ObjectMapper()),
      "https://openapi.naver.com/v1/search/local.json"
    );
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

  private static class CountingProvider implements PlaceSearchProvider {
    private final String provider;
    private final boolean available;
    private final List<PlaceSearchResult> results;
    private int invocations;

    private CountingProvider(String provider, boolean available, List<PlaceSearchResult> results) {
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
      invocations += 1;
      return results;
    }
  }

  private static class QueryAwareProvider implements PlaceSearchProvider {
    private final String provider;
    private final boolean available;
    private final List<String> queries = new java.util.ArrayList<>();

    private QueryAwareProvider(String provider, boolean available) {
      this.provider = provider;
      this.available = available;
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
      queries.add(query.normalizedQuery());
      return java.util.stream.IntStream.rangeClosed(1, 5)
        .mapToObj(index -> result(
          provider,
          provider + "-" + query.normalizedQuery() + "-" + index,
          query.normalizedQuery() + " 후보 " + index,
          "서울 성동구 " + query.normalizedQuery() + " " + index,
          37.50 + queries.size() / 100.0 + index / 10000.0,
          127.00 + queries.size() / 100.0 + index / 10000.0
        ))
        .toList();
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

  private static class CapturingHttpClient implements PlaceSearchHttpClient {
    private final String response;
    private URI requestedUri;
    private final List<URI> requestedUris = new java.util.ArrayList<>();
    private Map<String, String> headers = Map.of();

    private CapturingHttpClient(String response) {
      this.response = response;
    }

    @Override
    public String get(URI uri, Map<String, String> headers) {
      this.requestedUri = uri;
      this.requestedUris.add(uri);
      this.headers = new LinkedHashMap<>(headers);
      return response;
    }
  }

  private static class FailingHttpClient implements PlaceSearchHttpClient {
    @Override
    public String get(URI uri, Map<String, String> headers) {
      throw new HttpClientErrorException(HttpStatus.UNAUTHORIZED);
    }
  }
}
