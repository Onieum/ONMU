package com.onmu.api.web;

import com.onmu.api.service.AuthService;
import com.onmu.api.web.dto.OAuthLoginRequest;
import com.onmu.api.web.dto.RefreshTokenRequest;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import java.util.Map;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {
  private final AuthService authService;

  public AuthController(AuthService authService) {
    this.authService = authService;
  }

  @PostMapping("/oauth/{provider}")
  public Map<String, Object> oauthLogin(
    @PathVariable String provider,
    @Valid @RequestBody OAuthLoginRequest request,
    HttpServletRequest servletRequest
  ) {
    return authService.oauthLogin(provider, request, servletRequest.getRemoteAddr(), servletRequest.getHeader("User-Agent"));
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
}
