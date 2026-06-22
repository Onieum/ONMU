package com.onmu.api.service;

import com.onmu.api.place.DevMockPlaceSearchProvider;
import com.onmu.api.place.PlaceSearchCache;
import com.onmu.api.place.PlaceSearchProvider;
import com.onmu.api.place.PlaceSearchQuery;
import com.onmu.api.place.PlaceSearchResult;
import com.onmu.api.place.PlaceRecommendationReasoner;
import jakarta.annotation.PostConstruct;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HexFormat;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.env.Environment;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClientResponseException;

@Service
public class PlaceSearchService {
  private static final Logger LOGGER = LoggerFactory.getLogger(PlaceSearchService.class);
  private static final int RESULT_LIMIT = 20;
  private static final int NAVER_FANOUT_QUERY_LIMIT = 5;
  private static final String CURATED_PROVIDER = "onmu_catalog";
  private static final List<String> DEFAULT_PROVIDER_ORDER = List.of("naver", "kakao", CURATED_PROVIDER);
  private static final List<String> ATTRACTION_PROVIDER_ORDER = List.of(CURATED_PROVIDER, "naver", "kakao");
  private static final List<String> FOOD_FANOUT_KEYWORDS = List.of("한식", "양식", "중식", "일식", "아시안식");
  private static final List<String> CAFE_FANOUT_KEYWORDS = List.of("카페", "디저트", "베이커리");
  private static final List<String> ATTRACTION_FANOUT_KEYWORDS = List.of("공원", "해수욕장", "박물관", "미술관", "전시", "전망대", "산책로");
  private static final List<String> BROAD_ATTRACTION_KEYWORDS = List.of("가볼만한곳", "관광", "명소", "attraction");
  private static final String FALLBACK_PROPERTY = "onmu.place.dev-mock-fallback-enabled";
  private static final String FALLBACK_ENV = "ONMU_PLACE_DEV_MOCK_FALLBACK_ENABLED";

  private final List<PlaceSearchProvider> providers;
  private final DevMockPlaceSearchProvider devMockProvider;
  private final PlaceSearchCache cache;
  private final Environment environment;
  private final PlaceRecommendationReasoner recommendationReasoner;

  @Autowired
  public PlaceSearchService(
    List<PlaceSearchProvider> providers,
    DevMockPlaceSearchProvider devMockProvider,
    PlaceSearchCache cache,
    Environment environment
  ) {
    this(providers, devMockProvider, cache, environment, new PlaceRecommendationReasoner());
  }

  PlaceSearchService(
    List<PlaceSearchProvider> providers,
    DevMockPlaceSearchProvider devMockProvider,
    PlaceSearchCache cache,
    Environment environment,
    PlaceRecommendationReasoner recommendationReasoner
  ) {
    this.providers = providers.stream()
      .filter(provider -> !"dev-mock".equals(provider.provider()))
      .sorted(Comparator.comparingInt(provider -> providerPriority(provider.provider())))
      .toList();
    this.devMockProvider = devMockProvider;
    this.cache = cache;
    this.environment = environment;
    this.recommendationReasoner = recommendationReasoner;
  }

  @PostConstruct
  void logProviderAvailability() {
    Map<String, Object> availability = new LinkedHashMap<>();
    providers.forEach(provider -> availability.put(provider.provider(), provider.isAvailable()));
    LOGGER.info("Place search provider availability: {}", availability);
    DevMockFallbackMode fallbackMode = devMockFallbackMode();
    LOGGER.info("Place search dev mock fallback: enabled={}, source={}", fallbackMode.enabled(), fallbackMode.source());
  }

  public List<Map<String, Object>> search(String query, String groupId, String planId) {
    return search(query, groupId, planId, null, null, null, null);
  }

  public List<Map<String, Object>> search(
    String query,
    String groupId,
    String planId,
    Double lat,
    Double lng,
    Integer radius,
    String requestedCategory
  ) {
    return search(query, groupId, planId, lat, lng, radius, requestedCategory, List.of(), false);
  }

