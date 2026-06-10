package com.onmu.api.web.dto;

import jakarta.validation.constraints.NotBlank;

public record PresignedUrlRequest(
  @NotBlank String fileName,
  String contentType
) {
}
