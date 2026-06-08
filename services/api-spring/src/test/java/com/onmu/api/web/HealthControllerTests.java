package com.onmu.api.web;

import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.onmu.api.service.ReadinessProbeService;
import com.onmu.api.service.ReadinessProbeService.ReadinessReport;
import java.util.Map;
import org.junit.jupiter.api.Test;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

class HealthControllerTests {
  @Test
  void readyzReturnsDependencyShapeWhenAllDependenciesAreReady() throws Exception {
    ReadinessProbeService readinessProbeService = org.mockito.Mockito.mock(ReadinessProbeService.class);
    when(readinessProbeService.check()).thenReturn(new ReadinessReport(true, Map.of(
      "postgres", Map.of("ok", true, "required", true, "detail", "connection_valid"),
      "redis", Map.of("ok", true, "required", true, "detail", "tcp_connect_ok"),
      "minio", Map.of("ok", true, "required", true, "detail", "http_200")
    )));
    MockMvc mvc = MockMvcBuilders.standaloneSetup(new HealthController(readinessProbeService, "test")).build();

    mvc.perform(get("/readyz"))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.ok").value(true))
      .andExpect(jsonPath("$.dependencies.postgres.required").value(true))
      .andExpect(jsonPath("$.dependencies.redis.detail").value("tcp_connect_ok"))
      .andExpect(jsonPath("$.dependencies.minio.detail").value("http_200"));
  }

  @Test
  void readyzReturns503WhenAnyDependencyFails() throws Exception {
    ReadinessProbeService readinessProbeService = org.mockito.Mockito.mock(ReadinessProbeService.class);
    when(readinessProbeService.check()).thenReturn(new ReadinessReport(false, Map.of(
      "postgres", Map.of("ok", true, "required", true, "detail", "connection_valid"),
      "redis", Map.of("ok", false, "required", true, "error", "ConnectException"),
      "minio", Map.of("ok", true, "required", true, "detail", "http_200")
    )));
    MockMvc mvc = MockMvcBuilders.standaloneSetup(new HealthController(readinessProbeService, "test")).build();

    mvc.perform(get("/readyz"))
      .andExpect(status().isServiceUnavailable())
      .andExpect(jsonPath("$.ok").value(false))
      .andExpect(jsonPath("$.dependencies.redis.ok").value(false))
      .andExpect(jsonPath("$.dependencies.redis.error").value("ConnectException"));
  }
}
