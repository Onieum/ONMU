package com.onmu.api.service;

public record VerifiedOAuthIdentity(
  String provider,
  String providerSubject,
  String providerProfileName,
  String email,
  String profileImageUrl
) {
}
