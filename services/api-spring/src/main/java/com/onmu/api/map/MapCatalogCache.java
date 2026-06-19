package com.onmu.api.map;

import java.util.Map;
import java.util.Optional;

public interface MapCatalogCache {
  Optional<Map<String, Object>> get(String key);

  void put(String key, Map<String, Object> response);
}
