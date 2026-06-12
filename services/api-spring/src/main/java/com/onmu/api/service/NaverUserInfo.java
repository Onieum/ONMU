package com.onmu.api.service;

public record NaverUserInfo(
  String id,
  String displayName,
  String email,
  String profileImageUrl
) {
}
