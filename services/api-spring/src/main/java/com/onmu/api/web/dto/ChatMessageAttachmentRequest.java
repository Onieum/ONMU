package com.onmu.api.web.dto;

public record ChatMessageAttachmentRequest(
  String type,
  String storageKey,
  String publicUrl,
  String contentType,
  String fileName,
  Integer width,
  Integer height
) {
}
