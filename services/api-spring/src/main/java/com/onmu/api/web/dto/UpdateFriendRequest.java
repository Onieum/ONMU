package com.onmu.api.web.dto;

public record UpdateFriendRequest(
  String memo,
  Boolean favorite
) {
}
