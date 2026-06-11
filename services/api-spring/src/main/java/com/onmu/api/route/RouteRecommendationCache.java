package com.onmu.api.route;

import java.util.Map;
import java.util.Optional;

public interface RouteRecommendationCache {
  Optional<Map<String, Object>> get(String key);

  void put(String key, Map<String, Object> route);
}
