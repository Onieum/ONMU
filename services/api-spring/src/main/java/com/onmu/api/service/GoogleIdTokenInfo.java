package com.onmu.api.service;

import java.time.Instant;

public record GoogleIdTokenInfo(
  String issuer,
  String audience,
  String subject,
  Instant expiresAt,
  String displayName,
  String email,
  String profileImageUrl
) {
}
