package com.onmu.api.web.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record MapPointsRequest(
  @NotBlank String groupId,
  @NotBlank String planId,
  @NotNull @Valid Bounds bounds,
  @Min(0) @Max(22) Integer zoom,
  String category,
  String filter,
  String query
) {
  public record Bounds(
    @NotNull Double south,
    @NotNull Double west,
    @NotNull Double north,
    @NotNull Double east
  ) {
  }
}
