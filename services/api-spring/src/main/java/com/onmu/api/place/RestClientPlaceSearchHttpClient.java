package com.onmu.api.place;

import java.net.URI;
import java.time.Duration;
import java.util.Map;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

@Component
public class RestClientPlaceSearchHttpClient implements PlaceSearchHttpClient {
  private final RestClient restClient;

  public RestClientPlaceSearchHttpClient() {
    SimpleClientHttpRequestFactory requestFactory = new SimpleClientHttpRequestFactory();
    requestFactory.setConnectTimeout(Duration.ofSeconds(3));
    requestFactory.setReadTimeout(Duration.ofSeconds(5));
    this.restClient = RestClient.builder()
      .requestFactory(requestFactory)
      .build();
  }

  @Override
  public String get(URI uri, Map<String, String> headers) {
    RestClient.RequestHeadersSpec<?> request = restClient.get().uri(uri);
    headers.forEach(request::header);
    return request.retrieve().body(String.class);
  }
}
