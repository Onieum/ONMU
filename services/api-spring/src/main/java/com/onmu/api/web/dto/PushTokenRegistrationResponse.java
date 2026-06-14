package com.onmu.api.web.dto;

public record PushTokenRegistrationResponse(
  String deviceId,
  String provider,
  String platform,
  String status,
  boolean registered,
  String tokenLast4,
  String updatedAt
) {
}
