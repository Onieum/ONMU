package com.onmu.api.web.dto;

import java.util.Map;

public record FriendResponse(
  String userId,
  String publicId,
  String userCode,
  String nickname,
  String profileImageUrl,
  Map<String, Object> pixelCharacter,
  String memo,
  String introText,
  boolean useDefaultProfileImage,
  boolean favorite
) {
}
