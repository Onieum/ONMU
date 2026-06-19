package com.onmu.api.map;

import com.onmu.api.web.dto.MapPointsRequest;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import org.springframework.stereotype.Service;

@Service
public class MapCatalogService {
  private static final int POINT_ZOOM_THRESHOLD = 15;
  private static final String SCHEMA_VERSION = "external_places_postgis_v1";
  private static final String PROVIDER_AVAILABILITY = "onmu_catalog:postgis";

  private final MapCatalogRepository repository;
  private final MapCatalogCache cache;

  public MapCatalogService(MapCatalogRepository repository, MapCatalogCache cache) {
    this.repository = repository;
    this.cache = cache;
  }

  public Map<String, Object> mapPoints(MapPointsRequest request) {
    CatalogMapQuery query = CatalogMapQuery.from(request);
    String cacheKey = cacheKey(query);
    try {
      var cached = cache.get(cacheKey);
      if (cached.isPresent()) {
        return cached.get();
      }
    } catch (RuntimeException ignored) {
      // Redis cache 실패는 지도 catalog API 응답을 막지 않는다.
    }

    Map<String, Object> response = response(query);
    try {
      cache.put(cacheKey, response);
    } catch (RuntimeException ignored) {
      // Redis cache 실패는 지도 catalog API 응답을 막지 않는다.
    }
    return response;
  }

  private Map<String, Object> response(CatalogMapQuery query) {
    boolean pointMode = query.zoom() >= POINT_ZOOM_THRESHOLD;
    Map<String, Object> response = new LinkedHashMap<>();
    response.put("canonical", true);
    response.put("mode", pointMode ? "points" : "clusters");
    response.put("zoom", query.zoom());
    response.put("bounds", Map.of(
      "south", query.south(),
      "west", query.west(),
      "north", query.north(),
      "east", query.east()
    ));
    response.put("category", query.category().isBlank() ? null : query.category());
    response.put("filter", query.filter().isBlank() ? null : query.filter());
    response.put("query", query.query().isBlank() ? null : query.query());
    response.put("schema_version", SCHEMA_VERSION);
    if (pointMode) {
      List<Map<String, Object>> points = repository.findPoints(query).stream()
        .map(MapCatalogRepository.MapCatalogPoint::toApiMap)
        .toList();
      response.put("points", points);
      response.put("clusters", List.of());
      response.put("point_count", points.size());
      response.put("cluster_count", 0);
    } else {
      List<Map<String, Object>> clusters = repository.findClusters(query).stream()
        .map(MapCatalogRepository.MapCatalogCluster::toApiMap)
        .toList();
      response.put("clusters", clusters);
      response.put("points", List.of());
      response.put("cluster_count", clusters.size());
      response.put("point_count", 0);
    }
    return response;
  }

  private String cacheKey(CatalogMapQuery query) {
    String value = String.join("|",
      "v1",
      SCHEMA_VERSION,
      PROVIDER_AVAILABILITY,
      String.valueOf(query.zoom()),
      rounded(query.south()),
      rounded(query.west()),
      rounded(query.north()),
      rounded(query.east()),
      query.category(),
      query.filter(),
      query.query()
    );
    try {
      MessageDigest digest = MessageDigest.getInstance("SHA-256");
      byte[] hash = digest.digest(value.getBytes(StandardCharsets.UTF_8));
      return "map-catalog:v1:" + HexFormat.of().formatHex(hash, 0, 16);
    } catch (NoSuchAlgorithmException exception) {
      throw new IllegalStateException("SHA-256 is required", exception);
    }
  }

  private String rounded(double value) {
    return String.format(Locale.ROOT, "%.5f", value);
  }

  public record CatalogMapQuery(
    double south,
    double west,
    double north,
    double east,
    int zoom,
    String category,
    String filter,
    String query
  ) {
    static CatalogMapQuery from(MapPointsRequest request) {
      MapPointsRequest.Bounds bounds = request.bounds();
      double south = bounds.south();
      double west = bounds.west();
      double north = bounds.north();
      double east = bounds.east();
      if (south > north) {
        double value = south;
        south = north;
        north = value;
      }
      if (west > east) {
        double value = west;
        west = east;
        east = value;
      }
      return new CatalogMapQuery(
        clamp(south, -90.0, 90.0),
        clamp(west, -180.0, 180.0),
        clamp(north, -90.0, 90.0),
        clamp(east, -180.0, 180.0),
        request.zoom() == null ? 12 : request.zoom(),
        normalize(request.category()),
        normalize(request.filter()),
        normalize(request.query())
      );
    }

    private static double clamp(double value, double min, double max) {
      return Math.max(min, Math.min(max, value));
    }

    private static String normalize(String value) {
      return value == null ? "" : value.trim().toLowerCase(Locale.ROOT);
    }
  }
}
