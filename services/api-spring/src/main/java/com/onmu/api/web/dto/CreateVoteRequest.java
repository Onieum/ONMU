package com.onmu.api.web.dto;

import jakarta.validation.constraints.NotBlank;
import java.util.List;

public record CreateVoteRequest(
  @NotBlank String voteType,
  String targetType,
  String targetId,
  @NotBlank String title,
  List<String> options,
  List<String> placeCandidateIds
) {
  public CreateVoteRequest(
    String voteType,
    String targetType,
    String targetId,
    String title,
    List<String> options
  ) {
    this(voteType, targetType, targetId, title, options, List.of());
  }
}
