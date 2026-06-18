package com.onmu.api.service;

public record NaverUserInfo(
  String id,
  String providerProfileName,
  String email,
  String profileImageUrl
) {
}
