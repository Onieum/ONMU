package com.onmu.api.web;

import com.onmu.api.security.AuthenticatedUser;
import com.onmu.api.service.NotificationService;
import com.onmu.api.web.dto.NotificationItemResponse;
import com.onmu.api.web.dto.NotificationReadAllResponse;
import com.onmu.api.web.dto.NotificationUnreadCountResponse;
import java.util.List;
import java.util.UUID;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/notifications")
public class NotificationController {
  private final NotificationService notificationService;

  public NotificationController(NotificationService notificationService) {
    this.notificationService = notificationService;
  }

  @GetMapping
  public List<NotificationItemResponse> inbox(
    @AuthenticationPrincipal AuthenticatedUser user,
    @RequestParam(required = false) Integer limit
  ) {
    return notificationService.inbox(user.userId(), limit);
  }

  @GetMapping("/unread-count")
  public NotificationUnreadCountResponse unreadCount(
    @AuthenticationPrincipal AuthenticatedUser user
  ) {
    return notificationService.unreadCount(user.userId());
  }

  @PutMapping("/{notificationId}/read")
  public NotificationItemResponse markRead(
    @AuthenticationPrincipal AuthenticatedUser user,
    @PathVariable UUID notificationId
  ) {
    return notificationService.markRead(user.userId(), notificationId);
  }

  @PutMapping("/read-all")
  public NotificationReadAllResponse markAllRead(
    @AuthenticationPrincipal AuthenticatedUser user
  ) {
    return notificationService.markAllRead(user.userId());
  }
}
