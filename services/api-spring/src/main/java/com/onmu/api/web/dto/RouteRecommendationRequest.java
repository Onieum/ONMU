package com.onmu.api.web.dto;

import jakarta.validation.constraints.NotBlank;

public record RouteRecommendationRequest(
  @NotBlank String groupId,
  @NotBlank String planId,
  @NotBlank String travelMode
) {
}
