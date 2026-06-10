package com.onmu.api.web;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.onmu.api.config.DevTokenAuthService;
import com.onmu.api.config.DevTokenAuthenticationFilter;
import com.onmu.api.config.SecurityConfig;
import com.onmu.api.service.RecordService;
import com.onmu.api.web.dto.OotdCallbackRequest;
import java.util.Collections;
import java.util.Map;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(controllers = {InternalCallbackController.class})
@Import({SecurityConfig.class, DevTokenAuthenticationFilter.class, DevTokenAuthService.class})
@TestPropertySource(properties = {
  "onmu.security.dev-access-token=test-access-token",
  "onmu.security.dev-refresh-token=test-refresh-token",
  "ONMU_INTERNAL_SECRET=test-secret-key",
  "onmu.access-log.path=target/test-callback-api-access.log"
})
class InternalCallbackControllerTests {
  @Autowired
  private MockMvc mvc;

  @MockBean
  private RecordService recordService;

  @Autowired
  private ObjectMapper objectMapper;

  @Test
  void callbackFailsWhenSecretHeaderIsMissing() throws Exception {
    OotdCallbackRequest request = new OotdCallbackRequest(
      "rec_123",
      Collections.emptyMap(),
      Collections.emptyList(),
      "http://image",
      "SUCCESS",
      null
    );

    mvc.perform(post("/api/v1/internal/callbacks/ootd")
        .contentType(MediaType.APPLICATION_JSON)
        .content(objectMapper.writeValueAsString(request)))
      .andExpect(status().isForbidden());
  }

  @Test
  void callbackFailsWhenSecretHeaderIsIncorrect() throws Exception {
    OotdCallbackRequest request = new OotdCallbackRequest(
      "rec_123",
      Collections.emptyMap(),
      Collections.emptyList(),
      "http://image",
      "SUCCESS",
      null
    );

    mvc.perform(post("/api/v1/internal/callbacks/ootd")
        .header("X-Internal-Secret", "wrong-secret-key")
        .contentType(MediaType.APPLICATION_JSON)
        .content(objectMapper.writeValueAsString(request)))
      .andExpect(status().isForbidden());
  }

  @Test
  void callbackSucceedsWithCorrectSecretHeaderAndNoBearerToken() throws Exception {
    OotdCallbackRequest request = new OotdCallbackRequest(
      "rec_123",
      Collections.emptyMap(),
      Collections.emptyList(),
      "http://image",
      "SUCCESS",
      null
    );

    when(recordService.processOotdCallback(any(OotdCallbackRequest.class)))
      .thenReturn(Map.of("aiStatus", "SUCCESS"));

    mvc.perform(post("/api/v1/internal/callbacks/ootd")
        .header("X-Internal-Secret", "test-secret-key")
        .contentType(MediaType.APPLICATION_JSON)
        .content(objectMapper.writeValueAsString(request)))
      .andExpect(status().isOk());
  }
}
