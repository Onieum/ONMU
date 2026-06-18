package com.onmu.api.place;

import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.net.URI;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;
import org.springframework.mock.env.MockEnvironment;

class KakaoKeywordSearchProviderTests {
  private static final String SYNTHETIC_KAKAO_JSON = """
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

  @Test
  void searchesKakaoKeywordApiWithMaximumPageSizeAndLocationRadius() {
    CapturingHttpClient httpClient = new CapturingHttpClient(SYNTHETIC_KAKAO_JSON);
    KakaoKeywordSearchProvider provider = newProvider(httpClient, environmentWithCredentials());

    List<PlaceSearchResult> results = provider.search(new PlaceSearchQuery(
      "성수 카페",
      "1",
      "104",
      37.544,
      127.055,
      25_000,
      "cafe",
      List.of("kakao"),
      false
    ));

    assertThat(results).singleElement()
      .satisfies(result -> {
        assertThat(result.provider()).isEqualTo("kakao");
        assertThat(result.providerPlaceId()).isEqualTo("kakao-123");
        assertThat(result.name()).isEqualTo("온무 카페");
        assertThat(result.latitude()).isEqualTo(37.501);
        assertThat(result.longitude()).isEqualTo(127.001);
      });
    assertThat(httpClient.requestedUri).isNotNull();
    assertThat(httpClient.requestedUri.getRawQuery())
      .contains("query=%EC%84%B1%EC%88%98%20%EC%B9%B4%ED%8E%98")
      .contains("size=15")
      .contains("x=127.055")
      .contains("y=37.544")
      .contains("radius=20000");
    assertThat(httpClient.headers).containsKey("Authorization");
    assertThat(httpClient.headers.get("Authorization")).startsWith("KakaoAK ");
  }

  @Test
  void missingCredentialsKeepProviderUnavailableAndSkipHttpCall() {
    CapturingHttpClient httpClient = new CapturingHttpClient(SYNTHETIC_KAKAO_JSON);
    KakaoKeywordSearchProvider provider = newProvider(httpClient, new MockEnvironment());

    assertThat(provider.isAvailable()).isFalse();
    assertThat(provider.search(new PlaceSearchQuery("카페", "1", "101", null, null, null, null, List.of("kakao"), false)))
      .isEmpty();
    assertThat(httpClient.requestedUri).isNull();
  }

  private static KakaoKeywordSearchProvider newProvider(CapturingHttpClient httpClient, MockEnvironment environment) {
    return new KakaoKeywordSearchProvider(
      environment,
      httpClient,
      new KakaoKeywordSearchMapper(new ObjectMapper()),
      "https://dapi.kakao.com/v2/local/search/keyword.json"
    );
  }

  private static MockEnvironment environmentWithCredentials() {
    return new MockEnvironment().withProperty("KAKAO_REST_API_KEY", "synthetic-rest-api-key");
  }

  private static class CapturingHttpClient implements PlaceSearchHttpClient {
    private final String response;
    private URI requestedUri;
    private Map<String, String> headers = Map.of();

    private CapturingHttpClient(String response) {
      this.response = response;
    }

    @Override
    public String get(URI uri, Map<String, String> headers) {
      this.requestedUri = uri;
      this.headers = new LinkedHashMap<>(headers);
      return response;
    }
  }
}
