package com.onmu.api.service;

public record KakaoUserInfo(
  String id,
  String displayName,
  String email,
  String profileImageUrl
) {
}
