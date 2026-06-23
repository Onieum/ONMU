package com.onmu.api.place;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.onmu.api.domain.ExternalPlaceEntity;
import com.onmu.api.domain.ExternalPlaceRepository;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import org.springframework.stereotype.Component;

@Component
public class CuratedPlaceSearchProvider implements PlaceSearchProvider {
  private static final String API_PROVIDER = "onmu_catalog";
  private static final String STORED_PROVIDER = "ONMU_CATALOG";
  private static final int RESULT_LIMIT = 20;
  private static final double EARTH_RADIUS_METERS = 6_371_000.0;
  private static final List<String> FOOD_CATEGORIES = List.of("식당");
  private static final List<String> ATTRACTION_CATEGORIES = List.of("관광명소", "문화공간", "행사");
  private static final List<String> FOOD_TOKENS = List.of("음식점", "식당", "맛집", "한식", "양식", "중식", "일식", "아시안식", "분식");
  private static final List<String> CAFE_TOKENS = List.of("카페", "디저트", "베이커리", "커피", "브런치");
  private static final List<String> ATTRACTION_TOKENS = List.of("가볼만한곳", "관광", "명소", "공원", "해수욕장", "박물관", "미술관", "전시", "전망대", "산책로");
  private static final List<String> BROAD_ATTRACTION_TOKENS = List.of("가볼만한곳", "관광", "명소", "attraction", "place");
  private static final List<String> BROAD_FOOD_TOKENS = List.of("음식점", "식당", "맛집", "food", "restaurant", "place");
  private static final List<String> BROAD_CAFE_TOKENS = List.of("카페", "cafe", "place");

  private final ExternalPlaceRepository repository;
  private final ObjectMapper objectMapper;

  public CuratedPlaceSearchProvider(ExternalPlaceRepository repository, ObjectMapper objectMapper) {
    this.repository = repository;
    this.objectMapper = objectMapper;
  }

  @Override
  public String provider() {
    return API_PROVIDER;
  }

  @Override
  public boolean isAvailable() {
    return true;
  }

  @Override
  public List<PlaceSearchResult> search(PlaceSearchQuery query) {
    CatalogBucket bucket = CatalogBucket.from(query);
    if (bucket == CatalogBucket.UNKNOWN) {
      return List.of();
    }
    List<String> meaningfulTokens = meaningfulTokens(query, bucket);
    return repository.findByProviderAndCategoryInAndLatitudeIsNotNullAndLongitudeIsNotNull(
        STORED_PROVIDER,
        bucket.categories()
      ).stream()
      .map(place -> Candidate.from(place, parsePayload(place.getProviderPayload()), query))
      .filter(candidate -> candidate.matchesBucket(bucket, query))
      .filter(candidate -> candidate.matchesTokens(meaningfulTokens))
      .filter(Candidate::withinRadius)
      .sorted()
      .limit(RESULT_LIMIT)
      .map(Candidate::toResult)
      .toList();
  }

  private JsonNode parsePayload(String providerPayload) {
    if (providerPayload == null || providerPayload.isBlank()) {
      return objectMapper.createObjectNode();
    }
    try {
      return objectMapper.readTree(providerPayload);
    } catch (Exception exception) {
      return objectMapper.createObjectNode();
    }
  }

  private static List<String> meaningfulTokens(PlaceSearchQuery query, CatalogBucket bucket) {
    Set<String> removable = new LinkedHashSet<>();
    removable.add(query.normalizedCategory());
    removable.addAll(bucket.filterTokens());
    removable.addAll(FOOD_TOKENS);
    removable.addAll(CAFE_TOKENS);
    removable.addAll(ATTRACTION_TOKENS);
    String value = query.normalizedQuery();
    for (String token : removable) {
      if (token == null || token.isBlank()) {
        continue;
      }
      value = value.replace(token, " ");
    }
    String[] parts = value.replaceAll("[^\\p{IsHangul}\\p{IsAlphabetic}\\p{IsDigit}\\s]", " ").split("\\s+");
    List<String> tokens = new ArrayList<>();
    for (String part : parts) {
      String trimmed = part.trim();
      if (!trimmed.isBlank() && !isRemovableTokenPart(trimmed, removable)) {
        tokens.add(trimmed);
      }
    }
    return tokens;
  }

