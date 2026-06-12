package com.onmu.api.route;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import org.springframework.stereotype.Component;

@Component
public class DevMockRouteProvider implements RouteProvider {
  @Override
  public String provider() {
    return "dev-mock";
  }

  @Override
  public boolean isAvailable() {
    return true;
  }

  @Override
  public RouteRecommendation recommend(List<RouteStop> stops, RouteTravelMode travelMode) {
    List<RouteStop> safeStops = stops.size() >= 2 ? stops : fallbackStops(stops);
    List<RouteGeometryPoint> geometry = safeStops.stream()
      .map(stop -> new RouteGeometryPoint(stop.longitude(), stop.latitude()))
      .toList();
    double distanceMeters = distanceMeters(geometry);
    return new RouteRecommendation(
      provider(),
      safeStops,
      geometry,
      distanceMeters,
      distanceMeters / travelMode.fallbackMetersPerSecond(),
      travelMode,
      Instant.now()
    );
  }

  private List<RouteStop> fallbackStops(List<RouteStop> stops) {
    List<RouteStop> values = new ArrayList<>(stops);
    if (values.isEmpty()) {
      values.add(new RouteStop("dev-stop-1", "ONMU Dev Start", 37.5665, 126.9780, 1));
    }
    values.add(new RouteStop("dev-stop-2", "ONMU Dev Cafe", 37.5651, 126.9895, values.size() + 1));
    if (values.size() < 3) {
      values.add(new RouteStop("dev-stop-3", "ONMU Dev Park", 37.5326, 126.9904, values.size() + 1));
    }
    return values;
  }

  private double distanceMeters(List<RouteGeometryPoint> geometry) {
    double total = 0;
    for (int index = 1; index < geometry.size(); index += 1) {
      total += haversine(geometry.get(index - 1), geometry.get(index));
    }
    return total;
  }

  private double haversine(RouteGeometryPoint from, RouteGeometryPoint to) {
    double radiusMeters = 6371000;
    double lat1 = Math.toRadians(from.lat());
    double lat2 = Math.toRadians(to.lat());
    double deltaLat = Math.toRadians(to.lat() - from.lat());
    double deltaLng = Math.toRadians(to.lng() - from.lng());
    double a = Math.sin(deltaLat / 2) * Math.sin(deltaLat / 2)
      + Math.cos(lat1) * Math.cos(lat2) * Math.sin(deltaLng / 2) * Math.sin(deltaLng / 2);
    return radiusMeters * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  }
}
