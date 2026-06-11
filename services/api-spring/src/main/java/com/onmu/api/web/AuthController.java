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

@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {
  private static final String DEFAULT_NAVER_MOBILE_CALLBACK_URI = "io.onieum.onmu://oauth/naver/callback";
  private static final String DEFAULT_KAKAO_MOBILE_CALLBACK_URI = "io.onieum.onmu://oauth/kakao/callback";

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
}
