package com.onmu.api.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.onmu.api.domain.GroupEntity;
import com.onmu.api.domain.GroupRepository;
import com.onmu.api.domain.PlaceCandidateEntity;
import com.onmu.api.domain.PlaceCandidateRepository;
import com.onmu.api.domain.PlanEntity;
import com.onmu.api.domain.PlanRepository;
import com.onmu.api.domain.SchedulePlaceEntity;
import com.onmu.api.domain.SchedulePlaceRepository;
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
  @Mock
  private SchedulePlaceRepository schedulePlaceRepository;

  private final ObjectMapper objectMapper = new ObjectMapper();
  private GroupEntity group;
  private PlanEntity plan;

  @BeforeEach
  void setUp() {
    group = new GroupEntity("1", "ONMU", null);
    plan = new PlanEntity("101", group, "Route plan", Instant.parse("2026-06-10T00:00:00Z"), "draft");
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(planRepository.findByGroupAndPublicId(group, "101")).thenReturn(Optional.of(plan));
    when(schedulePlaceRepository.findByPlanOrderBySortOrderAsc(plan)).thenReturn(List.of());
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
    assertThat(httpClient.lastHeaders).containsEntry("Accept", "application/geo+json");
    assertThat(httpClient.lastBody.toString()).contains("126.978");
  }

  @Test
  void prefersSchedulePlacesOverCandidatePoolForRouteStops() {
    PlaceCandidateEntity scheduledCandidate = new PlaceCandidateEntity(
      "301",
      group,
      plan,
      "Scheduled cafe",
      "cafe",
      "Seoul",
      "{\"lat\":37.5,\"lng\":127.0}"
    );
    PlaceCandidateEntity secondScheduledCandidate = new PlaceCandidateEntity(
      "302",
      group,
      plan,
      "Scheduled park",
      "park",
      "Seoul",
      "{\"lat\":37.6,\"lng\":127.1}"
    );
    when(schedulePlaceRepository.findByPlanOrderBySortOrderAsc(plan)).thenReturn(List.of(
      new SchedulePlaceEntity("701", group, plan, scheduledCandidate, "Scheduled cafe", null, 1),
      new SchedulePlaceEntity("702", group, plan, secondScheduledCandidate, "Scheduled park", null, 2)
    ));
    RouteRecommendationService service = serviceWith("test-ors-key", new FakeRouteHttpClient());

    Map<String, Object> route = service.recommend("1", "101", "walk");

    List<?> stops = (List<?>) route.get("stops");
    assertThat(stops).hasSize(2);
    assertThat(((Map<?, ?>) stops.get(0)).get("id")).isEqualTo("701");
    assertThat(((Map<?, ?>) stops.get(1)).get("id")).isEqualTo("702");
  }

  @Test
  void doesNotFallbackToCandidatePoolWhenSchedulePlacesHaveNoRouteableCoordinates() {
    when(schedulePlaceRepository.findByPlanOrderBySortOrderAsc(plan)).thenReturn(List.of(
      new SchedulePlaceEntity("701", group, plan, null, "Direct place", null, 1)
    ));
    RouteRecommendationService service = serviceWith("test-ors-key", new FakeRouteHttpClient());

    Map<String, Object> route = service.recommend("1", "101", "walk");

    assertThat(route)
      .containsEntry("provider", "dev-mock")
      .containsEntry("travelMode", "walk");
    verify(placeCandidateRepository, never()).findByPlanOrderByCreatedAtAsc(plan);
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

  @Test
  void doesNotCacheDevMockFallbackWhenLiveRouteProviderFails() {
    RecordingRouteCache cache = new RecordingRouteCache();
    when(placeCandidateRepository.findByPlanOrderByCreatedAtAsc(plan)).thenReturn(candidatesWithCoordinates());
    RouteRecommendationService service = serviceWith("test-ors-key", new FailingRouteHttpClient(), cache);

    Map<String, Object> route = service.recommend("1", "101", "walk");

    assertThat(route).containsEntry("provider", "dev-mock");
    assertThat(cache.putCount).isZero();
  }

  @Test
  void separatesRouteCacheKeyByProviderAvailability() {
    RecordingRouteCache unavailableCache = new RecordingRouteCache();
    RecordingRouteCache availableCache = new RecordingRouteCache();
    when(placeCandidateRepository.findByPlanOrderByCreatedAtAsc(plan)).thenReturn(candidatesWithCoordinates());

    serviceWith("", new FakeRouteHttpClient(), unavailableCache).recommend("1", "101", "walk");
    serviceWith("test-ors-key", new FakeRouteHttpClient(), availableCache).recommend("1", "101", "walk");

    assertThat(unavailableCache.lastKey).isNotBlank();
    assertThat(availableCache.lastKey).isNotBlank();
    assertThat(unavailableCache.lastKey).isNotEqualTo(availableCache.lastKey);
  }

  private RouteRecommendationService serviceWith(String apiKey, RouteHttpClient httpClient) {
    return serviceWith(apiKey, httpClient, new NoopRouteCache());
  }

  private RouteRecommendationService serviceWith(String apiKey, RouteHttpClient httpClient, RouteRecommendationCache cache) {
    return new RouteRecommendationService(
      groupRepository,
      planRepository,
      placeCandidateRepository,
      schedulePlaceRepository,
      new OpenRouteServiceProvider(
        httpClient,
        new OpenRouteServiceMapper(objectMapper),
        apiKey,
        "https://routes.example.test"
      ),
      new DevMockRouteProvider(),
      cache,
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
    private Map<String, String> lastHeaders;
    private Map<String, Object> lastBody;

    @Override
    public String post(URI uri, Map<String, String> headers, Map<String, Object> body) {
      this.lastUri = uri;
      this.lastHeaders = headers;
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

  private static final class FailingRouteHttpClient implements RouteHttpClient {
    @Override
    public String post(URI uri, Map<String, String> headers, Map<String, Object> body) {
      throw new IllegalStateException("synthetic route provider failure");
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

  private static final class RecordingRouteCache implements RouteRecommendationCache {
    private int putCount;
    private String lastKey;

    @Override
    public Optional<Map<String, Object>> get(String key) {
      this.lastKey = key;
      return Optional.empty();
    }

    @Override
    public void put(String key, Map<String, Object> route) {
      this.putCount += 1;
      this.lastKey = key;
    }
  }
}
