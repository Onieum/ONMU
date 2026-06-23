package com.onmu.api.place;

import java.net.URI;
import org.springframework.http.MediaType;

public interface PlaceImageHttpClient {
  PlaceImageResponse get(URI uri);

  record PlaceImageResponse(byte[] content, MediaType contentType) {
  }
}
