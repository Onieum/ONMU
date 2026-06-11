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
      return new RouteRecommendation(
        "openrouteservice",
        stops,
        geometry,
        summary.path("distance").asDouble(0),
        summary.path("duration").asDouble(0),
        travelMode,
        fetchedAt
      );
    } catch (RuntimeException | java.io.IOException exception) {
      throw new IllegalArgumentException("invalid_openrouteservice_response", exception);
    }
  }
}
