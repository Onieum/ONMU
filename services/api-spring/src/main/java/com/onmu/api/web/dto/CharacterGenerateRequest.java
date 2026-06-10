package com.onmu.api.web.dto;

import jakarta.validation.constraints.NotBlank;

public record CharacterGenerateRequest(
  @NotBlank String keyword
) {}
