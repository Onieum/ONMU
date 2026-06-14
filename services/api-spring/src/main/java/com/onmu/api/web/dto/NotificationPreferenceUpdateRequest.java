package com.onmu.api.web.dto;

import java.util.Map;

public record NotificationPreferenceUpdateRequest(
  String notificationType,
  String channel,
  Boolean enabled,
  Map<String, Object> quietHours
) {
}
