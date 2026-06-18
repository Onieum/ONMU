package com.onmu.api.route;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import org.springframework.stereotype.Component;

@Component
public class OpenRouteServiceMapper {
  private final ObjectMapper objectMapper;

  public OpenRouteServiceMapper(ObjectMapper objectMapper) {
    this.objectMapper = objectMapper;
  }

  public RouteRecommendation map(String json, List<RouteStop> stops, RouteTravelMode travelMode, Instant fetchedAt) {
    try {
      JsonNode root = objectMapper.readTree(json);
      JsonNode feature = root.path("features").path(0);
      JsonNode coordinates = feature.path("geometry").path("coordinates");
      if (!coordinates.isArray() || coordinates.isEmpty()) {
        throw new IllegalArgumentException("missing_geometry");
      }

      List<RouteGeometryPoint> geometry = new ArrayList<>();
      for (JsonNode coordinate : coordinates) {
        if (coordinate.isArray() && coordinate.size() >= 2) {
          geometry.add(new RouteGeometryPoint(coordinate.path(0).asDouble(), coordinate.path(1).asDouble()));
        }
      }

      JsonNode summary = feature.path("properties").path("summary");
      List<RouteLeg> legs = routeLegs(feature.path("properties").path("segments"), stops);
      return new RouteRecommendation(
        "openrouteservice",
        stops,
        geometry,
        legs,
        summary.path("distance").asDouble(0),
        summary.path("duration").asDouble(0),
        travelMode,
        fetchedAt
      );
    } catch (RuntimeException | java.io.IOException exception) {
      throw new IllegalArgumentException("invalid_openrouteservice_response", exception);
    }
  }

  private List<RouteLeg> routeLegs(JsonNode segments, List<RouteStop> stops) {
    if (!segments.isArray() || stops.size() < 2) {
      return List.of();
    }
    List<RouteLeg> legs = new ArrayList<>();
    int count = Math.min(segments.size(), stops.size() - 1);
    for (int index = 0; index < count; index += 1) {
      JsonNode segment = segments.path(index);
      RouteStop from = stops.get(index);
      RouteStop to = stops.get(index + 1);
      legs.add(new RouteLeg(
        index + 1,
        from.id(),
        to.id(),
        from.name(),
        to.name(),
        segment.path("distance").isMissingNode() ? null : segment.path("distance").asDouble(),
        segment.path("duration").isMissingNode() ? null : segment.path("duration").asDouble()
      ));
    }
    return legs;
  }
}
