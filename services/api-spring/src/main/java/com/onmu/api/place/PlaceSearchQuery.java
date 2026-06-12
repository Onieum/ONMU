package com.onmu.api.place;

import java.util.List;
import java.util.Locale;

public record PlaceSearchQuery(
  String query,
  String groupId,
  String planId,
  Double lat,
  Double lng,
  Integer radius,
  String category,
  List<String> providers,
  boolean compare
) {
  public PlaceSearchQuery {
    providers = providers == null ? List.of() : providers.stream()
      .filter(value -> value != null && !value.isBlank())
      .map(value -> value.trim().toLowerCase(Locale.ROOT))
      .distinct()
      .toList();
  }

  public String normalizedQuery() {
    return query == null || query.isBlank() ? "장소" : query.trim();
  }

  public String normalizedCategory() {
    if (category != null && !category.isBlank()) {
      return category.trim();
    }
    return normalizedQuery().toLowerCase(Locale.ROOT).contains("카페") ? "cafe" : "place";
  }
}
