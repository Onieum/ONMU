package com.onmu.api.route;

import java.util.LinkedHashMap;
import java.util.Map;

public record RouteLeg(
  int order,
  String fromStopId,
  String toStopId,
  String fromName,
  String toName,
  Double distanceMeters,
  Double durationSeconds
) {
  public Map<String, Object> toApiMap() {
    Map<String, Object> value = new LinkedHashMap<>();
    value.put("order", order);
    value.put("fromStopId", fromStopId);
    value.put("toStopId", toStopId);
    value.put("fromName", fromName);
    value.put("toName", toName);
    if (distanceMeters != null) {
      value.put("distanceMeters", Math.round(distanceMeters));
    }
    if (durationSeconds != null) {
      value.put("durationSeconds", Math.round(durationSeconds));
    }
    return value;
  }
}
