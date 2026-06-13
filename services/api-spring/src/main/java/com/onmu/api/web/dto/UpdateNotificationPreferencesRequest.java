package com.onmu.api.web.dto;

import java.util.List;

public record UpdateNotificationPreferencesRequest(
  List<NotificationPreferenceUpdateRequest> preferences
) {
}
