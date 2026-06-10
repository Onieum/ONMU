package com.onmu.api.web.dto;

public record UploadMediaResponse(
  String storageKey,
  String publicUrl
) {
}
