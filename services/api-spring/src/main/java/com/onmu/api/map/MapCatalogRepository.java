package com.onmu.api.map;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.jdbc.core.namedparam.SqlParameterSource;
import org.springframework.stereotype.Repository;

@Repository
public class MapCatalogRepository {
  static final String STORED_PROVIDER = "ONMU_CATALOG";
  private static final int POINT_LIMIT = 500;
  private static final int CLUSTER_LIMIT = 300;
  private static final double MIN_KOREA_LATITUDE = 33.0;
  private static final double MAX_KOREA_LATITUDE = 39.0;
  private static final double MIN_KOREA_LONGITUDE = 124.0;
  private static final double MAX_KOREA_LONGITUDE = 132.0;

  private final NamedParameterJdbcTemplate jdbcTemplate;

  public MapCatalogRepository(NamedParameterJdbcTemplate jdbcTemplate) {
    this.jdbcTemplate = jdbcTemplate;
  }

  public List<MapCatalogPoint> findPoints(MapCatalogService.CatalogMapQuery query) {
    SqlParts parts = sqlParts(query);
    String sql = """
      select public_id,
             provider,
             provider_place_id,
             name,
             category,
             address,
             road_address,
             latitude,
             longitude
        from external_places
       where provider = :provider
         and place_point is not null
         and latitude between :min_korea_latitude and :max_korea_latitude
         and longitude between :min_korea_longitude and :max_korea_longitude
         and ST_Intersects(place_point, ST_MakeEnvelope(:west, :south, :east, :north, 4326))
      """ + parts.where() + """
       order by name asc, provider_place_id asc
       limit :limit
      """;
    return jdbcTemplate.query(sql, parts.params().addValue("limit", POINT_LIMIT), new PointMapper());
  }

  public List<MapCatalogCluster> findClusters(MapCatalogService.CatalogMapQuery query) {
    SqlParts parts = sqlParts(query);
    String sql = """
      with filtered as (
        select public_id,
               category,
               latitude,
               longitude,
               place_point,
               ST_SnapToGrid(place_point, :grid_size) as grid_cell
          from external_places
         where provider = :provider
           and place_point is not null
           and latitude between :min_korea_latitude and :max_korea_latitude
           and longitude between :min_korea_longitude and :max_korea_longitude
           and ST_Intersects(place_point, ST_MakeEnvelope(:west, :south, :east, :north, 4326))
      """ + parts.where() + """
      ),
      grouped as (
        select grid_cell,
               count(*) as point_count,
               ST_Y(ST_Centroid(ST_Collect(place_point))) as latitude,
               ST_X(ST_Centroid(ST_Collect(place_point))) as longitude,
               min(latitude) as south,
               min(longitude) as west,
               max(latitude) as north,
               max(longitude) as east,
               string_agg(distinct category, ',' order by category) filter (where category is not null) as categories
          from filtered
         group by grid_cell
      )
      select 'cluster:' || row_number() over (order by point_count desc, latitude asc, longitude asc) as cluster_id,
             point_count,
             latitude,
             longitude,
             south,
             west,
             north,
             east,
             categories
        from grouped
       order by point_count desc, latitude asc, longitude asc
       limit :limit
      """;
    return jdbcTemplate.query(
      sql,
      parts.params()
        .addValue("grid_size", gridSizeDegrees(query.zoom()))
        .addValue("limit", CLUSTER_LIMIT),
      new ClusterMapper()
    );
  }

  static double gridSizeDegrees(int zoom) {
    if (zoom <= 8) {
      return 0.5;
    }
    if (zoom <= 10) {
      return 0.1;
    }
    if (zoom <= 12) {
      return 0.03;
    }
    return 0.01;
  }

  private SqlParts sqlParts(MapCatalogService.CatalogMapQuery query) {
    StringBuilder where = new StringBuilder();
    MapSqlParameterSource params = new MapSqlParameterSource()
      .addValue("provider", STORED_PROVIDER)
      .addValue("south", query.south())
      .addValue("west", query.west())
      .addValue("north", query.north())
      .addValue("east", query.east())
      .addValue("min_korea_latitude", MIN_KOREA_LATITUDE)
      .addValue("max_korea_latitude", MAX_KOREA_LATITUDE)
      .addValue("min_korea_longitude", MIN_KOREA_LONGITUDE)
      .addValue("max_korea_longitude", MAX_KOREA_LONGITUDE);
    if (!query.category().isBlank()) {
      where.append(" and lower(category) = :category\n");
      params.addValue("category", query.category());
    }
    if (!query.filter().isBlank() && !"all".equals(query.filter())) {
      where.append("""
         and (
           lower(coalesce(category, '')) like :filter
           or lower(coalesce(provider_payload::text, '')) like :filter
         )
        """);
      params.addValue("filter", "%" + query.filter() + "%");
    }
    List<String> queryTokens = queryTokens(query.query(), query.category(), query.filter());
    for (int index = 0; index < queryTokens.size(); index++) {
      String paramName = "query_" + index;
      where.append("""
         and (
           lower(name) like :%1$s
           or lower(coalesce(category, '')) like :%1$s
           or lower(coalesce(address, '')) like :%1$s
           or lower(coalesce(road_address, '')) like :%1$s
           or lower(coalesce(provider_payload::text, '')) like :%1$s
         )
        """.formatted(paramName));
      params.addValue(paramName, "%" + queryTokens.get(index) + "%");
    }
    return new SqlParts(where.toString(), params);
  }

