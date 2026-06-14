package com.onmu.api.web.dto;

public record PushTokenRegistrationRequest(
  String provider,
  String token,
  String platform,
  String appVersion,
  String osVersion,
  String deviceLabel,
  String deviceFingerprintHash
) {
}
