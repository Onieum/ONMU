package com.onmu.api.place;

import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.time.Instant;
import org.junit.jupiter.api.Test;

class NaverLocalSearchMapperTests {
  private final NaverLocalSearchMapper mapper = new NaverLocalSearchMapper(new ObjectMapper());

  @Test
  void mapsSyntheticLocalSearchJsonWithoutTrustingMapxMapyAsWgs84() {
    String json = """
      {
        "items": [
          {
            "title": "<b>온무 카페</b>",
            "link": "https://example.com/naver-place",
            "category": "카페>디저트",
            "address": "서울 종로구 지번",
            "roadAddress": "서울 종로구 도로명",
            "mapx": "1269780",
            "mapy": "375665"
          }
        ]
      }
      """;

    var results = mapper.map(json, Instant.parse("2026-06-10T00:00:00Z"));

    assertThat(results).singleElement()
      .satisfies(result -> {
        assertThat(result.provider()).isEqualTo("naver");
        assertThat(result.providerPlaceId()).startsWith("naver-");
        assertThat(result.name()).isEqualTo("온무 카페");
        assertThat(result.category()).isEqualTo("카페 > 디저트");
        assertThat(result.address()).isEqualTo("서울 종로구 지번");
        assertThat(result.roadAddress()).isEqualTo("서울 종로구 도로명");
        assertThat(result.latitude()).isNull();
        assertThat(result.longitude()).isNull();
      });
  }

  @Test
  void invalidJsonReturnsEmptyResults() {
    assertThat(mapper.map("{", Instant.parse("2026-06-10T00:00:00Z"))).isEmpty();
  }
}
