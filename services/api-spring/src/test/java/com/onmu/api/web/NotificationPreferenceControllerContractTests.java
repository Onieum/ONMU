package com.onmu.api.web;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.onmu.api.service.NotificationPreferenceService;
import com.onmu.api.web.dto.NotificationPreferenceItemResponse;
import com.onmu.api.web.dto.NotificationPreferencesResponse;
import com.onmu.api.web.dto.UpdateNotificationPreferencesRequest;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

class NotificationPreferenceControllerContractTests {
  private static final UUID USER_ID = TestAuthenticatedUserArgumentResolver.USER_ID;

  private NotificationPreferenceService notificationPreferenceService;
  private MockMvc mvc;

  @BeforeEach
  void setUp() {
    notificationPreferenceService = mock(NotificationPreferenceService.class);
    mvc = MockMvcBuilders
      .standaloneSetup(new NotificationPreferenceController(notificationPreferenceService))
      .setCustomArgumentResolvers(new TestAuthenticatedUserArgumentResolver())
      .build();
  }

  @Test
  void preferencesReturnsServerAllowlistViewForCurrentUser() throws Exception {
    when(notificationPreferenceService.preferences(USER_ID)).thenReturn(new NotificationPreferencesResponse(List.of(
      new NotificationPreferenceItemResponse("chat_message", "push", true, Map.of())
    )));

    mvc.perform(get("/api/v1/notification-preferences"))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.preferences[0].notificationType").value("chat_message"))
      .andExpect(jsonPath("$.preferences[0].channel").value("push"))
      .andExpect(jsonPath("$.preferences[0].enabled").value(true));

    verify(notificationPreferenceService).preferences(USER_ID);
  }

  @Test
  void updateAcceptsJsonBodyAndUsesAuthenticatedUser() throws Exception {
    when(notificationPreferenceService.update(eq(USER_ID), any(UpdateNotificationPreferencesRequest.class)))
      .thenReturn(new NotificationPreferencesResponse(List.of(
        new NotificationPreferenceItemResponse("chat_message", "push", false, Map.of("start", "22:00"))
      )));

    mvc.perform(put("/api/v1/notification-preferences")
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
          {
            "preferences": [
              {
                "notificationType": "chat_message",
                "channel": "push",
                "enabled": false,
                "quietHours": {"start": "22:00"}
              }
            ]
          }
          """))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.preferences[0].notificationType").value("chat_message"))
      .andExpect(jsonPath("$.preferences[0].channel").value("push"))
      .andExpect(jsonPath("$.preferences[0].enabled").value(false))
      .andExpect(jsonPath("$.preferences[0].quietHours.start").value("22:00"));

    verify(notificationPreferenceService).update(eq(USER_ID), any(UpdateNotificationPreferencesRequest.class));
  }
}
