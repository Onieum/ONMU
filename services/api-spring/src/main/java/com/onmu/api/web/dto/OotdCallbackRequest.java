package com.onmu.api.web.dto;

import jakarta.validation.constraints.NotBlank;
import java.util.List;
import java.util.Map;

public record OotdCallbackRequest(
  @NotBlank String recordId,
  Map<String, Object> features,
  List<String> tags,
  String imageUrl,
  String status,
  String errorMessage
) {
}
