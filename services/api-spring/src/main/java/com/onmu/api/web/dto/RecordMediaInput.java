package com.onmu.api.web.dto;

public record RecordMediaInput(
  String mediaType,
  String storageKey,
  String publicUrl,
  Integer width,
  Integer height,
  Double durationSeconds,
  Integer sortOrder
) {
}
