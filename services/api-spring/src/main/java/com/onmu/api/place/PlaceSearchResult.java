package com.onmu.api.place;

import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;

public record PlaceSearchResult(
  String provider,
  String providerPlaceId,
  String name,
  String category,
  String address,
  String roadAddress,
  Double latitude,
  Double longitude,
  String sourceUrl,
  Instant fetchedAt
) {
  public Map<String, Object> toApiMap(Map<String, Object> context) {
    Map<String, Object> value = new LinkedHashMap<>();
    value.put("id", provider + ":" + providerPlaceId);
    value.put("provider", provider);
    value.put("providerPlaceId", providerPlaceId);
    value.put("name", name);
    value.put("category", category);
    value.put("address", address);
    value.put("roadAddress", roadAddress);
    value.put("source", provider);
    value.put("sourceUrl", sourceUrl);
    value.put("providerLink", sourceUrl);
    value.put("lat", latitude);
    value.put("lng", longitude);
    value.put("latitude", latitude);
    value.put("longitude", longitude);
    value.put("fetchedAt", fetchedAt == null ? null : fetchedAt.toString());
    value.put("likedByMe", false);
    value.put("myHearted", false);
    value.put("heartCount", 0);
    value.put("canAddCandidate", true);
    value.put("context", context);
    return value;
  }
}