  private static boolean isRemovableTokenPart(String part, Set<String> removableTokens) {
    String normalizedPart = normalize(part);
    if (normalizedPart.isBlank()) {
      return true;
    }
    for (String token : removableTokens) {
      String normalizedToken = normalize(token);
      if (normalizedToken.isBlank()) {
        continue;
      }
      if (normalizedPart.equals(normalizedToken) || normalizedToken.contains(normalizedPart)) {
        return true;
      }
    }
    return false;
  }

  private static boolean containsAny(String source, List<String> tokens) {
    String normalizedSource = normalize(source);
    return tokens.stream().anyMatch(token -> normalizedSource.contains(normalize(token)));
  }

  private static boolean containsAll(String source, List<String> tokens) {
    if (tokens.isEmpty()) {
      return true;
    }
    String normalizedSource = normalize(source);
    return tokens.stream().allMatch(token -> normalizedSource.contains(normalize(token)));
  }

  private static boolean isBroadCategory(PlaceSearchQuery query, CatalogBucket bucket) {
    String category = normalize(query.normalizedCategory());
    return bucket.broadTokens().stream().anyMatch(token -> category.equals(normalize(token)));
  }

  private static String normalize(String value) {
    return value == null ? "" : value.toLowerCase(Locale.ROOT).replaceAll("\\s+", "");
  }

  private enum CatalogBucket {
    FOOD(FOOD_CATEGORIES, FOOD_TOKENS, BROAD_FOOD_TOKENS),
    CAFE(FOOD_CATEGORIES, CAFE_TOKENS, BROAD_CAFE_TOKENS),
    ATTRACTION(ATTRACTION_CATEGORIES, ATTRACTION_TOKENS, BROAD_ATTRACTION_TOKENS),
    UNKNOWN(List.of(), List.of(), List.of());

    private final List<String> categories;
    private final List<String> filterTokens;
    private final List<String> broadTokens;

    CatalogBucket(List<String> categories, List<String> filterTokens, List<String> broadTokens) {
      this.categories = categories;
      this.filterTokens = filterTokens;
      this.broadTokens = broadTokens;
    }

    private List<String> categories() {
      return categories;
    }

    private List<String> filterTokens() {
      return filterTokens;
    }

    private List<String> broadTokens() {
      return broadTokens;
    }

    private static CatalogBucket from(PlaceSearchQuery query) {
      String category = query.normalizedCategory();
      String combined = category + " " + query.normalizedQuery();
      if (containsAny(combined, CAFE_TOKENS) || List.of("cafe").contains(normalize(category))) {
        return CAFE;
      }
      if (containsAny(combined, ATTRACTION_TOKENS) || List.of("attraction").contains(normalize(category))) {
        return ATTRACTION;
      }
      if (containsAny(combined, FOOD_TOKENS) || List.of("food", "restaurant").contains(normalize(category))) {
        return FOOD;
      }
      return UNKNOWN;
    }
  }

