package com.onmu.api.config;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.LinkedHashMap;
import java.util.Map;
import org.springframework.core.env.Environment;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

@Component
public class DevTokenAuthService {
  private final Environment environment;

  public DevTokenAuthService(Environment environment) {
    this.environment = environment;
  }

  public boolean hasAccessToken() {
    return StringUtils.hasText(accessToken());
  }

  public boolean isValidAccessToken(String token) {
    return constantTimeEquals(accessToken(), token);
  }

  public boolean isValidRefreshToken(String token) {
    return constantTimeEquals(refreshToken(), token);
  }

  public Map<String, Object> issueTokenResponse() {
    Map<String, Object> response = new LinkedHashMap<>();
    response.put("status", "scaffold");
    response.put("tokenType", "Bearer");
    response.put("expiresIn", 3600);
    response.put("accessToken", accessToken());
    return response;
  }

  private String accessToken() {
    return firstPresent(
      environment.getProperty("ONMU_API_ACCESS_TOKEN"),
      environment.getProperty("ONMU_DEV_ACCESS_TOKEN"),
      environment.getProperty("onmu.security.access-token"),
      environment.getProperty("onmu.security.dev-access-token")
    );
  }

  private String refreshToken() {
    return firstPresent(
      environment.getProperty("ONMU_API_REFRESH_TOKEN"),
      environment.getProperty("ONMU_DEV_REFRESH_TOKEN"),
      environment.getProperty("onmu.security.refresh-token"),
      environment.getProperty("onmu.security.dev-refresh-token")
    );
  }

  private String firstPresent(String... candidates) {
    for (String candidate : candidates) {
      if (StringUtils.hasText(candidate)) {
        return candidate;
      }
    }
    return "";
  }

  private boolean constantTimeEquals(String expected, String actual) {
    if (!StringUtils.hasText(expected) || !StringUtils.hasText(actual)) {
      return false;
    }

    byte[] expectedBytes = expected.getBytes(StandardCharsets.UTF_8);
    byte[] actualBytes = actual.getBytes(StandardCharsets.UTF_8);
    return MessageDigest.isEqual(expectedBytes, actualBytes);
  }
}
