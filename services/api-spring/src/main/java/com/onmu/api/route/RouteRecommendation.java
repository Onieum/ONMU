package com.onmu.api.route;

import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public record RouteRecommendation(
  String provider,
  List<RouteStop> stops,
  List<RouteGeometryPoint> geometry,
  List<RouteLeg> legs,
  double distanceMeters,
  double durationSeconds,
  RouteTravelMode travelMode,
  Instant fetchedAt
) {
  public RouteRecommendation(
    String provider,
    List<RouteStop> stops,
    List<RouteGeometryPoint> geometry,
    double distanceMeters,
    double durationSeconds,
    RouteTravelMode travelMode,
    Instant fetchedAt
  ) {
    this(provider, stops, geometry, List.of(), distanceMeters, durationSeconds, travelMode, fetchedAt);
  }

  public Map<String, Object> toApiMap() {
    Map<String, Object> value = new LinkedHashMap<>();
    value.put("provider", provider);
    value.put("stops", stops.stream().map(RouteStop::toApiMap).toList());
    value.put("geometry", geometry.stream().map(RouteGeometryPoint::toLngLat).toList());
    value.put("legs", routeLegs().stream().map(RouteLeg::toApiMap).toList());
    value.put("distanceMeters", Math.round(distanceMeters));
    value.put("durationSeconds", Math.round(durationSeconds));
    value.put("travelMode", travelMode.apiValue());
    value.put("fetchedAt", fetchedAt.toString());
    return value;
  }

  private List<RouteLeg> routeLegs() {
    if (!legs.isEmpty()) {
      return legs;
    }
    if (stops.size() < 2) {
      return List.of();
    }
    java.util.ArrayList<RouteLeg> value = new java.util.ArrayList<>();
    for (var index = 0; index < stops.size() - 1; index += 1) {
      RouteStop from = stops.get(index);
      RouteStop to = stops.get(index + 1);
      value.add(new RouteLeg(index + 1, from.id(), to.id(), from.name(), to.name(), null, null));
    }
    return value;
  }
}
