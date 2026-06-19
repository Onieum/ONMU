package com.onmu.api.place;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.onmu.api.domain.ExternalPlaceEntity;
import com.onmu.api.domain.ExternalPlaceRepository;
import java.util.Collection;
import java.util.List;
import org.junit.jupiter.api.Test;

@SuppressWarnings("unchecked")
class CuratedPlaceSearchProviderTests {
  private final ExternalPlaceRepository repository = mock(ExternalPlaceRepository.class);
  private final CuratedPlaceSearchProvider provider = new CuratedPlaceSearchProvider(repository, new ObjectMapper());

  @Test
  void searchReturnsAttractionCatalogRowsForLocationQuery() {
    when(repository.findByProviderAndCategoryInAndLatitudeIsNotNullAndLongitudeIsNotNull(eq("ONMU_CATALOG"), any(Collection.class)))
      .thenReturn(List.of(
        catalogPlace("tour-1", "망원 한강공원", "관광명소", "서울 마포구 망원동", 37.555, 126.895, payload("망원동", "공원", "산책로")),
        catalogPlace("tour-2", "강남 전시관", "문화공간", "서울 강남구", 37.500, 127.030, payload("강남", "전시", "미술관"))
      ));

    var results = provider.search(query("망원동 공원", "가볼만한곳", null, null, null));

    assertThat(results).singleElement()
      .satisfies(result -> assertThat(result)
        .extracting(PlaceSearchResult::provider, PlaceSearchResult::providerPlaceId, PlaceSearchResult::name)
        .containsExactly("onmu_catalog", "tour-1", "망원 한강공원"));
  }

  @Test
  void searchKeepsCafeSupplementToCafeTaggedRows() {
    when(repository.findByProviderAndCategoryInAndLatitudeIsNotNullAndLongitudeIsNotNull(eq("ONMU_CATALOG"), any(Collection.class)))
      .thenReturn(List.of(
        catalogPlace("food-1", "망원 디저트 카페", "식당", "서울 마포구 망원동", 37.555, 126.895, payload("망원동", "카페", "디저트")),
        catalogPlace("food-2", "망원 국밥", "식당", "서울 마포구 망원동", 37.556, 126.896, payload("망원동", "한식", "식당"))
      ));

    var results = provider.search(query("망원동", "카페", null, null, null));

    assertThat(results).singleElement()
      .satisfies(result -> assertThat(result)
        .extracting(PlaceSearchResult::providerPlaceId, PlaceSearchResult::name)
        .containsExactly("food-1", "망원 디저트 카페"));
  }

  @Test
  void searchAppliesRadiusWithoutPostgis() {
    when(repository.findByProviderAndCategoryInAndLatitudeIsNotNullAndLongitudeIsNotNull(eq("ONMU_CATALOG"), any(Collection.class)))
      .thenReturn(List.of(
        catalogPlace("tour-near", "현 위치 공원", "관광명소", "서울 마포구", 37.555, 126.895, payload("망원동", "공원")),
        catalogPlace("tour-far", "먼 지역 공원", "관광명소", "부산", 35.179, 129.075, payload("부산", "공원"))
      ));

    var results = provider.search(query("공원", "가볼만한곳", 37.555, 126.895, 1_500));

    assertThat(results).singleElement()
      .satisfies(result -> assertThat(result.providerPlaceId()).isEqualTo("tour-near"));
  }

  private static PlaceSearchQuery query(String value, String category, Double lat, Double lng, Integer radius) {
    return new PlaceSearchQuery(value, "group-1", "plan-1", lat, lng, radius, category, List.of(), false);
  }

  private static ExternalPlaceEntity catalogPlace(
    String providerPlaceId,
    String name,
    String category,
    String address,
    Double lat,
    Double lng,
    String payload
  ) {
    return new ExternalPlaceEntity("ONMU_CATALOG", providerPlaceId, name, category, address, address, lat, lng, null, payload);
  }

  private static String payload(String region, String... tags) {
    return """
      {
        "region": "%s",
        "summary": "%s 추천 장소",
        "tags": [%s],
        "purposeTags": [%s],
        "preferenceTags": [],
        "reasons": []
      }
      """.formatted(region, region, quoted(tags), quoted(tags));
  }

  private static String quoted(String[] values) {
    return java.util.Arrays.stream(values)
      .map(value -> "\"" + value + "\"")
      .reduce((left, right) -> left + ", " + right)
      .orElse("");
  }
}
