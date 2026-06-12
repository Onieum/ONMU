package com.onmu.api.web.dto;

import jakarta.validation.constraints.NotBlank;

public record AddFriendRequest(
  @NotBlank String publicId,
  String memo
) {
}
