package com.onmu.api.config;

import java.time.Duration;
import java.util.List;
import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "onmu.auth")
public record AuthProperties(
  String accessTokenSecret,
  String issuer,
  String audience,
  Duration accessTokenTtl,
  Duration refreshTokenTtl,
  Duration clockSkew,
  List<String> allowedOrigins
) {
  public AuthProperties {
    if (accessTokenSecret == null || accessTokenSecret.isBlank()) {
      accessTokenSecret = "local-dev-access-token-secret-change-before-shared-dev";
    }
    if (issuer == null || issuer.isBlank()) {
      issuer = "onmu-api";
    }
    if (audience == null || audience.isBlank()) {
      audience = "onmu-mobile";
    }
    if (accessTokenTtl == null) {
      accessTokenTtl = Duration.ofMinutes(30);
    }
    if (refreshTokenTtl == null) {
      refreshTokenTtl = Duration.ofDays(30);
    }
    if (clockSkew == null) {
      clockSkew = Duration.ofSeconds(60);
    }
    if (allowedOrigins == null || allowedOrigins.isEmpty()) {
      allowedOrigins = List.of(
        "http://localhost:*",
        "http://127.0.0.1:*",
        "https://dev-api.onmu.cloud"
      );
    }
  }
}
