package com.onmu.api.place;

import java.net.URI;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.env.Environment;
import org.springframework.stereotype.Component;
import org.springframework.web.util.UriComponentsBuilder;

@Component
public class KakaoKeywordSearchProvider implements PlaceSearchProvider {
  private final Environment environment;
  private final PlaceSearchHttpClient httpClient;
  private final KakaoKeywordSearchMapper mapper;
  private final String keywordSearchUrl;

  public KakaoKeywordSearchProvider(
    Environment environment,
    PlaceSearchHttpClient httpClient,
    KakaoKeywordSearchMapper mapper,
    @Value("${onmu.place.kakao.keyword-search-url:https://dapi.kakao.com/v2/local/search/keyword.json}") String keywordSearchUrl
  ) {
    this.environment = environment;
    this.httpClient = httpClient;
    this.mapper = mapper;
    this.keywordSearchUrl = keywordSearchUrl;
  }

  @Override
  public String provider() {
    return "kakao";
  }

  @Override
  public boolean isAvailable() {
    return hasText(restApiKey());
  }

  @Override
  public List<PlaceSearchResult> search(PlaceSearchQuery query) {
    if (!isAvailable()) {
      return List.of();
    }
    UriComponentsBuilder builder = UriComponentsBuilder.fromUriString(keywordSearchUrl)
      .queryParam("query", query.normalizedQuery())
      .queryParam("size", 15);
    if (query.lat() != null && query.lng() != null) {
      builder.queryParam("x", query.lng());
      builder.queryParam("y", query.lat());
      if (query.radius() != null && query.radius() > 0) {
        builder.queryParam("radius", Math.min(query.radius(), 20_000));
      }
    }
    URI uri = builder.build().encode().toUri();
    Map<String, String> headers = new LinkedHashMap<>();
    headers.put("Authorization", "KakaoAK " + restApiKey());
    String body = httpClient.get(uri, headers);
    return mapper.map(body, Instant.now());
  }

  private String restApiKey() {
    return environment.getProperty("KAKAO_REST_API_KEY");
  }

  private boolean hasText(String value) {
    return value != null && !value.isBlank();
  }
}
