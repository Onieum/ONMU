package com.onmu.api.web.dto;

import jakarta.validation.constraints.NotBlank;
import java.util.List;

public record CreatePlaceCandidateRequest(
  @NotBlank String name,
  String category,
  String address,
  String summary,
  List<String> tags
) {
}
