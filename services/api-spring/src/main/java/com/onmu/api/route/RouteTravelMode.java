package com.onmu.api.route;

import java.util.Locale;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

public enum RouteTravelMode {
  CAR("car", "driving-car", 13.8),
  WALK("walk", "foot-walking", 1.4),
  BIKE("bike", "cycling-regular", 4.2);

  private final String apiValue;
  private final String openRouteServiceProfile;
  private final double fallbackMetersPerSecond;

  RouteTravelMode(String apiValue, String openRouteServiceProfile, double fallbackMetersPerSecond) {
    this.apiValue = apiValue;
    this.openRouteServiceProfile = openRouteServiceProfile;
    this.fallbackMetersPerSecond = fallbackMetersPerSecond;
  }

  public String apiValue() {
    return apiValue;
  }

  public String openRouteServiceProfile() {
    return openRouteServiceProfile;
  }

  public double fallbackMetersPerSecond() {
    return fallbackMetersPerSecond;
  }

  public static RouteTravelMode fromApiValue(String value) {
    String normalized = value == null ? "" : value.trim().toLowerCase(Locale.ROOT);
    for (RouteTravelMode mode : values()) {
      if (mode.apiValue.equals(normalized)) {
        return mode;
      }
    }
    throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "unsupported_travel_mode");
  }
}
