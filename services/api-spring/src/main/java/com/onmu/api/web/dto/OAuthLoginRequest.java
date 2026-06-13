package com.onmu.api.web.dto;

import jakarta.validation.constraints.Size;

public record OAuthLoginRequest(
  @Size(max = 2048) String authorizationCode,
  @Size(max = 4096) String providerAccessToken,
  @Size(max = 4096) String providerIdToken,
  @Size(max = 120) String devVerifiedSubject,
  @Size(max = 80) String displayName,
  @Size(max = 254) String email,
  @Size(max = 2048) String profileImageUrl,
  @Size(max = 512) String state
) {
  public OAuthLoginRequest(
    String authorizationCode,
    String providerAccessToken,
    String devVerifiedSubject,
    String displayName,
    String email,
    String profileImageUrl
  ) {
    this(authorizationCode, providerAccessToken, null, devVerifiedSubject, displayName, email, profileImageUrl, null);
  }

  public OAuthLoginRequest(
    String authorizationCode,
    String providerAccessToken,
    String devVerifiedSubject,
    String displayName,
    String email,
    String profileImageUrl,
    String state
  ) {
    this(authorizationCode, providerAccessToken, null, devVerifiedSubject, displayName, email, profileImageUrl, state);
  }

  public boolean hasVerificationInput() {
    return hasText(authorizationCode)
      || hasText(providerAccessToken)
      || hasText(providerIdToken)
      || hasText(devVerifiedSubject);
  }

  private boolean hasText(String value) {
    return value != null && !value.isBlank();
  }
}
