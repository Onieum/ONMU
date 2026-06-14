package com.onmu.api.service;

import com.onmu.api.domain.UserDeviceEntity;
import com.onmu.api.domain.UserDeviceRepository;
import com.onmu.api.domain.UserEntity;
import com.onmu.api.domain.UserRepository;
import com.onmu.api.web.dto.PushTokenRegistrationRequest;
import com.onmu.api.web.dto.PushTokenRegistrationResponse;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Clock;
import java.time.Instant;
import java.util.HexFormat;
import java.util.Set;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;
import org.springframework.web.server.ResponseStatusException;

@Service
public class PushTokenService {
  private static final Set<String> SUPPORTED_PROVIDERS = Set.of("fcm", "apns", "dev");
  private static final Set<String> SUPPORTED_PLATFORMS = Set.of("ios", "android", "web", "unknown");
  private static final int MAX_TOKEN_LENGTH = 4096;

  private final UserRepository userRepository;
  private final UserDeviceRepository userDeviceRepository;
  private final Clock clock;

  @Autowired
  public PushTokenService(
    UserRepository userRepository,
    UserDeviceRepository userDeviceRepository
  ) {
    this(userRepository, userDeviceRepository, Clock.systemUTC());
  }

  PushTokenService(
    UserRepository userRepository,
    UserDeviceRepository userDeviceRepository,
    Clock clock
  ) {
    this.userRepository = userRepository;
    this.userDeviceRepository = userDeviceRepository;
    this.clock = clock;
  }

  @Transactional
  public PushTokenRegistrationResponse register(UUID currentUserId, PushTokenRegistrationRequest request) {
    TokenInput input = tokenInput(request);
    UserEntity user = userRepository.findByIdAndDeletedAtIsNull(currentUserId)
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "user_not_found"));
    Instant now = clock.instant();
    userDeviceRepository.deactivateActiveTokenForOtherUsers(
      user.getId(),
      input.provider(),
      input.tokenHash(),
      now
    );

    UserDeviceEntity device = userDeviceRepository
      .findFirstByUser_IdAndPushProviderAndPushTokenHashAndStatus(
        user.getId(),
        input.provider(),
        input.tokenHash(),
        "active"
      )
      .orElseGet(() -> new UserDeviceEntity(user, input.platform(), now));
    device.registerPushToken(
      input.provider(),
      input.token(),
      input.tokenHash(),
      input.tokenLast4(),
      input.platform(),
      trimToNull(request.appVersion()),
      trimToNull(request.osVersion()),
      trimToNull(request.deviceLabel()),
      trimToNull(request.deviceFingerprintHash()),
      now
    );
    UserDeviceEntity saved = userDeviceRepository.save(device);
    return response(saved, true, now);
  }

  @Transactional
  public PushTokenRegistrationResponse deactivate(UUID currentUserId, PushTokenRegistrationRequest request) {
    TokenInput input = tokenInput(request);
    Instant now = clock.instant();
    UserDeviceEntity device = userDeviceRepository
      .findFirstByUser_IdAndPushProviderAndPushTokenHashAndStatus(
        currentUserId,
        input.provider(),
        input.tokenHash(),
        "active"
      )
      .orElse(null);
    if (device == null) {
      return new PushTokenRegistrationResponse(
        null,
        input.provider(),
        input.platform(),
        "inactive",
        false,
        input.tokenLast4(),
        now.toString()
      );
    }
    device.deactivatePushToken(now);
    UserDeviceEntity saved = userDeviceRepository.save(device);
    return response(saved, false, now);
  }

  private PushTokenRegistrationResponse response(
    UserDeviceEntity device,
    boolean registered,
    Instant fallbackUpdatedAt
  ) {
    Instant updatedAt = device.getUpdatedAt() == null ? fallbackUpdatedAt : device.getUpdatedAt();
    return new PushTokenRegistrationResponse(
      device.getId().toString(),
      device.getPushProvider(),
      device.getPlatform(),
      device.getStatus(),
      registered,
      device.getPushTokenLast4(),
      updatedAt.toString()
    );
  }

  private TokenInput tokenInput(PushTokenRegistrationRequest request) {
    if (request == null) {
      throw badRequest("missing_push_token_request");
    }
    String provider = trimToNull(request.provider());
    if (provider == null) {
      throw badRequest("missing_push_provider");
    }
    provider = provider.toLowerCase();
    if (!SUPPORTED_PROVIDERS.contains(provider)) {
      throw badRequest("unsupported_push_provider");
    }

    String token = trimToNull(request.token());
    if (token == null) {
      throw badRequest("missing_push_token");
    }
    if (token.length() < 8 || token.length() > MAX_TOKEN_LENGTH) {
      throw badRequest("invalid_push_token");
    }

    String platform = trimToNull(request.platform());
    platform = platform == null ? "unknown" : platform.toLowerCase();
    if (!SUPPORTED_PLATFORMS.contains(platform)) {
      platform = "unknown";
    }
    return new TokenInput(provider, token, tokenHash(provider, token), tokenLast4(token), platform);
  }

  private String tokenHash(String provider, String token) {
    try {
      MessageDigest digest = MessageDigest.getInstance("SHA-256");
      byte[] hash = digest.digest((provider + ":" + token).getBytes(StandardCharsets.UTF_8));
      return HexFormat.of().formatHex(hash);
    } catch (NoSuchAlgorithmException exception) {
      throw new IllegalStateException("SHA-256 digest unavailable", exception);
    }
  }

  private String tokenLast4(String token) {
    return token.substring(Math.max(0, token.length() - 4));
  }

  private String trimToNull(String value) {
    return StringUtils.hasText(value) ? value.trim() : null;
  }

  private ResponseStatusException badRequest(String reason) {
    return new ResponseStatusException(HttpStatus.BAD_REQUEST, reason);
  }

  private record TokenInput(
    String provider,
    String token,
    String tokenHash,
    String tokenLast4,
    String platform
  ) {
  }
}
