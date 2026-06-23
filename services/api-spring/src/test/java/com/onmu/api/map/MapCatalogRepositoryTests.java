package com.onmu.api.map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import com.onmu.api.web.dto.MapPointsRequest;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.jdbc.core.namedparam.SqlParameterSource;

class MapCatalogRepositoryTests {
  @Test
  void clusterQueryUsesPostgisBboxSnapToGridAndFilters() {
    @SuppressWarnings("unchecked")
    NamedParameterJdbcTemplate jdbcTemplate = mock(NamedParameterJdbcTemplate.class);
    when(jdbcTemplate.query(any(String.class), any(SqlParameterSource.class), any(RowMapper.class)))
      .thenReturn(List.of());
    MapCatalogRepository repository = new MapCatalogRepository(jdbcTemplate);

    repository.findClusters(query(12, "카페", "rooftop", "성수"));

    CapturedQuery captured = capture(jdbcTemplate);
    assertThat(captured.sql())
      .contains("ST_Intersects(place_point, ST_MakeEnvelope(:west, :south, :east, :north, 4326))")
      .contains("ST_SnapToGrid(place_point, :grid_size)")
      .contains("lower(category) = :category")
      .contains("provider_payload::text")
      .contains("group by grid_cell");
    assertThat(captured.params().getValue("provider")).isEqualTo("ONMU_CATALOG");
    assertThat(captured.params().getValue("category")).isEqualTo("카페");
    assertThat(captured.params().getValue("filter")).isEqualTo("%rooftop%");
    assertThat(captured.params().getValue("query_0")).isEqualTo("%성수%");
    assertThat(captured.params().getValue("grid_size")).isEqualTo(0.03);
  }

  @Test
  void queryFilterMatchesAllWhitespaceSeparatedTokensAcrossCatalogText() {
    @SuppressWarnings("unchecked")
    NamedParameterJdbcTemplate jdbcTemplate = mock(NamedParameterJdbcTemplate.class);
    when(jdbcTemplate.query(any(String.class), any(SqlParameterSource.class), any(RowMapper.class)))
      .thenReturn(List.of());
    MapCatalogRepository repository = new MapCatalogRepository(jdbcTemplate);

    repository.findPoints(query(16, "식당", "all", "을지로 카페"));

    CapturedQuery captured = capture(jdbcTemplate);
    assertThat(captured.sql())
      .contains("lower(name) like :query_0")
      .contains("lower(coalesce(provider_payload::text, '')) like :query_0")
      .contains("lower(name) like :query_1")
      .contains("lower(coalesce(provider_payload::text, '')) like :query_1");
    assertThat(captured.params().getValue("query_0")).isEqualTo("%을지로%");
    assertThat(captured.params().getValue("query_1")).isEqualTo("%카페%");
    assertThat(captured.params().hasValue("query")).isFalse();
  }

  @Test
  void pointQueryUsesPostgisBboxWithoutClusterAggregation() {
    @SuppressWarnings("unchecked")
    NamedParameterJdbcTemplate jdbcTemplate = mock(NamedParameterJdbcTemplate.class);
    when(jdbcTemplate.query(any(String.class), any(SqlParameterSource.class), any(RowMapper.class)))
      .thenReturn(List.of());
    MapCatalogRepository repository = new MapCatalogRepository(jdbcTemplate);

    repository.findPoints(query(16, "", "all", ""));

    CapturedQuery captured = capture(jdbcTemplate);
    assertThat(captured.sql())
      .contains("ST_Intersects(place_point, ST_MakeEnvelope(:west, :south, :east, :north, 4326))")
      .doesNotContain("ST_SnapToGrid")
      .contains("order by name asc, provider_place_id asc")
      .contains("limit :limit");
    assertThat(captured.params().getValue("provider")).isEqualTo("ONMU_CATALOG");
    assertThat(captured.params().getValue("limit")).isEqualTo(500);
    assertThat(captured.params().hasValue("category")).isFalse();
    assertThat(captured.params().hasValue("query")).isFalse();
  }

  @Test
  void gridSizeGetsSmallerAsZoomIncreases() {
    assertThat(MapCatalogRepository.gridSizeDegrees(8)).isEqualTo(0.5);
    assertThat(MapCatalogRepository.gridSizeDegrees(10)).isEqualTo(0.1);
    assertThat(MapCatalogRepository.gridSizeDegrees(12)).isEqualTo(0.03);
    assertThat(MapCatalogRepository.gridSizeDegrees(14)).isEqualTo(0.01);
  }

  private static MapCatalogService.CatalogMapQuery query(int zoom, String category, String filter, String text) {
    return MapCatalogService.CatalogMapQuery.from(new MapPointsRequest(
      "1",
      "101",
      new MapPointsRequest.Bounds(37.50, 126.90, 37.62, 127.08),
      zoom,
      category,
      filter,
      text
    ));
  }

  private static CapturedQuery capture(NamedParameterJdbcTemplate jdbcTemplate) {
    ArgumentCaptor<String> sql = ArgumentCaptor.forClass(String.class);
    ArgumentCaptor<SqlParameterSource> params = ArgumentCaptor.forClass(SqlParameterSource.class);
    @SuppressWarnings("unchecked")
    ArgumentCaptor<RowMapper<?>> mapper = ArgumentCaptor.forClass(RowMapper.class);
    org.mockito.Mockito.verify(jdbcTemplate).query(sql.capture(), params.capture(), mapper.capture());
    return new CapturedQuery(sql.getValue(), params.getValue());
  }

  private record CapturedQuery(String sql, SqlParameterSource params) {
  }
}
