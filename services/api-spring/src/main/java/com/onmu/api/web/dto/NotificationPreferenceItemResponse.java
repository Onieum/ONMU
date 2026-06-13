package com.onmu.api.web.dto;

import java.util.Map;

public record NotificationPreferenceItemResponse(
  String notificationType,
  String channel,
  boolean enabled,
  Map<String, Object> quietHours
) {
}
