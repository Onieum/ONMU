package com.onmu.api.route;

import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.time.Instant;
import java.util.List;
import org.junit.jupiter.api.Test;

class OpenRouteServiceMapperTests {
  private final OpenRouteServiceMapper mapper = new OpenRouteServiceMapper(new ObjectMapper());

  @Test
  void mapsSyntheticGeoJsonResponse() {
    String json = """
      {
        "features": [
          {
            "geometry": {
              "type": "LineString",
              "coordinates": [[126.978, 37.5665], [126.9895, 37.5651]]
            },
            "properties": {
              "summary": {
                "distance": 1234.5,
                "duration": 456.7
              },
              "segments": [
                {
                  "distance": 1234.5,
                  "duration": 456.7
                }
              ]
            }
          }
        ]
      }
      """;
    List<RouteStop> stops = List.of(
      new RouteStop("1", "Start", 37.5665, 126.978, 1),
      new RouteStop("2", "End", 37.5651, 126.9895, 2)
    );

    RouteRecommendation route = mapper.map(json, stops, RouteTravelMode.WALK, Instant.parse("2026-06-10T00:00:00Z"));

    assertThat(route.provider()).isEqualTo("openrouteservice");
    assertThat(route.geometry()).containsExactly(
      new RouteGeometryPoint(126.978, 37.5665),
      new RouteGeometryPoint(126.9895, 37.5651)
    );
    assertThat(route.distanceMeters()).isEqualTo(1234.5);
    assertThat(route.durationSeconds()).isEqualTo(456.7);
    assertThat(route.travelMode()).isEqualTo(RouteTravelMode.WALK);
    assertThat(route.legs()).hasSize(1);
    assertThat(route.legs().getFirst().fromName()).isEqualTo("Start");
    assertThat(route.legs().getFirst().toName()).isEqualTo("End");
    assertThat(route.legs().getFirst().distanceMeters()).isEqualTo(1234.5);
    assertThat(route.legs().getFirst().durationSeconds()).isEqualTo(456.7);
  }
}
