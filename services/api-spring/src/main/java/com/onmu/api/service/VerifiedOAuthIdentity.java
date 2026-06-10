package com.onmu.api.service;

public record VerifiedOAuthIdentity(
  String provider,
  String providerSubject,
  String displayName,
  String email,
  String profileImageUrl
) {
}