  public List<Map<String, Object>> search(
    String query,
    String groupId,
    String planId,
    Double lat,
    Double lng,
    Integer radius,
    String requestedCategory,
    List<String> requestedProviders,
    boolean compare
  ) {
    PlaceSearchQuery searchQuery = new PlaceSearchQuery(
      query,
      groupId,
      planId,
      lat,
      lng,
      radius,
      requestedCategory,
      requestedProviders,
      compare
    );
    List<PlaceSearchProvider> selectedProviders = selectedProviders(searchQuery.providers(), searchQuery);
    List<PlaceSearchProvider> availableProviders = selectedProviders.stream()
      .filter(PlaceSearchProvider::isAvailable)
      .toList();
    LOGGER.info("Place search provider selection: requested_count={}, selected={}, available={}",
      searchQuery.providers().size(), providerNames(selectedProviders), providerNames(availableProviders));
    DevMockFallbackMode fallbackMode = devMockFallbackMode();
    String cacheKey = cacheKey(searchQuery, fallbackMode, providerNames(availableProviders));
    var cached = cache.get(cacheKey);
    if (cached.isPresent()) {
      return cached.get();
    }

    boolean usedDevMock = false;
    List<PlaceSearchResult> normalizedResults = List.of();
    if (availableProviders.isEmpty()) {
      if (fallbackMode.enabled()) {
        usedDevMock = true;
        normalizedResults = devMockProvider.search(searchQuery);
        LOGGER.info("Using dev mock place search fallback after no available providers: groupId={}, planId={}, source={}",
          searchQuery.groupId(), searchQuery.planId(), fallbackMode.source());
      }
    } else {
      normalizedResults = searchExternalProviders(searchQuery, availableProviders);
      if (normalizedResults.isEmpty() && fallbackMode.enabled()) {
        usedDevMock = true;
        normalizedResults = devMockProvider.search(searchQuery);
        LOGGER.info("Using dev mock place search fallback after empty or failed provider results: groupId={}, planId={}, source={}",
          searchQuery.groupId(), searchQuery.planId(), fallbackMode.source());
      }
    }

    Map<String, Object> context = context(searchQuery, usedDevMock ? List.of(devMockProvider.provider()) : providerNames(availableProviders), usedDevMock);
    List<Map<String, Object>> results = new ArrayList<>();
    int rank = 1;
    for (PlaceSearchResult result : normalizedResults.stream().limit(RESULT_LIMIT).toList()) {
      Map<String, Object> value = result.toApiMap(context);
      value.putAll(recommendationReasoner.explainSearchResult(result, searchQuery, rank));
      results.add(value);
      rank++;
    }
    if (!(usedDevMock && !availableProviders.isEmpty())) {
      cache.put(cacheKey, results);
    }
    return results;
  }

  private List<PlaceSearchResult> searchExternalProviders(
    PlaceSearchQuery query,
    List<PlaceSearchProvider> availableProviders
  ) {
    List<PlaceSearchResult> results = new ArrayList<>();
    Set<String> seen = new LinkedHashSet<>();
    for (PlaceSearchProvider provider : availableProviders) {
      if (!query.compare() && results.size() >= RESULT_LIMIT) {
        break;
      }
      try {
        List<PlaceSearchQuery> providerQueries = providerQueries(query, provider);
        LOGGER.info("Place search provider invocation started: provider={}, query_count={}",
          provider.provider(), providerQueries.size());
        List<PlaceSearchResult> providerResults = new ArrayList<>();
        for (PlaceSearchQuery providerQuery : providerQueries) {
          providerResults.addAll(provider.search(providerQuery));
        }
        int acceptedBefore = results.size();
        for (PlaceSearchResult result : providerResults) {
          String key = dedupeKey(result);
          if (seen.add(key)) {
            results.add(result);
          }
          if (!query.compare() && results.size() >= RESULT_LIMIT) {
            break;
          }
        }
        LOGGER.info("Place search provider invocation finished: provider={}, result_count={}, accepted_count={}",
          provider.provider(), providerResults.size(), results.size() - acceptedBefore);
      } catch (RestClientResponseException exception) {
        LOGGER.warn("Place search provider HTTP failed: provider={}, status={}, error_type={}",
          provider.provider(), exception.getStatusCode().value(), exception.getClass().getSimpleName());
      } catch (RuntimeException exception) {
        LOGGER.warn("Place search provider failed: provider={}, error_type={}", provider.provider(), exception.getClass().getSimpleName());
      }
    }
    return results;
  }

  private List<PlaceSearchProvider> selectedProviders(List<String> requestedProviders, PlaceSearchQuery query) {
    List<String> providerOrder = providerOrder(query);
    if (requestedProviders.isEmpty()) {
      return providers.stream()
        .sorted(Comparator.comparingInt(provider -> providerPriority(provider.provider(), providerOrder)))
        .toList();
    }
    Set<String> requested = new LinkedHashSet<>(requestedProviders);
    return providers.stream()
      .filter(provider -> requested.contains(provider.provider()))
      .sorted(Comparator.comparingInt(provider -> providerPriority(provider.provider(), providerOrder)))
      .toList();
  }

