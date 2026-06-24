package com.onmu.api.web.dto;

import jakarta.validation.constraints.NotBlank;
import java.util.Map;
import java.util.UUID;

public record OotdAvatarGenerationRequest(
  @NotBlank String recordId,
  @NotBlank String inputType,
  UUID outfitPhotoMediaId,
  String outfitPhotoStorageKey,
  String outfitDescription,
  String weather,
  String weatherText,
  String mood,
  String moodText,
  Map<String, Object> characterOverrides
) {}
