package com.onmu.api.web;

import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
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
import com.onmu.api.service.RouteRecommendationService;
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
  private RouteRecommendationService routeRecommendationService;

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
    UserEntity user = authenticatedUser();
    when(groupApiService.groups(user.getId())).thenReturn(List.of(Map.of("id", "2", "name", "내 모임")));

    mvc.perform(get("/api/v1/groups")
        .header(HttpHeaders.AUTHORIZATION, "Bearer test-access-token"))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$[0].id").value("2"));

    verify(groupApiService).groups(eq(user.getId()));
  }

  @Test
  void routeRecommendDelegatesWithValidBearerToken() throws Exception {
    UserEntity user = authenticatedUser();
    when(routeRecommendationService.recommend("1", "101", "walk", user.getId()))
      .thenReturn(Map.of(
        "provider", "dev-mock",
        "travelMode", "walk",
        "geometry", List.of(List.of(126.978, 37.5665))
      ));

    mvc.perform(post("/api/v1/routes/recommend")
        .header(HttpHeaders.AUTHORIZATION, "Bearer test-access-token")
        .contentType(MediaType.APPLICATION_JSON)
        .content("{\"groupId\":\"1\",\"planId\":\"101\",\"travelMode\":\"walk\"}"))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.provider").value("dev-mock"))
      .andExpect(jsonPath("$.travelMode").value("walk"));
  }

  @Test
  void placeSearchResponseIncludesProviderAndCoordinateCounts() throws Exception {
    UserEntity user = authenticatedUser();
    when(onmuApiService.plan("1", "101", user.getId())).thenReturn(Map.of("id", "101"));
    when(placeSearchService.search("홍대 카페", "1", "101", null, null, null, null, null, false))
      .thenReturn(List.of(Map.of(
        "provider", "naver",
        "source", "naver",
        "lat", 37.5665,
        "lng", 126.9780,
        "name", "네이버 후보"
      )));

    mvc.perform(post("/api/v1/place-search")
        .header(HttpHeaders.AUTHORIZATION, "Bearer test-access-token")
        .contentType(MediaType.APPLICATION_JSON)
        .content("{\"query\":\"홍대 카페\",\"groupId\":\"1\",\"planId\":\"101\"}"))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.provider_counts.naver").value(1))
      .andExpect(jsonPath("$.source_counts.naver").value(1))
      .andExpect(jsonPath("$.coordinate_count").value(1))
      .andExpect(jsonPath("$.results[0].provider").value("naver"));

    verify(onmuApiService).plan("1", "101", user.getId());
  }

  @Test
  void placeSearchStopsBeforeProviderLookupWhenPlanAccessIsRejected() throws Exception {
    UserEntity user = authenticatedUser();
    when(onmuApiService.plan("1", "101", user.getId()))
      .thenThrow(new ResponseStatusException(HttpStatus.FORBIDDEN, "not_group_member"));

    mvc.perform(post("/api/v1/place-search")
        .header(HttpHeaders.AUTHORIZATION, "Bearer test-access-token")
        .contentType(MediaType.APPLICATION_JSON)
        .content("{\"query\":\"홍대 카페\",\"groupId\":\"1\",\"planId\":\"101\"}"))
      .andExpect(status().isForbidden())
      .andExpect(status().reason("not_group_member"));

    verify(onmuApiService).plan("1", "101", user.getId());
    verifyNoInteractions(placeSearchService);
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
  void naverOAuthCallbackIsPublicAndRedirectsToMobileScheme() throws Exception {
    mvc.perform(get("/api/v1/auth/oauth/naver/callback")
        .param("code", "auth-code")
        .param("state", "state-123"))
      .andExpect(status().isFound())
      .andExpect(header().string(
        HttpHeaders.LOCATION,
        "io.onieum.onmu://oauth/naver/callback?code=auth-code&state=state-123"
      ));
  }

  @Test
  void kakaoOAuthCallbackIsPublicAndRedirectsToMobileScheme() throws Exception {
    mvc.perform(get("/api/v1/auth/oauth/kakao/callback")
        .param("code", "auth-code")
        .param("state", "state-123"))
      .andExpect(status().isFound())
      .andExpect(header().string(
        HttpHeaders.LOCATION,
        "io.onieum.onmu://oauth/kakao/callback?code=auth-code&state=state-123"
      ));
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

  private UserEntity authenticatedUser() {
    UserEntity user = new UserEntity("usr_test", "ONMU User", null, null);
    when(accessTokenVerifier.verify("test-access-token")).thenReturn("usr_test");
    when(userRepository.findByPublicIdAndDeletedAtIsNull("usr_test"))
      .thenReturn(Optional.of(user));
    return user;
  }
}
