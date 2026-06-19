package com.onmu.api.map;

import static org.assertj.core.api.Assertions.assertThat;

import com.onmu.api.web.dto.MapPointsRequest;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import org.junit.jupiter.api.Test;

class MapCatalogServiceTests {
  @Test
  void lowZoomReturnsClustersWithoutTop20PlaceSearchResults() {
    FakeRepository repository = new FakeRepository();
    repository.clusters = List.of(new MapCatalogRepository.MapCatalogCluster(
      "cluster:1",
      12,
      37.55,
      127.02,
      37.54,
      127.01,
      37.56,
      127.03,
      "카페"
    ));
    MapCatalogService service = new MapCatalogService(repository, new MemoryCache());

    Map<String, Object> response = service.mapPoints(request(12, "카페", "all", "성수"));

    assertThat(response)
      .containsEntry("mode", "clusters")
      .containsEntry("point_count", 0)
      .containsEntry("cluster_count", 1);
    assertThat((List<?>) response.get("points")).isEmpty();
    assertThat((List<?>) response.get("clusters")).singleElement()
      .isInstanceOfSatisfying(Map.class, cluster -> assertThat(cluster)
        .containsEntry("type", "cluster")
        .containsEntry("count", 12L)
        .doesNotContainKeys("heartCount", "myHearted", "canAddCandidate"));
    assertThat(repository.pointQueries).isEmpty();
    assertThat(repository.clusterQueries).hasSize(1);
  }

  @Test
  void highZoomReturnsCatalogPoints() {
    FakeRepository repository = new FakeRepository();
    repository.points = List.of(new MapCatalogRepository.MapCatalogPoint(
      "place_1",
      "ONMU_CATALOG",
      "catalog-1",
      "성수 카페",
      "카페",
      "서울 성동구",
      "서울 성동구 도로",
      37.55,
      127.02
    ));
    MapCatalogService service = new MapCatalogService(repository, new MemoryCache());

    Map<String, Object> response = service.mapPoints(request(16, "카페", "all", "성수"));

    assertThat(response)
      .containsEntry("mode", "points")
      .containsEntry("point_count", 1)
      .containsEntry("cluster_count", 0);
    assertThat((List<?>) response.get("clusters")).isEmpty();
    assertThat((List<?>) response.get("points")).singleElement()
      .isInstanceOfSatisfying(Map.class, point -> assertThat(point)
        .containsEntry("type", "point")
        .containsEntry("provider", "onmu_catalog")
        .containsEntry("providerPlaceId", "catalog-1")
        .doesNotContainKeys("heartCount", "myHearted", "canAddCandidate"));
    assertThat(repository.clusterQueries).isEmpty();
    assertThat(repository.pointQueries).hasSize(1);
  }

  @Test
  void cacheKeySeparatesBoundsZoomCategoryFilterAndQuery() {
    FakeRepository repository = new FakeRepository();
    MemoryCache cache = new MemoryCache();
    MapCatalogService service = new MapCatalogService(repository, cache);

    service.mapPoints(request(12, "카페", "all", "성수"));
    service.mapPoints(request(12, "카페", "all", "성수"));
    service.mapPoints(request(13, "카페", "all", "성수"));
    service.mapPoints(request(12, "식당", "all", "성수"));
    service.mapPoints(request(12, "카페", "rooftop", "성수"));
    service.mapPoints(request(12, "카페", "all", "망원"));

    assertThat(cache.values).hasSize(5);
    assertThat(repository.clusterQueries).hasSize(5);
  }

  @Test
  void redisCacheFailureDoesNotFailCatalogResponse() {
    FakeRepository repository = new FakeRepository();
    repository.clusters = List.of(new MapCatalogRepository.MapCatalogCluster(
      "cluster:1",
      1,
      37.55,
      127.02,
      37.55,
      127.02,
      37.55,
      127.02,
      ""
    ));
    MapCatalogService service = new MapCatalogService(repository, new ThrowingCache());

    Map<String, Object> response = service.mapPoints(request(12, null, null, null));

    assertThat(response).containsEntry("mode", "clusters");
    assertThat((List<?>) response.get("clusters")).hasSize(1);
  }

  private static MapPointsRequest request(int zoom, String category, String filter, String query) {
    return new MapPointsRequest(
      "1",
      "101",
      new MapPointsRequest.Bounds(37.50, 126.90, 37.62, 127.08),
      zoom,
      category,
      filter,
      query
    );
  }

  private static final class FakeRepository extends MapCatalogRepository {
    private List<MapCatalogPoint> points = List.of();
    private List<MapCatalogCluster> clusters = List.of();
    private final List<MapCatalogService.CatalogMapQuery> pointQueries = new ArrayList<>();
    private final List<MapCatalogService.CatalogMapQuery> clusterQueries = new ArrayList<>();

    private FakeRepository() {
      super(null);
    }

    @Override
    public List<MapCatalogPoint> findPoints(MapCatalogService.CatalogMapQuery query) {
      pointQueries.add(query);
      return points;
    }

    @Override
    public List<MapCatalogCluster> findClusters(MapCatalogService.CatalogMapQuery query) {
      clusterQueries.add(query);
      return clusters;
    }
  }

  private static final class MemoryCache implements MapCatalogCache {
    private final Map<String, Map<String, Object>> values = new HashMap<>();

    @Override
    public Optional<Map<String, Object>> get(String key) {
      return Optional.ofNullable(values.get(key));
    }

    @Override
    public void put(String key, Map<String, Object> response) {
      values.put(key, response);
    }
  }

  private static final class ThrowingCache implements MapCatalogCache {
    @Override
    public Optional<Map<String, Object>> get(String key) {
      throw new IllegalStateException("redis unavailable");
    }

    @Override
    public void put(String key, Map<String, Object> response) {
      throw new IllegalStateException("redis unavailable");
    }
  }
}
