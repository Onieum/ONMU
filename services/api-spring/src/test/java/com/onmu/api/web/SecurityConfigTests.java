package com.onmu.api.web;

import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.options;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.onmu.api.config.SecurityConfig;
import com.onmu.api.domain.UserEntity;
import com.onmu.api.domain.UserRepository;
import com.onmu.api.security.AccessTokenVerifier;
import com.onmu.api.security.BearerTokenAuthenticationFilter;
import com.onmu.api.service.AuthService;
import com.onmu.api.service.GroupApiService;
import com.onmu.api.service.OnmuApiService;
import com.onmu.api.service.PlaceSearchService;
import com.onmu.api.service.SettlementApiService;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import org.hamcrest.Matchers;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.web.server.ResponseStatusException;

@WebMvcTest(controllers = {ApiController.class, AuthController.class, SessionController.class})
@Import({SecurityConfig.class, BearerTokenAuthenticationFilter.class})
@TestPropertySource(properties = {
  "ONMU_API_ACCESS_TOKEN=test-access-token",
  "ONMU_API_REFRESH_TOKEN=test-refresh-token",
  "ONMU_CORS_ORIGINS=http://localhost:5173",
  "onmu.security.access-token=test-access-token",
  "onmu.security.refresh-token=test-refresh-token",
  "onmu.security.dev-access-token=test-access-token",
  "onmu.security.dev-refresh-token=test-refresh-token",
  "onmu.security.cors.allowed-origins=http://localhost:5173",
  "onmu.auth.access-token-secret=test-access-token-secret-with-enough-length",
  "onmu.access-log.path=target/test-security-config-api-access.log"
})
class SecurityConfigTests {
  @Autowired
  private MockMvc mvc;

  @MockitoBean
  private GroupApiService groupApiService;

  @MockitoBean
  private OnmuApiService onmuApiService;

  @MockitoBean
  private PlaceSearchService placeSearchService;

  @MockitoBean
  private AuthService authService;

  @MockitoBean
  private AccessTokenVerifier accessTokenVerifier;

  @MockitoBean
  private UserRepository userRepository;
  
  @MockitoBean
  private SettlementApiService settlementApiService;

  @Test
  void protectedApiRequiresBearerToken() throws Exception {
    mvc.perform(get("/api/v1/groups"))
      .andExpect(status().isUnauthorized())
      .andExpect(jsonPath("$.ok").value(false))
      .andExpect(jsonPath("$.error").value("authentication_required"));
  }

  @Test
  void protectedApiAcceptsValidBearerToken() throws Exception {
    authenticatedUser();
    when(onmuApiService.groups()).thenReturn(List.of(Map.of("id", "1", "name", "ONMU Dev")));

    mvc.perform(get("/api/v1/groups")
        .header(HttpHeaders.AUTHORIZATION, "Bearer test-access-token"))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$[0].id").value("1"));
  }

  @Test
  void invalidBearerTokenIsRejected() throws Exception {
    when(accessTokenVerifier.verify("wrong-token"))
      .thenThrow(new ResponseStatusException(HttpStatus.UNAUTHORIZED, "invalid_token"));

    mvc.perform(get("/api/v1/groups")
        .header(HttpHeaders.AUTHORIZATION, "Bearer wrong-token"))
      .andExpect(status().isUnauthorized())
      .andExpect(jsonPath("$.ok").value(false))
      .andExpect(jsonPath("$.error").value("invalid_token"));
  }

  @Test
  void sessionRequiresAuthentication() throws Exception {
    mvc.perform(get("/api/v1/auth/session"))
      .andExpect(status().isUnauthorized())
      .andExpect(jsonPath("$.error").value("authentication_required"));
  }

  @Test
  void sessionReturnsAuthenticatedUserWithValidToken() throws Exception {
    authenticatedUser();

    mvc.perform(get("/api/v1/auth/session")
        .header(HttpHeaders.AUTHORIZATION, "Bearer test-access-token"))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.authenticated").value(true))
      .andExpect(jsonPath("$.user.id").value("usr_test"));
  }

