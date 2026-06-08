package com.onmu.api.web;

import java.util.Locale;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {
  @PostMapping("/oauth/{provider}")
  public ResponseEntity<Map<String, Object>> oauthScaffold(@PathVariable String provider) {
    return ResponseEntity.status(HttpStatus.ACCEPTED).body(Map.of(
      "provider", provider.toUpperCase(Locale.ROOT),
      "status", "scaffold",
      "implemented", false,
      "tokenContract", Map.of(
        "accessToken", "spring-main-api-todo",
        "refreshToken", "spring-main-api-todo",
        "clientStorage", "flutter-secure-storage"
      )
    ));
  }
}
