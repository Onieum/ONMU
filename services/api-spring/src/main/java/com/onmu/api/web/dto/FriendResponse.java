package com.onmu.api.web.dto;

public record FriendResponse(
  String userId,
  String publicId,
  String userCode,
  String displayName,
  String nickname,
  String profileImageUrl,
  String memo,
  boolean favorite
) {
}
