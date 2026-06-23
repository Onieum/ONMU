package com.onmu.api.place;

import java.net.URI;
import java.time.Duration;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

@Component
public class RestClientPlaceImageHttpClient implements PlaceImageHttpClient {
  private final RestClient restClient;

  public RestClientPlaceImageHttpClient() {
    SimpleClientHttpRequestFactory requestFactory = new SimpleClientHttpRequestFactory();
    requestFactory.setConnectTimeout(Duration.ofSeconds(3));
    requestFactory.setReadTimeout(Duration.ofSeconds(6));
    this.restClient = RestClient.builder()
      .requestFactory(requestFactory)
      .build();
  }

  @Override
  public PlaceImageResponse get(URI uri) {
    ResponseEntity<byte[]> response = restClient.get()
      .uri(uri)
      .retrieve()
      .toEntity(byte[].class);
    return new PlaceImageResponse(
      response.getBody() == null ? new byte[0] : response.getBody(),
      response.getHeaders().getContentType() == null
        ? MediaType.APPLICATION_OCTET_STREAM
        : response.getHeaders().getContentType()
    );
  }
}
