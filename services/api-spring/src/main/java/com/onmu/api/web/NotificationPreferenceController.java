package com.onmu.api.web;

import com.onmu.api.security.AuthenticatedUser;
import com.onmu.api.service.NotificationPreferenceService;
import com.onmu.api.web.dto.NotificationPreferencesResponse;
import com.onmu.api.web.dto.UpdateNotificationPreferencesRequest;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/notification-preferences")
public class NotificationPreferenceController {
  private final NotificationPreferenceService notificationPreferenceService;

  public NotificationPreferenceController(NotificationPreferenceService notificationPreferenceService) {
    this.notificationPreferenceService = notificationPreferenceService;
  }

  @GetMapping
  public NotificationPreferencesResponse preferences(
    @AuthenticationPrincipal AuthenticatedUser user
  ) {
    return notificationPreferenceService.preferences(user.userId());
  }

  @PutMapping
  public NotificationPreferencesResponse update(
    @AuthenticationPrincipal AuthenticatedUser user,
    @RequestBody(required = false) UpdateNotificationPreferencesRequest request
  ) {
    return notificationPreferenceService.update(user.userId(), request);
  }
}