  private Map<String, Object> context(PlaceSearchQuery query, List<String> providerNames, boolean devMock) {
    Map<String, Object> context = new LinkedHashMap<>();
    context.put("groupId", query.groupId());
    context.put("planId", query.planId());
    context.put("lat", query.lat());
    context.put("lng", query.lng());
    context.put("radius", query.radius());
    context.put("category", query.normalizedCategory());
    context.put("providers", providerNames);
    context.put("compare", query.compare());
    context.put("source", devMock ? "dev-mock" : "external-provider");
    return context;
  }

  private List<String> providerNames(List<PlaceSearchProvider> values) {
    return values.stream().map(PlaceSearchProvider::provider).toList();
  }

  private DevMockFallbackMode devMockFallbackMode() {
    List<PropertyCandidate> explicitCandidates = List.of(
      new PropertyCandidate(FALLBACK_PROPERTY, environment.getProperty(FALLBACK_PROPERTY)),
      new PropertyCandidate(FALLBACK_ENV, environment.getProperty(FALLBACK_ENV)),
      new PropertyCandidate("system:" + FALLBACK_PROPERTY, System.getProperty(FALLBACK_PROPERTY)),
      new PropertyCandidate("env:" + FALLBACK_ENV, System.getenv(FALLBACK_ENV))
    );
    for (PropertyCandidate candidate : explicitCandidates) {
      if (candidate.value() != null && !candidate.value().isBlank()) {
        return new DevMockFallbackMode(Boolean.parseBoolean(candidate.value().trim()), candidate.name());
      }
    }
    for (String profile : environment.getActiveProfiles()) {
      String normalizedProfile = profile.toLowerCase(Locale.ROOT);
      if (List.of("local", "dev", "test").contains(normalizedProfile)) {
        return new DevMockFallbackMode(true, "profile:" + normalizedProfile);
      }
    }
    String datasourceUrl = environment.getProperty("spring.datasource.url", "");
    boolean localDatasource = datasourceUrl.contains("localhost")
      || datasourceUrl.contains("127.0.0.1")
      || datasourceUrl.contains("jdbc:h2:");
    return new DevMockFallbackMode(localDatasource, localDatasource ? "local-datasource" : "disabled");
  }

  private String dedupeKey(PlaceSearchResult result) {
    return normalize(result.name()) + "|" + normalize(result.roadAddress() == null ? result.address() : result.roadAddress());
  }

  private String normalize(String value) {
    return value == null ? "" : value.toLowerCase(Locale.ROOT).replaceAll("\\s+", "");
  }

  private int providerPriority(String provider) {
    return providerPriority(provider, DEFAULT_PROVIDER_ORDER);
  }

  private int providerPriority(String provider, List<String> providerOrder) {
    int index = providerOrder.indexOf(provider);
    return index < 0 ? providerOrder.size() : index;
  }

  private List<String> providerOrder(PlaceSearchQuery query) {
    return isAttractionQuery(query) ? ATTRACTION_PROVIDER_ORDER : DEFAULT_PROVIDER_ORDER;
  }

  private boolean isAttractionQuery(PlaceSearchQuery query) {
    String category = query.normalizedCategory();
    return BROAD_ATTRACTION_KEYWORDS.stream().anyMatch(keyword -> normalize(category).equals(normalize(keyword)))
      || ATTRACTION_FANOUT_KEYWORDS.stream().anyMatch(keyword -> normalize(category).equals(normalize(keyword)))
      || containsAny(query.normalizedQuery(), BROAD_ATTRACTION_KEYWORDS)
      || containsAny(query.normalizedQuery(), ATTRACTION_FANOUT_KEYWORDS);
  }

  private List<PlaceSearchQuery> providerQueries(PlaceSearchQuery query, PlaceSearchProvider provider) {
    if (!"naver".equals(provider.provider()) || query.compare()) {
      return List.of(query);
    }
    List<String> keywords = naverFanoutKeywords(query);
    if (keywords.isEmpty()) {
      return List.of(query);
    }
    String baseQuery = naverFanoutBaseQuery(query, keywords);
    return keywords.stream()
      .limit(NAVER_FANOUT_QUERY_LIMIT)
      .map(keyword -> new PlaceSearchQuery(
        appendKeyword(baseQuery, keyword),
        query.groupId(),
        query.planId(),
        query.lat(),
        query.lng(),
        query.radius(),
        query.category(),
        List.of(provider.provider()),
        query.compare()
      ))
      .toList();
  }

