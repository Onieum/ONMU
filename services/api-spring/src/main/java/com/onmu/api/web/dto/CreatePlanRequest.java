package com.onmu.api.web.dto;

import jakarta.validation.constraints.NotBlank;

public record CreatePlanRequest(
  @NotBlank String title,
  String startsAt,
  String placeName
) {
}
