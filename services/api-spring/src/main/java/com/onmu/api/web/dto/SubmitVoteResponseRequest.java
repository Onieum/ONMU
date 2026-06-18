package com.onmu.api.web.dto;

import jakarta.validation.constraints.NotBlank;

public record SubmitVoteResponseRequest(
  @NotBlank String optionId
) {
}