  private record Candidate(
    ExternalPlaceEntity place,
    JsonNode payload,
    String searchText,
    Double distanceMeters,
    Integer radiusMeters,
    boolean categorySpecificMatch,
    boolean nameMatch
  ) implements Comparable<Candidate> {
    private static Candidate from(ExternalPlaceEntity place, JsonNode payload, PlaceSearchQuery query) {
      String searchText = String.join(" ",
        nullToBlank(place.getName()),
        nullToBlank(place.getCategory()),
        nullToBlank(place.getAddress()),
        nullToBlank(place.getRoadAddress()),
        payloadText(payload)
      );
      Double distanceMeters = distanceMeters(query, place);
      List<String> queryTokens = meaningfulTokens(query, CatalogBucket.from(query));
      boolean nameMatch = containsAny(place.getName(), queryTokens);
      boolean categorySpecificMatch = containsAny(searchText, List.of(query.normalizedCategory()));
      return new Candidate(place, payload, searchText, distanceMeters, query.radius(), categorySpecificMatch, nameMatch);
    }

    private boolean matchesBucket(CatalogBucket bucket, PlaceSearchQuery query) {
      if (bucket == CatalogBucket.CAFE) {
        return containsAny(searchText, CAFE_TOKENS);
      }
      if (bucket == CatalogBucket.ATTRACTION && !isBroadCategory(query, bucket)) {
        return containsAny(searchText, List.of(query.normalizedCategory()));
      }
      if (bucket == CatalogBucket.FOOD && !isBroadCategory(query, bucket)) {
        return containsAny(searchText, List.of(query.normalizedCategory()));
      }
      return true;
    }

    private boolean matchesTokens(List<String> tokens) {
      return containsAll(searchText, tokens);
    }

    private boolean withinRadius() {
      return distanceMeters == null || radiusMeters == null || radiusMeters <= 0 || distanceMeters <= radiusMeters;
    }

    private PlaceSearchResult toResult() {
      return new PlaceSearchResult(
        API_PROVIDER,
        place.getProviderPlaceId(),
        place.getName(),
        place.getCategory(),
        place.getAddress(),
        place.getRoadAddress(),
        place.getLatitude(),
        place.getLongitude(),
        place.getHomepageUrl(),
        Instant.now()
      );
    }

    @Override
    public int compareTo(Candidate other) {
      return Comparator
        .comparing(Candidate::distanceSort)
        .thenComparing(candidate -> !candidate.categorySpecificMatch)
        .thenComparing(candidate -> !candidate.nameMatch)
        .thenComparing(candidate -> candidate.place.getName(), Comparator.nullsLast(String::compareTo))
        .thenComparing(candidate -> candidate.place.getProviderPlaceId(), Comparator.nullsLast(String::compareTo))
        .compare(this, other);
    }

    private double distanceSort() {
      return distanceMeters == null ? Double.MAX_VALUE : distanceMeters;
    }

    private static Double distanceMeters(PlaceSearchQuery query, ExternalPlaceEntity place) {
      if (query.lat() == null || query.lng() == null || place.getLatitude() == null || place.getLongitude() == null) {
        return null;
      }
      double lat1 = Math.toRadians(query.lat());
      double lat2 = Math.toRadians(place.getLatitude());
      double deltaLat = Math.toRadians(place.getLatitude() - query.lat());
      double deltaLng = Math.toRadians(place.getLongitude() - query.lng());
      double a = Math.sin(deltaLat / 2) * Math.sin(deltaLat / 2)
        + Math.cos(lat1) * Math.cos(lat2) * Math.sin(deltaLng / 2) * Math.sin(deltaLng / 2);
      double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
      return EARTH_RADIUS_METERS * c;
    }

    private static String payloadText(JsonNode payload) {
      List<String> parts = new ArrayList<>();
      addText(parts, payload, "region");
      addText(parts, payload, "summary");
      addText(parts, payload, "sourceProject");
      addArrayText(parts, payload, "tags");
      addArrayText(parts, payload, "purposeTags");
      addArrayText(parts, payload, "preferenceTags");
      addArrayText(parts, payload, "reasons");
      return String.join(" ", parts);
    }

    private static void addText(List<String> parts, JsonNode payload, String field) {
      JsonNode value = payload.get(field);
      if (value != null && value.isTextual()) {
        parts.add(value.asText());
      }
    }

    private static void addArrayText(List<String> parts, JsonNode payload, String field) {
      JsonNode values = payload.get(field);
      if (values == null || !values.isArray()) {
        return;
      }
      values.forEach(value -> {
        if (value.isTextual()) {
          parts.add(value.asText());
        }
      });
    }

    private static String nullToBlank(String value) {
      return value == null ? "" : value;
    }
  }
}
