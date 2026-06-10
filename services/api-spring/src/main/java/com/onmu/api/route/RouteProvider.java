package com.onmu.api.route;

import java.util.List;

public interface RouteProvider {
  String provider();

  boolean isAvailable();

  RouteRecommendation recommend(List<RouteStop> stops, RouteTravelMode travelMode);
}
