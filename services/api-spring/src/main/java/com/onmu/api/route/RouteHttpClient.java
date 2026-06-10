package com.onmu.api.route;

import java.net.URI;
import java.util.Map;

public interface RouteHttpClient {
  String post(URI uri, Map<String, String> headers, Map<String, Object> body);
}
