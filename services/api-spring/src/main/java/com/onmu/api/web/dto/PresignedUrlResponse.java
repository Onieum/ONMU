package com.onmu.api.web.dto;

public record PresignedUrlResponse(
  String uploadUrl,
  String storageKey,
  String publicUrl
) {
}
