package com.onmu.api.place;

import java.net.URI;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.env.Environment;
import org.springframework.stereotype.Component;
import org.springframework.web.util.UriComponentsBuilder;

@Component
public class NaverLocalSearchProvider implements PlaceSearchProvider {
  private final Environment environment;
  private final PlaceSearchHttpClient httpClient;
  private final NaverLocalSearchMapper mapper;
  private final String localSearchUrl;

  public NaverLocalSearchProvider(
    Environment environment,
    PlaceSearchHttpClient httpClient,
    NaverLocalSearchMapper mapper,
    @Value("${onmu.place.naver.local-search-url:https://openapi.naver.com/v1/search/local.json}") String localSearchUrl
  ) {
    this.environment = environment;
    this.httpClient = httpClient;
    this.mapper = mapper;
    this.localSearchUrl = localSearchUrl;
  }

  @Override
  public String provider() {
    return "naver";
  }

  @Override
  public boolean isAvailable() {
    return hasText(clientId()) && hasText(clientSecret());
  }

  @Override
  public List<PlaceSearchResult> search(PlaceSearchQuery query) {
    if (!isAvailable()) {
      return List.of();
    }
    URI uri = UriComponentsBuilder.fromUriString(localSearchUrl)
      .queryParam("query", query.normalizedQuery())
      .queryParam("display", 5)
      .queryParam("start", 1)
      .queryParam("sort", "random")
      .build()
      .encode()
      .toUri();
    String body = httpClient.get(uri, Map.of(
      "X-Naver-Client-Id", clientId(),
      "X-Naver-Client-Secret", clientSecret()
    ));
    return mapper.map(body, Instant.now());
  }

  private String clientId() {
    return environment.getProperty("NAVER_SEARCH_CLIENT_ID");
  }

  private String clientSecret() {
    return environment.getProperty("NAVER_SEARCH_CLIENT_SECRET");
  }

  private boolean hasText(String value) {
    return value != null && !value.isBlank();
  }
}
