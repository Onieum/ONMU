package com.onmu.api.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.List;
import java.util.Map;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;

public class DevTokenAuthenticationFilter extends OncePerRequestFilter {
  private static final String BEARER_PREFIX = "Bearer ";

  private final DevTokenAuthService devTokenAuthService;
  private final ObjectMapper objectMapper;

  public DevTokenAuthenticationFilter(DevTokenAuthService devTokenAuthService, ObjectMapper objectMapper) {
    this.devTokenAuthService = devTokenAuthService;
    this.objectMapper = objectMapper;
  }

  @Override
  protected void doFilterInternal(
    HttpServletRequest request,
    HttpServletResponse response,
    FilterChain filterChain
  ) throws ServletException, IOException {
    if (HttpMethod.OPTIONS.matches(request.getMethod())) {
      filterChain.doFilter(request, response);
      return;
    }

    String path = request.getRequestURI();
    boolean apiPath = path.startsWith("/api/v1/");
    boolean protectedApiPath = apiPath && !isAnonymousApiPath(request.getMethod(), path);
    String authorization = request.getHeader(HttpHeaders.AUTHORIZATION);

    if (!StringUtils.hasText(authorization)) {
      if (protectedApiPath) {
        writeUnauthorized(response, "missing_bearer_token");
        return;
      }
      filterChain.doFilter(request, response);
      return;
    }

    if (!authorization.startsWith(BEARER_PREFIX)) {
      if (apiPath) {
        writeUnauthorized(response, "invalid_authorization_header");
        return;
      }
      filterChain.doFilter(request, response);
      return;
    }

    String token = authorization.substring(BEARER_PREFIX.length()).trim();
    if (!devTokenAuthService.isValidAccessToken(token)) {
      writeUnauthorized(response, devTokenAuthService.hasAccessToken()
        ? "invalid_bearer_token"
        : "dev_access_token_not_configured");
      return;
    }

    UsernamePasswordAuthenticationToken authentication = new UsernamePasswordAuthenticationToken(
      "dev-user",
      null,
      List.of(new SimpleGrantedAuthority("ROLE_DEV_USER"))
    );
    SecurityContextHolder.getContext().setAuthentication(authentication);

    filterChain.doFilter(request, response);
  }

  private boolean isAnonymousApiPath(String method, String path) {
    return (
      HttpMethod.GET.matches(method) && "/api/v1/auth/session".equals(path)
    ) || (
      HttpMethod.POST.matches(method) && path.matches("^/api/v1/auth/oauth/[^/]+$")
    ) || (
      HttpMethod.POST.matches(method) && "/api/v1/auth/refresh".equals(path)
    ) || (
      HttpMethod.POST.matches(method) && path.startsWith("/api/v1/internal/callbacks/")
    );
  }

  private void writeUnauthorized(HttpServletResponse response, String error) throws IOException {
    SecurityContextHolder.clearContext();
    response.setStatus(HttpStatus.UNAUTHORIZED.value());
    response.setContentType(MediaType.APPLICATION_JSON_VALUE);
    objectMapper.writeValue(response.getWriter(), Map.of(
      "error", error,
      "authenticated", false
    ));
  }
}
