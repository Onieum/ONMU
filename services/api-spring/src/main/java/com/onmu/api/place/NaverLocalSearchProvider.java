package com.onmu.api.place;

import java.net.URI;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.env.Environment;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClientResponseException;
import org.springframework.web.util.UriComponentsBuilder;

@Component
public class NaverLocalSearchProvider implements PlaceSearchProvider {
  private static final Logger LOGGER = LoggerFactory.getLogger(NaverLocalSearchProvider.class);

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
    String clientId = clientId();
    String clientSecret = clientSecret();
    if (!hasText(clientId) || !hasText(clientSecret)) {
      LOGGER.warn("Naver local search skipped because credentials are unavailable");
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
    Map<String, String> headers = new LinkedHashMap<>();
    headers.put(HttpHeaders.ACCEPT, MediaType.APPLICATION_JSON_VALUE);
    headers.put(HttpHeaders.USER_AGENT, "ONMU-Spring-PlaceSearch/1.0");
    headers.put("X-Naver-Client-Id", clientId);
    headers.put("X-Naver-Client-Secret", clientSecret);
    try {
      LOGGER.info("Naver local search HTTP request starting");
      String body = httpClient.get(uri, headers);
      List<PlaceSearchResult> results = mapper.map(body, Instant.now());
      LOGGER.info("Naver local search provider returned mapped results: result_count={}", results.size());
      return results;
    } catch (RestClientResponseException exception) {
      LOGGER.warn("Naver local search HTTP request failed: status={}, error_type={}",
        exception.getStatusCode().value(), exception.getClass().getSimpleName());
      throw exception;
    }
  }

  private String clientId() {
    return trimmed(environment.getProperty("NAVER_SEARCH_CLIENT_ID"));
  }

  private String clientSecret() {
    return trimmed(environment.getProperty("NAVER_SEARCH_CLIENT_SECRET"));
  }

  private boolean hasText(String value) {
    return value != null && !value.isBlank();
  }

  private String trimmed(String value) {
    return value == null ? null : value.trim();
  }
}
