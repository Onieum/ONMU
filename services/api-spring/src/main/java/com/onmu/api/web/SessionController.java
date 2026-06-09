package com.onmu.api.web;

import com.onmu.api.security.AuthenticatedUser;
import java.util.Map;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/auth")
public class SessionController {
  @GetMapping("/session")
  public Map<String, Object> session(@AuthenticationPrincipal AuthenticatedUser user) {
    return Map.of(
      "ok", true,
      "authenticated", true,
      "user", Map.of(
        "id", user.publicId()
      )
    );
  }
}
