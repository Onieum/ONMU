package com.onmu.api.place;

import java.net.URI;
import java.util.Map;

public interface PlaceSearchHttpClient {
  String get(URI uri, Map<String, String> headers);
}
