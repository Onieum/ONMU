package com.onmu.api.route;

import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public record RouteRecommendation(
  String provider,
  List<RouteStop> stops,
  List<RouteGeometryPoint> geometry,
  double distanceMeters,
  double durationSeconds,
  RouteTravelMode travelMode,
  Instant fetchedAt
) {
  public Map<String, Object> toApiMap() {
    Map<String, Object> value = new LinkedHashMap<>();
    value.put("provider", provider);
    value.put("stops", stops.stream().map(RouteStop::toApiMap).toList());
    value.put("geometry", geometry.stream().map(RouteGeometryPoint::toLngLat).toList());
    value.put("distanceMeters", Math.round(distanceMeters));
    value.put("durationSeconds", Math.round(durationSeconds));
    value.put("travelMode", travelMode.apiValue());
    value.put("fetchedAt", fetchedAt.toString());
    return value;
  }
}
