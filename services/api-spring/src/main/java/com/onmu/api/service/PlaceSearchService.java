package com.onmu.api.service;

import com.onmu.api.place.DevMockPlaceSearchProvider;
import com.onmu.api.place.PlaceSearchCache;
import com.onmu.api.place.PlaceSearchProvider;
import com.onmu.api.place.PlaceSearchQuery;
import com.onmu.api.place.PlaceSearchResult;
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
import org.springframework.stereotype.Service;

@Service
public class PlaceSearchService {
  private static final Logger LOGGER = LoggerFactory.getLogger(PlaceSearchService.class);
  private static final int RESULT_LIMIT = 5;
  private static final List<String> PROVIDER_ORDER = List.of("naver", "kakao");

  private final List<PlaceSearchProvider> providers;
  private final DevMockPlaceSearchProvider devMockProvider;
  private final PlaceSearchCache cache;

  public PlaceSearchService(
    List<PlaceSearchProvider> providers,
    DevMockPlaceSearchProvider devMockProvider,
    PlaceSearchCache cache
  ) {
    this.providers = providers.stream()
      .filter(provider -> !"dev-mock".equals(provider.provider()))
      .sorted(Comparator.comparingInt(provider -> providerPriority(provider.provider())))
      .toList();
    this.devMockProvider = devMockProvider;
    this.cache = cache;
  }

  @PostConstruct
  void logProviderAvailability() {
    Map<String, Object> availability = new LinkedHashMap<>();
    providers.forEach(provider -> availability.put(provider.provider(), provider.isAvailable()));
    LOGGER.info("Place search provider availability: {}", availability);
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
    String cacheKey = cacheKey(searchQuery);
    var cached = cache.get(cacheKey);
    if (cached.isPresent()) {
      return cached.get();
    }

    List<PlaceSearchProvider> selectedProviders = selectedProviders(searchQuery.providers());
    List<PlaceSearchProvider> availableProviders = selectedProviders.stream()
      .filter(PlaceSearchProvider::isAvailable)
      .toList();
    boolean usedDevMock = availableProviders.isEmpty();
    List<PlaceSearchResult> normalizedResults = usedDevMock
      ? devMockProvider.search(searchQuery)
      : searchExternalProviders(searchQuery, availableProviders);

    Map<String, Object> context = context(searchQuery, usedDevMock ? List.of(devMockProvider.provider()) : providerNames(availableProviders), usedDevMock);
    List<Map<String, Object>> results = normalizedResults.stream()
      .limit(RESULT_LIMIT)
      .map(result -> result.toApiMap(context))
      .toList();
    cache.put(cacheKey, results);
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
        List<PlaceSearchResult> providerResults = provider.search(query);
        for (PlaceSearchResult result : providerResults) {
          String key = dedupeKey(result);
          if (seen.add(key)) {
            results.add(result);
          }
          if (!query.compare() && results.size() >= RESULT_LIMIT) {
            break;
          }
        }
      } catch (RuntimeException exception) {
        LOGGER.warn("Place search provider failed: provider={}, message={}", provider.provider(), exception.getClass().getSimpleName());
      }
    }
    return results;
  }

  private List<PlaceSearchProvider> selectedProviders(List<String> requestedProviders) {
    if (requestedProviders.isEmpty()) {
      return providers;
    }
    Set<String> requested = new LinkedHashSet<>(requestedProviders);
    return providers.stream()
      .filter(provider -> requested.contains(provider.provider()))
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

  private String dedupeKey(PlaceSearchResult result) {
    return normalize(result.name()) + "|" + normalize(result.roadAddress() == null ? result.address() : result.roadAddress());
  }

  private String normalize(String value) {
    return value == null ? "" : value.toLowerCase(Locale.ROOT).replaceAll("\\s+", "");
  }

  private int providerPriority(String provider) {
    int index = PROVIDER_ORDER.indexOf(provider);
    return index < 0 ? PROVIDER_ORDER.size() : index;
  }

  private String cacheKey(PlaceSearchQuery query) {
    String value = String.join("|",
      query.normalizedQuery(),
      nullToBlank(query.groupId()),
      nullToBlank(query.planId()),
      nullToBlank(query.lat()),
      nullToBlank(query.lng()),
      nullToBlank(query.radius()),
      query.normalizedCategory(),
      String.join(",", query.providers()),
      Boolean.toString(query.compare())
    );
    try {
      MessageDigest digest = MessageDigest.getInstance("SHA-256");
      byte[] hash = digest.digest(value.getBytes(StandardCharsets.UTF_8));
      return "place-search:v1:" + HexFormat.of().formatHex(hash, 0, 16);
    } catch (NoSuchAlgorithmException exception) {
      throw new IllegalStateException("SHA-256 is required", exception);
    }
  }

  private String nullToBlank(Object value) {
    return value == null ? "" : String.valueOf(value);
  }
}
