package com.onmu.api.web.dto;

import jakarta.validation.constraints.NotBlank;

public record CreateSchedulePlaceRequest(
  String candidateId,
  @NotBlank String name,
  String startsAt
) {
}
