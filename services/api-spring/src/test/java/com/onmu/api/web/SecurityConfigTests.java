package com.onmu.api.web;

import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.options;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.onmu.api.config.DevTokenAuthService;
import com.onmu.api.config.DevTokenAuthenticationFilter;
import com.onmu.api.config.SecurityConfig;
import com.onmu.api.service.OnmuApiService;
import com.onmu.api.service.PlaceSearchService;
import java.util.List;
import java.util.Map;
import org.hamcrest.Matchers;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(controllers = {ApiController.class, AuthController.class})
@Import({SecurityConfig.class, DevTokenAuthenticationFilter.class, DevTokenAuthService.class})
@TestPropertySource(properties = {
  "onmu.security.dev-access-token=test-access-token",
  "onmu.security.dev-refresh-token=test-refresh-token",
  "onmu.security.cors.allowed-origins=http://localhost:5173"
})
class SecurityConfigTests {
  @Autowired
  private MockMvc mvc;

  @MockBean
  private OnmuApiService onmuApiService;

  @MockBean
  private PlaceSearchService placeSearchService;

  @Test
  void protectedApiRequiresBearerToken() throws Exception {
    mvc.perform(get("/api/v1/groups"))
      .andExpect(status().isUnauthorized())
      .andExpect(jsonPath("$.error").value("missing_bearer_token"))
      .andExpect(jsonPath("$.authenticated").value(false));
  }

  @Test
  void protectedApiAcceptsValidBearerToken() throws Exception {
    when(onmuApiService.groups()).thenReturn(List.of(Map.of("id", "1", "name", "ONMU Dev")));

    mvc.perform(get("/api/v1/groups")
        .header(HttpHeaders.AUTHORIZATION, "Bearer test-access-token"))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$[0].id").value("1"));
  }

  @Test
  void invalidBearerTokenIsRejected() throws Exception {
    mvc.perform(get("/api/v1/groups")
        .header(HttpHeaders.AUTHORIZATION, "Bearer wrong-token"))
      .andExpect(status().isUnauthorized())
      .andExpect(jsonPath("$.error").value("invalid_bearer_token"));
  }

  @Test
  void sessionReturnsAnonymousWithoutToken() throws Exception {
    mvc.perform(get("/api/v1/auth/session"))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.authenticated").value(false))
      .andExpect(jsonPath("$.status").value("anonymous"));
  }

  @Test
  void sessionReturnsAuthenticatedWithValidToken() throws Exception {
    mvc.perform(get("/api/v1/auth/session")
        .header(HttpHeaders.AUTHORIZATION, "Bearer test-access-token"))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.authenticated").value(true))
      .andExpect(jsonPath("$.authMode").value("spring-dev-token"));
  }

  @Test
  void refreshRejectsInvalidRefreshToken() throws Exception {
    mvc.perform(post("/api/v1/auth/refresh")
        .contentType(MediaType.APPLICATION_JSON)
        .content("{\"refreshToken\":\"wrong-refresh-token\"}"))
      .andExpect(status().isUnauthorized())
      .andExpect(jsonPath("$.error").value("invalid_refresh_token"));
  }

  @Test
  void refreshAcceptsConfiguredRefreshToken() throws Exception {
    mvc.perform(post("/api/v1/auth/refresh")
        .contentType(MediaType.APPLICATION_JSON)
        .content("{\"refreshToken\":\"test-refresh-token\"}"))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.status").value("scaffold"))
      .andExpect(jsonPath("$.tokenType").value("Bearer"))
      .andExpect(jsonPath("$.accessToken").isNotEmpty());
  }

  @Test
  void deleteSessionRequiresAuthentication() throws Exception {
    mvc.perform(delete("/api/v1/auth/session"))
      .andExpect(status().isUnauthorized());
  }

  @Test
  void deleteSessionWorksWithValidToken() throws Exception {
    mvc.perform(delete("/api/v1/auth/session")
        .header(HttpHeaders.AUTHORIZATION, "Bearer test-access-token"))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.deleted").value(true));
  }

  @Test
  void deleteCorsPreflightAllowsConfiguredOrigin() throws Exception {
    mvc.perform(options("/api/v1/auth/session")
        .header(HttpHeaders.ORIGIN, "http://localhost:5173")
        .header(HttpHeaders.ACCESS_CONTROL_REQUEST_METHOD, "DELETE"))
      .andExpect(status().isOk())
      .andExpect(header().string(HttpHeaders.ACCESS_CONTROL_ALLOW_ORIGIN, "http://localhost:5173"))
      .andExpect(header().string(
        HttpHeaders.ACCESS_CONTROL_ALLOW_METHODS,
        Matchers.containsString("DELETE")
      ));
  }
}
