package com.onmu.api.web.dto;

import java.time.Instant;

public record OotdAvatarGenerationResponse(
  String jobId,
  String status,
  String recordId,
  String generatedImageUrl,
  String errorCode,
  boolean retryable,
  Instant createdAt,
  Instant updatedAt
) {}
