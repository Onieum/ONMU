package com.onmu.api.web.dto;

import jakarta.validation.constraints.NotBlank;
import java.util.List;
import java.util.Map;

public record PlaceReasonCallbackRequest(
  String groupId,
  String planId,
  @NotBlank String candidateId,
  @NotBlank String status,
  String summary,
  List<String> reasons,
  Map<String, Object> recommendation,
  String jobRunId,
  String promptRunId,
  String errorCode
) {
}
