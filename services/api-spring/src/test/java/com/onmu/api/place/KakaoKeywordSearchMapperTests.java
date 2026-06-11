package com.onmu.api.place;

import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.time.Instant;
import org.junit.jupiter.api.Test;

class KakaoKeywordSearchMapperTests {
  private final KakaoKeywordSearchMapper mapper = new KakaoKeywordSearchMapper(new ObjectMapper());

  @Test
  void mapsSyntheticKeywordSearchJson() {
    String json = """
      {
        "documents": [
          {
            "id": "kakao-123",
            "place_name": "온무 카페",
            "category_name": "음식점 > 카페",
            "address_name": "서울 강남구 지번",
            "road_address_name": "서울 강남구 도로명",
            "x": "127.001",
            "y": "37.501",
            "place_url": "https://place.map.kakao.com/123"
          }
        ]
      }
      """;

    var results = mapper.map(json, Instant.parse("2026-06-10T00:00:00Z"));

    assertThat(results).singleElement()
      .satisfies(result -> {
        assertThat(result.provider()).isEqualTo("kakao");
        assertThat(result.providerPlaceId()).isEqualTo("kakao-123");
        assertThat(result.name()).isEqualTo("온무 카페");
        assertThat(result.latitude()).isEqualTo(37.501);
        assertThat(result.longitude()).isEqualTo(127.001);
        assertThat(result.sourceUrl()).isEqualTo("https://place.map.kakao.com/123");
      });
  }
}
