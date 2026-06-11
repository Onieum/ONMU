package com.onmu.api.place;

import java.util.List;
import java.util.Map;
import java.util.Optional;

public interface PlaceSearchCache {
  Optional<List<Map<String, Object>>> get(String key);

  void put(String key, List<Map<String, Object>> results);
}
