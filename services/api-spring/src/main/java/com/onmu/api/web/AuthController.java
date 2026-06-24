package com.onmu.api.web;

import com.onmu.api.service.AuthService;
import com.onmu.api.web.dto.OAuthLoginRequest;
import com.onmu.api.web.dto.RefreshTokenRequest;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import java.net.URI;
import java.util.Map;
import org.springframework.core.env.Environment;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.util.UriComponentsBuilder;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {
  private static final String DEFAULT_NAVER_MOBILE_CALLBACK_URI = "io.onieum.onmu://oauth/naver/callback";
  private static final String DEFAULT_KAKAO_MOBILE_CALLBACK_URI = "io.onieum.onmu://oauth/kakao/callback";
  private static final String KAKAO_LOGOUT_CALLBACK_PATH = "/api/v1/auth/oauth/kakao/logout/callback";

  private final AuthService authService;
  private final Environment environment;

  public AuthController(AuthService authService, Environment environment) {
    this.authService = authService;
    this.environment = environment;
  }

  @PostMapping("/oauth/{provider}")
  public Map<String, Object> oauthLogin(
    @PathVariable String provider,
    @Valid @RequestBody OAuthLoginRequest request,
    HttpServletRequest servletRequest
  ) {
    return authService.oauthLogin(provider, request, servletRequest.getRemoteAddr(), servletRequest.getHeader("User-Agent"));
  }

  @GetMapping("/oauth/naver/callback")
  public ResponseEntity<Void> naverOAuthCallback(
    @RequestParam(required = false) String code,
    @RequestParam(required = false) String state,
    @RequestParam(required = false) String error,
    @RequestParam(name = "error_description", required = false) String errorDescription
  ) {
    return oauthCallback(resolveNaverMobileCallbackUri(), code, state, error, errorDescription);
  }

  @GetMapping("/oauth/kakao/callback")
  public ResponseEntity<Void> kakaoOAuthCallback(
    @RequestParam(required = false) String code,
    @RequestParam(required = false) String state,
    @RequestParam(required = false) String error,
    @RequestParam(name = "error_description", required = false) String errorDescription
  ) {
    return oauthCallback(resolveKakaoMobileCallbackUri(), code, state, error, errorDescription);
  }

  @GetMapping("/oauth/kakao/logout")
  public ResponseEntity<Void> kakaoLogout(HttpServletRequest servletRequest) {
    String clientId = resolveKakaoClientId();
    URI location = UriComponentsBuilder.fromUriString("https://kauth.kakao.com/oauth/logout")
      .queryParam("client_id", clientId)
      .queryParam("logout_redirect_uri", resolveKakaoLogoutRedirectUri(servletRequest))
      .build()
      .encode()
      .toUri();
    return ResponseEntity.status(HttpStatus.FOUND).location(location).build();
  }

  @GetMapping("/oauth/kakao/logout/callback")
  public ResponseEntity<Void> kakaoLogoutCallback() {
    return oauthLogoutCallback(resolveKakaoMobileCallbackUri(), "kakao");
  }

  @GetMapping("/oauth/naver/disconnect/callback")
  public Map<String, Object> naverDisconnectCallback() {
    return Map.of(
      "ok", true,
      "provider", "naver",
      "disconnectReceived", true
    );
  }

  @PostMapping("/oauth/naver/disconnect/callback")
  public Map<String, Object> naverDisconnectCallbackPost() {
    return naverDisconnectCallback();
  }

  @PostMapping("/refresh")
  public Map<String, Object> refresh(
    @Valid @RequestBody RefreshTokenRequest request,
    HttpServletRequest servletRequest
  ) {
    return authService.refresh(request.refreshToken().trim(), servletRequest.getRemoteAddr(), servletRequest.getHeader("User-Agent"));
  }

  @PostMapping("/logout")
  public Map<String, Object> logout(@RequestBody(required = false) RefreshTokenRequest request) {
    return authService.logout(request == null ? null : request.refreshToken());
  }

  @DeleteMapping("/session")
  public Map<String, Object> deleteSession(@RequestBody(required = false) RefreshTokenRequest request) {
    return authService.logout(request == null ? null : request.refreshToken());
  }

  private String resolveNaverMobileCallbackUri() {
    String configured = firstPresent(
      environment.getProperty("NAVER_OAUTH_MOBILE_CALLBACK_URI"),
      environment.getProperty("onmu.oauth.naver.mobile-callback-uri")
    );
    return StringUtils.hasText(configured) ? configured : DEFAULT_NAVER_MOBILE_CALLBACK_URI;
  }

  private String resolveKakaoMobileCallbackUri() {
    String configured = firstPresent(
      environment.getProperty("KAKAO_OAUTH_MOBILE_CALLBACK_URI"),
      environment.getProperty("onmu.oauth.kakao.mobile-callback-uri")
    );
    return StringUtils.hasText(configured) ? configured : DEFAULT_KAKAO_MOBILE_CALLBACK_URI;
  }

  private String resolveKakaoClientId() {
    String configured = firstPresent(
      environment.getProperty("KAKAO_REST_API_KEY"),
      environment.getProperty("onmu.oauth.kakao.client-id")
    );
    if (StringUtils.hasText(configured)) {
      return configured.trim();
    }
    throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, "kakao_client_id_missing");
  }

  private String resolveKakaoLogoutRedirectUri(HttpServletRequest request) {
    String explicitRedirectUri = firstPresent(environment.getProperty("KAKAO_OAUTH_LOGOUT_REDIRECT_URI"));
    if (StringUtils.hasText(explicitRedirectUri)) {
      return explicitRedirectUri;
    }
    String publicBaseUrl = firstPresent(
      environment.getProperty("ONMU_PUBLIC_BASE_URL"),
      environment.getProperty("onmu.public-base-url")
    );
    if (StringUtils.hasText(publicBaseUrl)) {
      return appendPath(publicBaseUrl, KAKAO_LOGOUT_CALLBACK_PATH);
    }
    String scheme = firstPresent(request.getHeader("X-Forwarded-Proto"), request.getScheme());
    String host = firstPresent(request.getHeader("X-Forwarded-Host"), request.getServerName());
    String forwardedPort = firstPresent(request.getHeader("X-Forwarded-Port"));
    int port = parsePort(forwardedPort, request.getServerPort());
    UriComponentsBuilder builder = UriComponentsBuilder.newInstance()
      .scheme(scheme)
      .host(trimHost(host))
      .path(KAKAO_LOGOUT_CALLBACK_PATH);
    if (!isDefaultPort(scheme, port)) {
      builder.port(port);
    }
    return builder.build().toUriString();
  }

  private ResponseEntity<Void> oauthCallback(
    String mobileCallbackUri,
    String code,
    String state,
    String error,
    String errorDescription
  ) {
    UriComponentsBuilder builder = UriComponentsBuilder.fromUriString(mobileCallbackUri);
    addQueryParam(builder, "code", code);
    addQueryParam(builder, "state", state);
    addQueryParam(builder, "error", error);
    addQueryParam(builder, "error_description", errorDescription);
    URI location = builder.build().encode().toUri();
    return ResponseEntity.status(HttpStatus.FOUND).location(location).build();
  }

  private ResponseEntity<Void> oauthLogoutCallback(String mobileCallbackUri, String provider) {
    UriComponentsBuilder builder = UriComponentsBuilder.fromUriString(mobileCallbackUri);
    builder.queryParam("logout", "true");
    builder.queryParam("provider", provider);
    URI location = builder.build().encode().toUri();
    return ResponseEntity.status(HttpStatus.FOUND).location(location).build();
  }

  private void addQueryParam(UriComponentsBuilder builder, String name, String value) {
    if (StringUtils.hasText(value)) {
      builder.queryParam(name, value.trim());
    }
  }

  private String firstPresent(String... candidates) {
    for (String candidate : candidates) {
      if (StringUtils.hasText(candidate)) {
        return candidate.trim();
      }
    }
    return "";
  }

  private String appendPath(String baseUrl, String path) {
    UriComponentsBuilder builder = UriComponentsBuilder.fromUriString(baseUrl.trim());
    String existingPath = builder.build().getPath();
    if (!StringUtils.hasText(existingPath)) {
      builder.path(path);
    } else if (existingPath.endsWith("/")) {
      builder.path(path.substring(1));
    } else {
      builder.path(path);
    }
    return builder.build().toUriString();
  }

  private int parsePort(String portValue, int fallbackPort) {
    if (!StringUtils.hasText(portValue)) {
      return fallbackPort;
    }
    try {
      return Integer.parseInt(portValue.trim());
    } catch (NumberFormatException ignored) {
      return fallbackPort;
    }
  }

  private boolean isDefaultPort(String scheme, int port) {
    return ("http".equalsIgnoreCase(scheme) && port == 80)
      || ("https".equalsIgnoreCase(scheme) && port == 443);
  }

  private String trimHost(String host) {
    String trimmed = firstPresent(host);
    if (!StringUtils.hasText(trimmed)) {
      return "";
    }
    int commaIndex = trimmed.indexOf(',');
    String firstHost = commaIndex >= 0 ? trimmed.substring(0, commaIndex).trim() : trimmed;
    int colonIndex = firstHost.indexOf(':');
    return colonIndex >= 0 ? firstHost.substring(0, colonIndex) : firstHost;
  }
}
