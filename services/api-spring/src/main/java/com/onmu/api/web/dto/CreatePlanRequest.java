package com.onmu.api.web.dto;

import jakarta.validation.constraints.NotBlank;
import java.util.List;

public record CreatePlanRequest(
  @NotBlank String title,
  String startsAt,
  String endsAt,
  String placeName,
  String memo,
  List<String> participantUserIds
) {
  public CreatePlanRequest(
    String title,
    String startsAt,
    String endsAt,
    String placeName,
    String memo
  ) {
    this(title, startsAt, endsAt, placeName, memo, List.of());
  }
}
