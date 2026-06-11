package com.onmu.api.route;

import java.net.URI;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.util.UriComponentsBuilder;

@Component
public class OpenRouteServiceProvider implements RouteProvider {
  private final RouteHttpClient httpClient;
  private final OpenRouteServiceMapper mapper;
  private final String apiKey;
  private final String baseUrl;

  public OpenRouteServiceProvider(
    RouteHttpClient httpClient,
    OpenRouteServiceMapper mapper,
    @Value("${OPENROUTESERVICE_API_KEY:}") String apiKey,
    @Value("${onmu.routes.openrouteservice-base-url:https://api.openrouteservice.org}") String baseUrl
  ) {
    this.httpClient = httpClient;
    this.mapper = mapper;
    this.apiKey = apiKey == null ? "" : apiKey.trim();
    this.baseUrl = baseUrl == null || baseUrl.isBlank() ? "https://api.openrouteservice.org" : baseUrl;
  }

  @Override
  public String provider() {
    return "openrouteservice";
  }

  @Override
  public boolean isAvailable() {
    return !apiKey.isBlank();
  }

  @Override
  public RouteRecommendation recommend(List<RouteStop> stops, RouteTravelMode travelMode) {
    URI uri = UriComponentsBuilder
      .fromUriString(baseUrl)
      .path("/v2/directions/{profile}/geojson")
      .build(travelMode.openRouteServiceProfile());
    List<List<Double>> coordinates = stops.stream()
      .map(stop -> List.of(stop.longitude(), stop.latitude()))
      .toList();
    Map<String, Object> body = Map.of("coordinates", coordinates);
    String response = httpClient.post(
      uri,
      Map.of(
        "Authorization", apiKey,
        "Accept", "application/json",
        "Content-Type", "application/json"
      ),
      body
    );
    return mapper.map(response, stops, travelMode, Instant.now());
  }
}