  private static List<String> queryTokens(String query, String category, String filter) {
    if (query == null || query.isBlank()) {
      return List.of();
    }
    String[] parts = query
      .replaceAll("[^\\p{IsHangul}\\p{IsAlphabetic}\\p{IsDigit}\\s]", " ")
      .split("\\s+");
    List<String> tokens = new ArrayList<>();
    for (String part : parts) {
      String token = part.trim().toLowerCase(Locale.ROOT);
      if (!token.isBlank()
        && !isBroadIntentToken(token, category, filter)
        && !tokens.contains(token)) {
        tokens.add(token);
      }
    }
    return tokens;
  }

  private static boolean isBroadIntentToken(String token, String category, String filter) {
    if (List.of("장소", "추천", "근처", "주변", "일대").contains(token)) {
      return true;
    }
    String normalizedCategory = category == null ? "" : category.trim().toLowerCase(Locale.ROOT);
    String normalizedFilter = filter == null ? "" : filter.trim().toLowerCase(Locale.ROOT);
    if ("식당".equals(normalizedCategory) && List.of("맛집", "음식점", "식당").contains(token)) {
      return true;
    }
    if ("관광명소".equals(normalizedCategory)
      && List.of("가볼만한", "가볼만한곳", "곳", "관광", "관광지").contains(token)) {
      return true;
    }
    if (!normalizedFilter.isBlank()
      && !"all".equals(normalizedFilter)
      && normalizedFilter.equals(token)) {
      return true;
    }
    return false;
  }

  private record SqlParts(String where, MapSqlParameterSource params) {
  }

  public record MapCatalogPoint(
    String id,
    String provider,
    String providerPlaceId,
    String name,
    String category,
    String address,
    String roadAddress,
    double lat,
    double lng
  ) {
    Map<String, Object> toApiMap() {
      return Map.ofEntries(
        Map.entry("id", id),
        Map.entry("type", "point"),
        Map.entry("provider", "onmu_catalog"),
        Map.entry("providerPlaceId", providerPlaceId),
        Map.entry("name", name),
        Map.entry("category", category == null ? "" : category),
        Map.entry("address", address == null ? "" : address),
        Map.entry("roadAddress", roadAddress == null ? "" : roadAddress),
        Map.entry("lat", lat),
        Map.entry("lng", lng)
      );
    }
  }

  public record MapCatalogCluster(
    String id,
    long count,
    double lat,
    double lng,
    double south,
    double west,
    double north,
    double east,
    String categories
  ) {
    Map<String, Object> toApiMap() {
      return Map.of(
        "id", id,
        "type", "cluster",
        "count", count,
        "lat", lat,
        "lng", lng,
        "bounds", Map.of(
          "south", south,
          "west", west,
          "north", north,
          "east", east
        ),
        "categories", categories == null || categories.isBlank()
          ? List.of()
          : List.of(categories.split(","))
      );
    }
  }

  private static final class PointMapper implements RowMapper<MapCatalogPoint> {
    @Override
    public MapCatalogPoint mapRow(ResultSet rs, int rowNum) throws SQLException {
      return new MapCatalogPoint(
        rs.getString("public_id"),
        rs.getString("provider"),
        rs.getString("provider_place_id"),
        rs.getString("name"),
        rs.getString("category"),
        rs.getString("address"),
        rs.getString("road_address"),
        rs.getDouble("latitude"),
        rs.getDouble("longitude")
      );
    }
  }

  private static final class ClusterMapper implements RowMapper<MapCatalogCluster> {
    @Override
    public MapCatalogCluster mapRow(ResultSet rs, int rowNum) throws SQLException {
      return new MapCatalogCluster(
        rs.getString("cluster_id"),
        rs.getLong("point_count"),
        rs.getDouble("latitude"),
        rs.getDouble("longitude"),
        rs.getDouble("south"),
        rs.getDouble("west"),
        rs.getDouble("north"),
        rs.getDouble("east"),
        rs.getString("categories")
      );
    }
  }
}
