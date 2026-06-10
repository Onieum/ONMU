package com.onmu.api.service;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import org.springframework.stereotype.Service;

@Service
public class PlaceSearchService {
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
    String normalizedQuery = query == null || query.isBlank() ? "장소" : query.trim();
    String category = requestedCategory == null || requestedCategory.isBlank()
      ? normalizedQuery.toLowerCase(Locale.ROOT).contains("카페") ? "cafe" : "place"
      : requestedCategory.trim();

    List<Map<String, Object>> results = new ArrayList<>();
    results.add(place("mock-place-1", "%s 후보 A".formatted(normalizedQuery), category, "서울 종로구", false, 3, 37.5665, 126.9780));
    results.add(place("mock-place-2", "%s 후보 B".formatted(normalizedQuery), category, "서울 중구", false, 1, 37.5651, 126.9895));
    results.add(place("mock-place-3", "%s 후보 C".formatted(normalizedQuery), category, "서울 용산구", false, 0, 37.5326, 126.9904));

    Map<String, Object> context = new LinkedHashMap<>();
    context.put("groupId", groupId);
    context.put("planId", planId);
    context.put("lat", lat);
    context.put("lng", lng);
    context.put("radius", radius);
    context.put("category", category);
    context.put("source", "dev-mock");
    results.forEach(result -> result.put("context", context));
    return results;
  }

  private Map<String, Object> place(
    String id,
    String name,
    String category,
    String address,
    boolean myHearted,
    int heartCount,
    double lat,
    double lng
  ) {
    Map<String, Object> value = new LinkedHashMap<>();
    value.put("id", id);
    value.put("name", name);
    value.put("category", category);
    value.put("address", address);
    value.put("source", "dev-mock");
    value.put("lat", lat);
    value.put("lng", lng);
    value.put("likedByMe", myHearted);
    value.put("myHearted", myHearted);
    value.put("heartCount", heartCount);
    value.put("canAddCandidate", true);
    return value;
  }
}
