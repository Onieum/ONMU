package com.onmu.api.web.dto;

public record FriendResponse(
  String userId,
  String publicId,
  String userCode,
  String nickname,
  String profileImageUrl,
  String memo,
  String introText,
  boolean favorite
) {
}
