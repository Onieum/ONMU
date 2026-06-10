package com.onmu.api.place;

import java.util.List;

public interface PlaceSearchProvider {
  String provider();

  boolean isAvailable();

  List<PlaceSearchResult> search(PlaceSearchQuery query);
}
