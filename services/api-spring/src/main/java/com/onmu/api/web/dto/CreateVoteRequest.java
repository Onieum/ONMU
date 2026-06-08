package com.onmu.api.web.dto;

import jakarta.validation.constraints.NotBlank;
import java.util.List;

public record CreateVoteRequest(
  @NotBlank String voteType,
  String targetType,
  String targetId,
  @NotBlank String title,
  List<String> options
) {
}
