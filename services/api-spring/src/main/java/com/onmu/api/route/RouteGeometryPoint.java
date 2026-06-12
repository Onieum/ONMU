package com.onmu.api.route;

import java.util.List;

public record RouteGeometryPoint(double lng, double lat) {
  public List<Double> toLngLat() {
    return List.of(lng, lat);
  }
}
