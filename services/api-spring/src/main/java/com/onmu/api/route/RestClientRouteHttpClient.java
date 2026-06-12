package com.onmu.api.route;

import java.net.URI;
import java.time.Duration;
import java.util.Map;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

@Component
public class RestClientRouteHttpClient implements RouteHttpClient {
  private final RestClient restClient;

  public RestClientRouteHttpClient() {
    SimpleClientHttpRequestFactory requestFactory = new SimpleClientHttpRequestFactory();
    requestFactory.setConnectTimeout(Duration.ofSeconds(4));
    requestFactory.setReadTimeout(Duration.ofSeconds(8));
    this.restClient = RestClient.builder()
      .requestFactory(requestFactory)
      .build();
  }

  @Override
  public String post(URI uri, Map<String, String> headers, Map<String, Object> body) {
    RestClient.RequestBodySpec request = restClient.post().uri(uri);
    headers.forEach(request::header);
    return request.body(body).retrieve().body(String.class);
  }
}
