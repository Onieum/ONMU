package com.onmu.api.map;

import java.sql.ResultSet;
import java.sql.SQLException;
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
      .addValue("east", query.east());
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
    if (!query.query().isBlank()) {
      where.append("""
         and (
           lower(name) like :query
           or lower(coalesce(category, '')) like :query
           or lower(coalesce(address, '')) like :query
           or lower(coalesce(road_address, '')) like :query
           or lower(coalesce(provider_payload::text, '')) like :query
         )
        """);
      params.addValue("query", "%" + query.query() + "%");
    }
    return new SqlParts(where.toString(), params);
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
