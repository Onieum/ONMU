package com.onmu.api.web;

import static org.hamcrest.Matchers.not;
import static org.hamcrest.Matchers.containsString;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.onmu.api.service.PushTokenService;
import com.onmu.api.web.dto.PushTokenRegistrationRequest;
import com.onmu.api.web.dto.PushTokenRegistrationResponse;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

class DeviceControllerContractTests {
  private static final UUID USER_ID = TestAuthenticatedUserArgumentResolver.USER_ID;
  private static final String RAW_TOKEN = "synthetic-dev-token-1234567890";

  private PushTokenService pushTokenService;
  private MockMvc mvc;

  @BeforeEach
  void setUp() {
    pushTokenService = mock(PushTokenService.class);
    mvc = MockMvcBuilders
      .standaloneSetup(new DeviceController(pushTokenService))
      .setCustomArgumentResolvers(new TestAuthenticatedUserArgumentResolver())
      .build();
  }

  @Test
  void registerPushTokenReturnsOnlyReadinessMetadata() throws Exception {
    when(pushTokenService.register(eq(USER_ID), any(PushTokenRegistrationRequest.class)))
      .thenReturn(new PushTokenRegistrationResponse(
        "00000000-0000-0000-0000-00000000d001",
        "dev",
        "android",
        "active",
        true,
        "7890",
        "2026-06-18T01:00:00Z"
      ));

    mvc.perform(post("/api/v1/devices/push-token")
        .contentType(MediaType.APPLICATION_JSON)
        .content(requestBody()))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.provider").value("dev"))
      .andExpect(jsonPath("$.platform").value("android"))
      .andExpect(jsonPath("$.status").value("active"))
      .andExpect(jsonPath("$.registered").value(true))
      .andExpect(jsonPath("$.tokenLast4").value("7890"))
      .andExpect(content().string(not(containsString(RAW_TOKEN))));

    verify(pushTokenService).register(eq(USER_ID), any(PushTokenRegistrationRequest.class));
  }

  @Test
  void deactivatePushTokenUsesRequestBodyWithoutLeakingRawToken() throws Exception {
    when(pushTokenService.deactivate(eq(USER_ID), any(PushTokenRegistrationRequest.class)))
      .thenReturn(new PushTokenRegistrationResponse(
        "00000000-0000-0000-0000-00000000d001",
        "dev",
        "android",
        "inactive",
        false,
        "7890",
        "2026-06-18T01:01:00Z"
      ));

    mvc.perform(delete("/api/v1/devices/push-token")
        .contentType(MediaType.APPLICATION_JSON)
        .content(requestBody()))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.provider").value("dev"))
      .andExpect(jsonPath("$.status").value("inactive"))
      .andExpect(jsonPath("$.registered").value(false))
      .andExpect(content().string(not(containsString(RAW_TOKEN))));

    verify(pushTokenService).deactivate(eq(USER_ID), any(PushTokenRegistrationRequest.class));
  }

  private String requestBody() {
    return """
      {
        "provider": "dev",
        "token": "%s",
        "platform": "android",
        "appVersion": "1.0.0",
        "osVersion": "android-test",
        "deviceLabel": "staging-smoke",
        "deviceFingerprintHash": "synthetic-device-hash"
      }
      """.formatted(RAW_TOKEN);
  }
}
