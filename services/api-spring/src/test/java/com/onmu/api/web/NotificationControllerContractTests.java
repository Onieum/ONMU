package com.onmu.api.web;

import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.onmu.api.service.NotificationService;
import com.onmu.api.web.dto.NotificationItemResponse;
import com.onmu.api.web.dto.NotificationReadAllResponse;
import com.onmu.api.web.dto.NotificationUnreadCountResponse;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

class NotificationControllerContractTests {
  private static final UUID USER_ID = TestAuthenticatedUserArgumentResolver.USER_ID;
  private static final UUID NOTIFICATION_ID = UUID.fromString("00000000-0000-0000-0000-000000001211");

  private NotificationService notificationService;
  private MockMvc mvc;

  @BeforeEach
  void setUp() {
    notificationService = mock(NotificationService.class);
    mvc = MockMvcBuilders
      .standaloneSetup(new NotificationController(notificationService))
      .setCustomArgumentResolvers(new TestAuthenticatedUserArgumentResolver())
      .build();
  }

  @Test
  void inboxPassesAuthenticatedUserAndLimitToService() throws Exception {
    when(notificationService.inbox(USER_ID, 25)).thenReturn(List.of(new NotificationItemResponse(
      NOTIFICATION_ID.toString(),
      "chat_message",
      "chat_message",
      "새 메시지",
      "메시지를 확인해 주세요.",
      "queued",
      null,
      "2026-06-18T01:00:00Z",
      "01:00",
      "1",
      "101",
      Map.of("messageId", "message-1"),
      false
    )));

    mvc.perform(get("/api/v1/notifications")
        .queryParam("limit", "25"))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$[0].id").value(NOTIFICATION_ID.toString()))
      .andExpect(jsonPath("$[0].notificationType").value("chat_message"))
      .andExpect(jsonPath("$[0].payload.messageId").value("message-1"))
      .andExpect(jsonPath("$[0].isRead").value(false));

    verify(notificationService).inbox(USER_ID, 25);
  }

  @Test
  void unreadCountReturnsCurrentUserProjectionOnly() throws Exception {
    when(notificationService.unreadCount(USER_ID)).thenReturn(new NotificationUnreadCountResponse(3L));

    mvc.perform(get("/api/v1/notifications/unread-count"))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.unreadCount").value(3));

    verify(notificationService).unreadCount(USER_ID);
  }

  @Test
  void markReadUsesPathNotificationIdAndAuthenticatedUser() throws Exception {
    when(notificationService.markRead(eq(USER_ID), eq(NOTIFICATION_ID)))
      .thenReturn(new NotificationItemResponse(
        NOTIFICATION_ID.toString(),
        "chat_message",
        "chat_message",
        "새 메시지",
        "메시지를 확인해 주세요.",
        "read",
        "2026-06-18T01:01:00Z",
        "2026-06-18T01:00:00Z",
        "01:00",
        "1",
        "101",
        Map.of(),
        true
      ));

    mvc.perform(put("/api/v1/notifications/{notificationId}/read", NOTIFICATION_ID))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.id").value(NOTIFICATION_ID.toString()))
      .andExpect(jsonPath("$.status").value("read"))
      .andExpect(jsonPath("$.isRead").value(true));

    verify(notificationService).markRead(USER_ID, NOTIFICATION_ID);
  }

  @Test
  void readAllUsesOnlyAuthenticatedUserScope() throws Exception {
    when(notificationService.markAllRead(USER_ID)).thenReturn(new NotificationReadAllResponse(2));

    mvc.perform(put("/api/v1/notifications/read-all"))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.updatedCount").value(2));

    verify(notificationService).markAllRead(USER_ID);
  }
}
