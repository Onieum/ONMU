package com.onmu.api.route;

import java.util.LinkedHashMap;
import java.util.Map;

public record RouteStop(
  String id,
  String name,
  Double latitude,
  Double longitude,
  int order
) {
  public Map<String, Object> toApiMap() {
    Map<String, Object> value = new LinkedHashMap<>();
    value.put("id", id);
    value.put("name", name);
    value.put("lat", latitude);
    value.put("lng", longitude);
    value.put("latitude", latitude);
    value.put("longitude", longitude);
    value.put("order", order);
    return value;
  }
}
