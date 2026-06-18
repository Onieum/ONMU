package com.onmu.api.service;

public record KakaoUserInfo(
  String id,
  String providerProfileName,
  String email,
  String profileImageUrl
) {
}
