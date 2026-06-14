package com.onmu.api.place;

import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.net.URI;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.mock.env.MockEnvironment;

class NaverLocalSearchProviderTests {
  private static final String SYNTHETIC_NAVER_JSON = """
    {
      "lastBuildDate": "Sun, 14 Jun 2026 00:00:00 +0900",
      "total": 1,
      "start": 1,
      "display": 1,
      "items": [
        {
          "title": "<b>ONMU Cafe</b>",
          "link": "https://example.test/naver-place",
          "category": "Cafe>Brunch",
          "description": "",
          "telephone": "",
          "address": "Seoul Jongno-gu",
          "roadAddress": "Seoul Road 10",
          "mapx": "1269780000",
          "mapy": "375665000"
        }
      ]
    }
    """;

  @Test
  void searchesNaverLocalApiWithJsonHeadersAndMapsSyntheticResults() {
    CapturingHttpClient httpClient = new CapturingHttpClient(SYNTHETIC_NAVER_JSON);
    NaverLocalSearchProvider provider = newProvider(httpClient, environmentWithCredentials());

    List<PlaceSearchResult> results = provider.search(new PlaceSearchQuery(
      "홍대 카페",
      "1",
      "104",
      37.5665,
      126.9780,
      1000,
      "cafe",
      List.of("naver"),
      false
    ));

    assertThat(results).singleElement()
      .satisfies(result -> {
        assertThat(result.provider()).isEqualTo("naver");
        assertThat(result.providerPlaceId()).startsWith("naver-");
        assertThat(result.name()).isEqualTo("ONMU Cafe");
        assertThat(result.category()).isEqualTo("Cafe > Brunch");
        assertThat(result.address()).isEqualTo("Seoul Jongno-gu");
        assertThat(result.roadAddress()).isEqualTo("Seoul Road 10");
        assertThat(result.sourceUrl()).isEqualTo("https://example.test/naver-place");
        assertThat(result.latitude()).isEqualTo(37.5665);
        assertThat(result.longitude()).isEqualTo(126.9780);
      });
    assertThat(httpClient.requestedUri).isNotNull();
    assertThat(httpClient.requestedUri.getRawQuery())
      .contains("query=%ED%99%8D%EB%8C%80%20%EC%B9%B4%ED%8E%98")
      .contains("display=5")
      .contains("start=1")
      .contains("sort=random");
    assertThat(httpClient.headers)
      .containsEntry(HttpHeaders.ACCEPT, MediaType.APPLICATION_JSON_VALUE)
      .containsKey(HttpHeaders.USER_AGENT)
      .containsKeys("X-Naver-Client-Id", "X-Naver-Client-Secret");
  }

  @Test
  void missingCredentialsKeepProviderUnavailableAndSkipHttpCall() {
    CapturingHttpClient httpClient = new CapturingHttpClient(SYNTHETIC_NAVER_JSON);
    NaverLocalSearchProvider provider = newProvider(httpClient, new MockEnvironment());

    assertThat(provider.isAvailable()).isFalse();
    assertThat(provider.search(new PlaceSearchQuery("카페", "1", "101", null, null, null, null, List.of("naver"), false)))
      .isEmpty();
    assertThat(httpClient.requestedUri).isNull();
  }

  private static NaverLocalSearchProvider newProvider(CapturingHttpClient httpClient, MockEnvironment environment) {
    return new NaverLocalSearchProvider(
      environment,
      httpClient,
      new NaverLocalSearchMapper(new ObjectMapper()),
      "https://openapi.naver.com/v1/search/local.json"
    );
  }

  private static MockEnvironment environmentWithCredentials() {
    return new MockEnvironment()
      .withProperty("NAVER_SEARCH_CLIENT_ID", "synthetic-client-id")
      .withProperty("NAVER_SEARCH_CLIENT_SECRET", "synthetic-client-secret");
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
