package com.onmu.api.web.dto;

import java.time.Instant;
import java.util.UUID;

public record CharacterProfileResponse(
  UUID userId,
  String gender,
  String skinTone,
  String hairStyle,
  String hairColor,
  String eyeStyle,
  String eyeColor,
  String clothes,
  boolean skipped,
  Instant updatedAt
) {}
