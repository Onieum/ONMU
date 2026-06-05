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
    String normalizedQuery = query == null || query.isBlank() ? "장소" : query.trim();
    String category = normalizedQuery.toLowerCase(Locale.ROOT).contains("카페") ? "cafe" : "place";

    List<Map<String, Object>> results = new ArrayList<>();
    results.add(place("mock-place-1", "%s 후보 A".formatted(normalizedQuery), category, "서울 종로구", true, 3));
    results.add(place("mock-place-2", "%s 후보 B".formatted(normalizedQuery), category, "서울 중구", false, 1));
    results.add(place("mock-place-3", "%s 후보 C".formatted(normalizedQuery), category, "서울 용산구", false, 0));

    Map<String, Object> context = new LinkedHashMap<>();
    context.put("groupId", groupId);
    context.put("planId", planId);
    context.put("source", "dev-mock");
    results.forEach(result -> result.put("context", context));
    return results;
  }

  private Map<String, Object> place(
    String id,
    String name,
    String category,
    String address,
    boolean likedByMe,
    int heartCount
  ) {
    Map<String, Object> value = new LinkedHashMap<>();
    value.put("id", id);
    value.put("name", name);
    value.put("category", category);
    value.put("address", address);
    value.put("likedByMe", likedByMe);
    value.put("heartCount", heartCount);
    value.put("canAddCandidate", true);
    return value;
  }
}
