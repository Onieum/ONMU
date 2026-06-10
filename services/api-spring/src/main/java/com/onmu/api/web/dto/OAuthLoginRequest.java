package com.onmu.api.web.dto;

import jakarta.validation.constraints.Size;

public record OAuthLoginRequest(
  @Size(max = 2048) String authorizationCode,
  @Size(max = 4096) String providerAccessToken,
  @Size(max = 120) String devVerifiedSubject,
  @Size(max = 80) String displayName,
  @Size(max = 254) String email,
  @Size(max = 2048) String profileImageUrl
) {
  public boolean hasVerificationInput() {
    return hasText(authorizationCode) || hasText(providerAccessToken) || hasText(devVerifiedSubject);
  }

  private boolean hasText(String value) {
    return value != null && !value.isBlank();
  }
}