  private List<String> naverFanoutKeywords(PlaceSearchQuery query) {
    String category = query.normalizedCategory();
    String normalizedCategory = normalize(category);
    if (List.of("음식점", "식당", "맛집", "food", "restaurant", "place").contains(normalizedCategory)
      && containsAny(query.normalizedQuery(), List.of("맛집", "음식점", "식당"))) {
      return FOOD_FANOUT_KEYWORDS;
    }
    if (List.of("음식점", "식당", "맛집", "food", "restaurant").contains(normalizedCategory)) {
      return FOOD_FANOUT_KEYWORDS;
    }
    if (FOOD_FANOUT_KEYWORDS.stream().anyMatch(keyword -> normalizedCategory.equals(normalize(keyword)))) {
      return List.of(category.trim());
    }
    if (List.of("카페", "cafe").contains(normalizedCategory)) {
      return CAFE_FANOUT_KEYWORDS;
    }
    if (CAFE_FANOUT_KEYWORDS.stream().anyMatch(keyword -> normalizedCategory.equals(normalize(keyword)))) {
      return List.of(category.trim());
    }
    if (List.of("가볼만한곳", "관광", "명소", "attraction").contains(normalizedCategory)) {
      return ATTRACTION_FANOUT_KEYWORDS.stream().limit(NAVER_FANOUT_QUERY_LIMIT).toList();
    }
    if (ATTRACTION_FANOUT_KEYWORDS.stream().anyMatch(keyword -> normalizedCategory.equals(normalize(keyword)))) {
      return List.of(category.trim());
    }
    return List.of();
  }

  private boolean containsAny(String query, List<String> values) {
    String normalizedQuery = normalize(query);
    return values.stream().anyMatch(value -> normalizedQuery.contains(normalize(value)));
  }

  private String naverFanoutBaseQuery(PlaceSearchQuery query, List<String> keywords) {
    String value = query.normalizedQuery().trim();
    List<String> removableTokens = new ArrayList<>();
    removableTokens.add(query.normalizedCategory());
    removableTokens.addAll(List.of("음식점", "식당", "맛집", "가볼만한곳", "관광", "명소"));
    removableTokens.addAll(keywords);
    for (String token : removableTokens) {
      if (token == null || token.isBlank()) {
        continue;
      }
      value = value.replace(token, " ");
    }
    value = value.replaceAll("\\s+", " ").trim();
    return value.isBlank() ? query.normalizedQuery().trim() : value;
  }

  private String appendKeyword(String baseQuery, String keyword) {
    String normalizedBase = normalize(baseQuery);
    if (normalizedBase.contains(normalize(keyword))) {
      return baseQuery.trim();
    }
    return (baseQuery.trim() + " " + keyword.trim()).trim();
  }

  private String cacheKey(PlaceSearchQuery query, DevMockFallbackMode fallbackMode, List<String> availableProviders) {
    String value = String.join("|",
      "v4",
      query.normalizedQuery(),
      nullToBlank(query.groupId()),
      nullToBlank(query.planId()),
      nullToBlank(query.lat()),
      nullToBlank(query.lng()),
      nullToBlank(query.radius()),
      query.normalizedCategory(),
      naverFanoutSignature(query, availableProviders),
      String.join(",", query.providers()),
      String.join(",", availableProviders),
      Boolean.toString(query.compare()),
      Boolean.toString(fallbackMode.enabled())
    );
    try {
      MessageDigest digest = MessageDigest.getInstance("SHA-256");
      byte[] hash = digest.digest(value.getBytes(StandardCharsets.UTF_8));
      return "place-search:v4:" + HexFormat.of().formatHex(hash, 0, 16);
    } catch (NoSuchAlgorithmException exception) {
      throw new IllegalStateException("SHA-256 is required", exception);
    }
  }

  private String naverFanoutSignature(PlaceSearchQuery query, List<String> availableProviders) {
    if (!availableProviders.contains("naver") || query.compare()) {
      return "fanout:none";
    }
    List<String> keywords = naverFanoutKeywords(query).stream()
      .limit(NAVER_FANOUT_QUERY_LIMIT)
      .toList();
    if (keywords.isEmpty()) {
      return "fanout:none";
    }
    return "fanout:naver:" + String.join(",", keywords);
  }

  private String nullToBlank(Object value) {
    return value == null ? "" : String.valueOf(value);
  }

  private record PropertyCandidate(String name, String value) {
  }

  private record DevMockFallbackMode(boolean enabled, String source) {
  }
}
