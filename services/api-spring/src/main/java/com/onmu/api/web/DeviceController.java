package com.onmu.api.web;

import com.onmu.api.security.AuthenticatedUser;
import com.onmu.api.service.PushTokenService;
import com.onmu.api.web.dto.PushTokenRegistrationRequest;
import com.onmu.api.web.dto.PushTokenRegistrationResponse;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/devices")
public class DeviceController {
  private final PushTokenService pushTokenService;

  public DeviceController(PushTokenService pushTokenService) {
    this.pushTokenService = pushTokenService;
  }

  @PostMapping("/push-token")
  public PushTokenRegistrationResponse registerPushToken(
    @AuthenticationPrincipal AuthenticatedUser user,
    @RequestBody(required = false) PushTokenRegistrationRequest request
  ) {
    return pushTokenService.register(user.userId(), request);
  }

  @DeleteMapping("/push-token")
  public PushTokenRegistrationResponse deactivatePushToken(
    @AuthenticationPrincipal AuthenticatedUser user,
    @RequestBody(required = false) PushTokenRegistrationRequest request
  ) {
    return pushTokenService.deactivate(user.userId(), request);
  }
}
