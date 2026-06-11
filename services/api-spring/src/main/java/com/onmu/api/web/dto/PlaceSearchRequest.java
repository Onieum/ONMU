package com.onmu.api.web.dto;

import jakarta.validation.constraints.NotBlank;
import java.util.List;

public record PlaceSearchRequest(
  @NotBlank String query,
  String groupId,
  String planId,
  Double lat,
  Double lng,
  Integer radius,
  String category,
  List<String> providers,
  Boolean compare
) {
}