  @Test
  void refreshEndpointIsPublicAndDelegatesToAuthService() throws Exception {
    when(authService.refresh("test-refresh-token", "127.0.0.1", null))
      .thenReturn(Map.of("ok", true, "authenticated", true));

    mvc.perform(post("/api/v1/auth/refresh")
        .contentType(MediaType.APPLICATION_JSON)
        .content("{\"refreshToken\":\"test-refresh-token\"}"))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.ok").value(true));
  }

  @Test
  void logoutEndpointIsPublic() throws Exception {
    when(authService.logout("test-refresh-token"))
      .thenReturn(Map.of("ok", true, "authenticated", false));

    mvc.perform(post("/api/v1/auth/logout")
        .contentType(MediaType.APPLICATION_JSON)
        .content("{\"refreshToken\":\"test-refresh-token\"}"))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.authenticated").value(false));
  }

  @Test
  void contractDeleteSessionEndpointIsPublic() throws Exception {
    when(authService.logout("test-refresh-token"))
      .thenReturn(Map.of("ok", true, "authenticated", false));

    mvc.perform(delete("/api/v1/auth/session")
        .contentType(MediaType.APPLICATION_JSON)
        .content("{\"refreshToken\":\"test-refresh-token\"}"))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.authenticated").value(false));
  }

  @Test
  void corsPreflightAllowsConfiguredOriginAndRequestHeaders() throws Exception {
    mvc.perform(options("/api/v1/auth/session")
        .header(HttpHeaders.ORIGIN, "http://localhost:5173")
        .header(HttpHeaders.ACCESS_CONTROL_REQUEST_METHOD, "PATCH")
        .header(HttpHeaders.ACCESS_CONTROL_REQUEST_HEADERS, "authorization,x-request-id,x-correlation-id"))
      .andExpect(status().isOk())
      .andExpect(header().string(HttpHeaders.ACCESS_CONTROL_ALLOW_ORIGIN, "http://localhost:5173"))
      .andExpect(header().string(
        HttpHeaders.ACCESS_CONTROL_ALLOW_METHODS,
        Matchers.containsString("PATCH")
      ))
      .andExpect(header().string(
        HttpHeaders.ACCESS_CONTROL_ALLOW_HEADERS,
        Matchers.containsString("x-request-id")
      ))
      .andExpect(header().string(
        HttpHeaders.ACCESS_CONTROL_ALLOW_HEADERS,
        Matchers.containsString("x-correlation-id")
      ));
  }

  @Test
  void corsPreflightKeepsDefaultLocalOriginsWhenConfiguredOriginsArePresent() throws Exception {
    mvc.perform(options("/api/v1/auth/session")
        .header(HttpHeaders.ORIGIN, "http://localhost:3000")
        .header(HttpHeaders.ACCESS_CONTROL_REQUEST_METHOD, "GET")
        .header(HttpHeaders.ACCESS_CONTROL_REQUEST_HEADERS, "authorization,content-type"))
      .andExpect(status().isOk())
      .andExpect(header().string(HttpHeaders.ACCESS_CONTROL_ALLOW_ORIGIN, "http://localhost:3000"));
  }

  @Test
  void corsResponseExposesRequestIdHeader() throws Exception {
    authenticatedUser();

    mvc.perform(get("/api/v1/auth/session")
        .header(HttpHeaders.ORIGIN, "http://localhost:5173")
        .header(HttpHeaders.AUTHORIZATION, "Bearer test-access-token")
        .header("X-Request-Id", "request-id-from-client"))
      .andExpect(status().isOk())
      .andExpect(header().string("X-Request-Id", "request-id-from-client"))
      .andExpect(header().string(
        HttpHeaders.ACCESS_CONTROL_EXPOSE_HEADERS,
        Matchers.containsString("X-Request-Id")
      ));
  }

  private void authenticatedUser() {
    when(accessTokenVerifier.verify("test-access-token")).thenReturn("usr_test");
    when(userRepository.findByPublicIdAndDeletedAtIsNull("usr_test"))
      .thenReturn(Optional.of(new UserEntity("usr_test", "ONMU User", null, null)));
  }
}
