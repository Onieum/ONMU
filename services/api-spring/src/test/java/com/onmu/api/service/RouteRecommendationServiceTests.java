package com.onmu.api.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.onmu.api.domain.GroupEntity;
import com.onmu.api.domain.GroupRepository;
import com.onmu.api.domain.PlaceCandidateEntity;
import com.onmu.api.domain.PlaceCandidateRepository;
import com.onmu.api.domain.PlanEntity;
import com.onmu.api.domain.PlanRepository;
import com.onmu.api.route.DevMockRouteProvider;
import com.onmu.api.route.OpenRouteServiceMapper;
import com.onmu.api.route.OpenRouteServiceProvider;
import com.onmu.api.route.RouteHttpClient;
import com.onmu.api.route.RouteRecommendationCache;
import java.net.URI;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class RouteRecommendationServiceTests {
  @Mock
  private GroupRepository groupRepository;
  @Mock
  private PlanRepository planRepository;
  @Mock
  private PlaceCandidateRepository placeCandidateRepository;

  private final ObjectMapper objectMapper = new ObjectMapper();
  private GroupEntity group;
  private PlanEntity plan;

  @BeforeEach
  void setUp() {
    group = new GroupEntity("1", "ONMU", null);
    plan = new PlanEntity("101", group, "Route plan", Instant.parse("2026-06-10T00:00:00Z"), "draft");
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(planRepository.findByGroupAndPublicId(group, "101")).thenReturn(Optional.of(plan));
  }

  @Test
  void returnsDevMockRouteForCarWalkBikeWhenOpenRouteServiceKeyIsMissing() {
    when(placeCandidateRepository.findByPlanOrderByCreatedAtAsc(plan)).thenReturn(candidatesWithCoordinates());
    RouteRecommendationService service = serviceWith("", new FakeRouteHttpClient());

    for (String mode : List.of("car", "walk", "bike")) {
      Map<String, Object> route = service.recommend("1", "101", mode);

      assertThat(route)
        .containsEntry("provider", "dev-mock")
        .containsEntry("travelMode", mode);
      assertThat((List<?>) route.get("stops")).hasSize(2);
      assertThat((List<?>) route.get("geometry")).hasSize(2);
      assertThat((Number) route.get("distanceMeters")).isNotNull();
      assertThat((Number) route.get("durationSeconds")).isNotNull();
    }
  }

  @Test
  void usesOpenRouteServiceWhenKeyAndCandidateCoordinatesAreAvailable() {
    FakeRouteHttpClient httpClient = new FakeRouteHttpClient();
    when(placeCandidateRepository.findByPlanOrderByCreatedAtAsc(plan)).thenReturn(candidatesWithCoordinates());
    RouteRecommendationService service = serviceWith("test-ors-key", httpClient);

    Map<String, Object> route = service.recommend("1", "101", "walk");

    assertThat(route)
      .containsEntry("provider", "openrouteservice")
      .containsEntry("travelMode", "walk")
      .containsEntry("distanceMeters", 1500L)
      .containsEntry("durationSeconds", 600L);
    assertThat(httpClient.lastUri.toString()).contains("/v2/directions/foot-walking/geojson");
    assertThat(httpClient.lastBody.toString()).contains("126.978");
  }

  @Test
  void fallsBackToDevMockWhenCandidateCoordinatesAreMissing() {
    when(placeCandidateRepository.findByPlanOrderByCreatedAtAsc(plan)).thenReturn(List.of(
      new PlaceCandidateEntity("201", group, plan, "No coordinate", "cafe", "Seoul", "{}")
    ));
    RouteRecommendationService service = serviceWith("test-ors-key", new FakeRouteHttpClient());

    Map<String, Object> route = service.recommend("1", "101", "bike");

    assertThat(route)
      .containsEntry("provider", "dev-mock")
      .containsEntry("travelMode", "bike");
    assertThat((List<?>) route.get("stops")).hasSizeGreaterThanOrEqualTo(2);
  }

  private RouteRecommendationService serviceWith(String apiKey, RouteHttpClient httpClient) {
    return new RouteRecommendationService(
      groupRepository,
      planRepository,
      placeCandidateRepository,
      new OpenRouteServiceProvider(
        httpClient,
        new OpenRouteServiceMapper(objectMapper),
        apiKey,
        "https://routes.example.test"
      ),
      new DevMockRouteProvider(),
      new NoopRouteCache(),
      objectMapper
    );
  }

  private List<PlaceCandidateEntity> candidatesWithCoordinates() {
    return List.of(
      new PlaceCandidateEntity("201", group, plan, "Start", "cafe", "Seoul", "{\"lat\":37.5665,\"lng\":126.978}"),
      new PlaceCandidateEntity("202", group, plan, "End", "park", "Seoul", "{\"lat\":37.5651,\"lng\":126.9895}")
    );
  }

  private static final class FakeRouteHttpClient implements RouteHttpClient {
    private URI lastUri;
    private Map<String, Object> lastBody;

    @Override
    public String post(URI uri, Map<String, String> headers, Map<String, Object> body) {
      this.lastUri = uri;
      this.lastBody = body;
      return """
        {
          "features": [
            {
              "geometry": {
                "type": "LineString",
                "coordinates": [[126.978, 37.5665], [126.9895, 37.5651]]
              },
              "properties": {
                "summary": {
                  "distance": 1500,
                  "duration": 600
                }
              }
            }
          ]
        }
        """;
    }
  }

  private static final class NoopRouteCache implements RouteRecommendationCache {
    @Override
    public Optional<Map<String, Object>> get(String key) {
      return Optional.empty();
    }

    @Override
    public void put(String key, Map<String, Object> route) {
    }
  }
}
