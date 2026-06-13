package com.onmu.api.web.dto;

import java.util.List;

public record NotificationPreferencesResponse(
  List<NotificationPreferenceItemResponse> preferences
) {
}
