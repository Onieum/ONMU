package com.onmu.api.place;

import java.time.Instant;
import java.util.List;
import org.springframework.stereotype.Component;

@Component
public class DevMockPlaceSearchProvider implements PlaceSearchProvider {
  @Override
  public String provider() {
    return "dev-mock";
  }

  @Override
  public boolean isAvailable() {
    return true;
  }

  @Override
  public List<PlaceSearchResult> search(PlaceSearchQuery query) {
    String normalizedQuery = query.normalizedQuery();
    String category = query.normalizedCategory();
    Instant fetchedAt = Instant.now();
    return List.of(
      new PlaceSearchResult("dev-mock", "mock-place-1", "%s 후보 A".formatted(normalizedQuery), category, "서울 종로구", null, 37.5665, 126.9780, null, fetchedAt),
      new PlaceSearchResult("dev-mock", "mock-place-2", "%s 후보 B".formatted(normalizedQuery), category, "서울 중구", null, 37.5651, 126.9895, null, fetchedAt),
      new PlaceSearchResult("dev-mock", "mock-place-3", "%s 후보 C".formatted(normalizedQuery), category, "서울 용산구", null, 37.5326, 126.9904, null, fetchedAt)
    );
  }
}
