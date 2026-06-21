package com.onmu.api.place;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;

public class PlaceRecommendationReasoner {
  private static final String VERSION = "rule-v1";

  public Map<String, Object> explainSearchResult(
    PlaceSearchResult result,
    PlaceSearchQuery query,
    int rank
  ) {
    List<String> reasons = reasons(result, query, rank);
    Map<String, Object> value = new LinkedHashMap<>();
    value.put("summary", summary(result, query));
    value.put("tags", tags(result, query));
    value.put("reasons", reasons);
    value.put("distanceLabel", distanceLabel(result, query));
    value.put("travelTimeLabel", "");
    value.put("priceLabel", "");
    value.put("openingLabel", "");
    value.put("recommendation", Map.of(
      "version", VERSION,
      "status", "ready",
      "reasonSource", "rule_based",
      "reasonCount", reasons.size(),
      "aiStatus", "not_requested"
    ));
    return value;
  }

  private String summary(PlaceSearchResult result, PlaceSearchQuery query) {
    String category = category(result, query);
    if (hasCoordinate(result) && hasSearchCenter(query)) {
      return "현 지도 기준으로 비교할 수 있는 " + category + " 후보입니다.";
    }
    return "일정 후보로 저장해 비교할 수 있는 " + category + " 장소입니다.";
  }

  private List<String> reasons(PlaceSearchResult result, PlaceSearchQuery query, int rank) {
    List<String> values = new ArrayList<>();
    String category = category(result, query);
    if (matchesCategory(result, query)) {
      values.add(category + " 필터와 잘 맞아요.");
    }
    String distance = distanceLabel(result, query);
    if (!distance.isBlank()) {
      values.add("현 지도 중심에서 " + distance + " 안팎으로 비교할 수 있어요.");
    }
    if (hasAddress(result)) {
      values.add("주소 정보가 있어 일정 장소로 저장하기 좋아요.");
    }
    if (rank <= 3) {
      values.add("현재 검색 조건에서 우선 확인할 만한 후보예요.");
    }
    if (result.sourceUrl() != null && !result.sourceUrl().isBlank()) {
      values.add("방문 전 상세 정보를 더 확인할 수 있어요.");
    }
    if (values.isEmpty()) {
      values.add("일정 후보로 저장해 팀원들과 비교할 수 있어요.");
    }
    return values.stream().distinct().limit(3).toList();
  }

  private List<String> tags(PlaceSearchResult result, PlaceSearchQuery query) {
    LinkedHashSet<String> values = new LinkedHashSet<>();
    addCategoryTokens(values, result.category());
    addCategoryTokens(values, query.category());
    if (hasCoordinate(result)) {
      values.add("지도 후보");
    }
    if (hasAddress(result)) {
      values.add("주소 확인");
    }
    return values.stream()
      .filter(value -> !value.isBlank())
      .limit(4)
      .toList();
  }

  private void addCategoryTokens(LinkedHashSet<String> values, String category) {
    if (category == null || category.isBlank()) {
      return;
    }
    String[] tokens = category.split("[>,/|]");
    for (String token : tokens) {
      String trimmed = token.trim();
      if (!trimmed.isBlank()) {
        values.add(trimmed);
      }
    }
  }

  private String category(PlaceSearchResult result, PlaceSearchQuery query) {
    if (result.category() != null && !result.category().isBlank()) {
      return result.category().trim().split("[>,/|]")[0].trim();
    }
    if (query.category() != null && !query.category().isBlank()) {
      return query.category().trim();
    }
    return "장소";
  }

  private boolean matchesCategory(PlaceSearchResult result, PlaceSearchQuery query) {
    String requested = normalize(query.category());
    if (requested.isBlank()) {
      return false;
    }
    return normalize(result.category()).contains(requested) || normalize(query.normalizedQuery()).contains(requested);
  }

  private boolean hasCoordinate(PlaceSearchResult result) {
    return result.latitude() != null && result.longitude() != null;
  }

  private boolean hasSearchCenter(PlaceSearchQuery query) {
    return query.lat() != null && query.lng() != null;
  }

  private boolean hasAddress(PlaceSearchResult result) {
    return (result.roadAddress() != null && !result.roadAddress().isBlank())
      || (result.address() != null && !result.address().isBlank());
  }

  private String distanceLabel(PlaceSearchResult result, PlaceSearchQuery query) {
    if (!hasCoordinate(result) || !hasSearchCenter(query)) {
      return "";
    }
    double distanceMeters = haversineMeters(query.lat(), query.lng(), result.latitude(), result.longitude());
    if (!Double.isFinite(distanceMeters) || distanceMeters < 0) {
      return "";
    }
    if (distanceMeters < 1000) {
      int rounded = Math.max(10, (int) Math.round(distanceMeters / 10.0) * 10);
      return "약 " + rounded + "m";
    }
    double kilometers = distanceMeters / 1000.0;
    return String.format(Locale.KOREA, "약 %.1fkm", kilometers);
  }

  private double haversineMeters(double startLat, double startLng, double endLat, double endLng) {
    double earthRadiusMeters = 6_371_000;
    double startLatRad = Math.toRadians(startLat);
    double endLatRad = Math.toRadians(endLat);
    double deltaLat = Math.toRadians(endLat - startLat);
    double deltaLng = Math.toRadians(endLng - startLng);
    double a = Math.sin(deltaLat / 2) * Math.sin(deltaLat / 2)
      + Math.cos(startLatRad) * Math.cos(endLatRad)
      * Math.sin(deltaLng / 2) * Math.sin(deltaLng / 2);
    double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  private String normalize(String value) {
    return value == null ? "" : value.toLowerCase(Locale.ROOT).replaceAll("\\s+", "");
  }
}
