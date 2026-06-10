package com.onmu.api.web.dto;

import jakarta.validation.constraints.NotBlank;

public record UpdateCharacterRequest(
  @NotBlank String skinTone,
  @NotBlank String hairStyle,
  @NotBlank String hairColor,
  @NotBlank String eyeStyle,
  @NotBlank String eyeColor,
  @NotBlank String clothes
) {}
