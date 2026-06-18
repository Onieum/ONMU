package com.onmu.api.service;

import com.onmu.api.config.AuthProperties;
import com.onmu.api.domain.AuthIdentityEntity;
import com.onmu.api.domain.AuthIdentityRepository;
import com.onmu.api.domain.RefreshTokenEntity;
import com.onmu.api.domain.RefreshTokenRepository;
import com.onmu.api.domain.UserEntity;
import com.onmu.api.domain.UserRepository;
import com.onmu.api.security.AccessTokenIssuer;
import com.onmu.api.security.AccessTokenIssuer.IssuedAccessToken;
import com.onmu.api.web.dto.OAuthLoginRequest;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.time.Instant;
import java.util.Base64;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
public class AuthService {
  private static final SecureRandom SECURE_RANDOM = new SecureRandom();
  private static final Base64.Encoder BASE64_URL_ENCODER = Base64.getUrlEncoder().withoutPadding();

  private final UserRepository userRepository;
  private final AuthIdentityRepository authIdentityRepository;
  private final RefreshTokenRepository refreshTokenRepository;
  private final AccessTokenIssuer accessTokenIssuer;
  private final AuthProperties authProperties;
  private final OAuthIdentityVerifier oAuthIdentityVerifier;
  private final UserCodeService userCodeService;

  public AuthService(
    UserRepository userRepository,
    AuthIdentityRepository authIdentityRepository,
    RefreshTokenRepository refreshTokenRepository,
    AccessTokenIssuer accessTokenIssuer,
    AuthProperties authProperties,
    OAuthIdentityVerifier oAuthIdentityVerifier,
    UserCodeService userCodeService
  ) {
    this.userRepository = userRepository;
    this.authIdentityRepository = authIdentityRepository;
    this.refreshTokenRepository = refreshTokenRepository;
    this.accessTokenIssuer = accessTokenIssuer;
    this.authProperties = authProperties;
    this.oAuthIdentityVerifier = oAuthIdentityVerifier;
    this.userCodeService = userCodeService;
  }

  @Transactional
  public Map<String, Object> oauthLogin(
    String provider,
    OAuthLoginRequest request,
    String clientIp,
    String userAgent
  ) {
    VerifiedOAuthIdentity verifiedIdentity = oAuthIdentityVerifier.verify(provider, request);
    AuthIdentityEntity identity = authIdentityRepository
      .findByProviderAndProviderSubjectAndDeletedAtIsNull(
        verifiedIdentity.provider(),
        verifiedIdentity.providerSubject()
      )
      .orElseGet(() -> createIdentity(verifiedIdentity));
    syncDefaultProfileFromProvider(identity.getUser(), verifiedIdentity);
    identity.recordLogin(verifiedIdentity.email());
    userCodeService.ensureActiveCode(identity.getUser());

    return issueTokenResponse(identity.getUser(), clientIp, userAgent, null, UUID.randomUUID());
  }

  @Transactional
  public Map<String, Object> refresh(String refreshToken, String clientIp, String userAgent) {
    RefreshTokenEntity currentToken = refreshTokenRepository.findByTokenHashForUpdate(hash(refreshToken))
      .orElseThrow(() -> unauthorized("invalid_refresh_token"));
    Instant now = Instant.now();
    if (!currentToken.isActive(now)) {
      if (currentToken.getRevokedAt() != null) {
        refreshTokenRepository.revokeFamily(
          currentToken.getTokenFamilyId(),
          now,
          "reuse_detected"
        );
        throw unauthorized("refresh_token_reuse_detected");
      }
      throw unauthorized("refresh_token_expired");
    }
    UserEntity user = currentToken.getUser();
    if (user.getDeletedAt() != null) {
      throw unauthorized("user_not_found");
    }

    currentToken.markRotated();
    return issueTokenResponse(user, clientIp, userAgent, currentToken.getTokenHash(), currentToken.getTokenFamilyId());
  }

  @Transactional
  public Map<String, Object> logout(String refreshToken) {
    if (refreshToken != null && !refreshToken.isBlank()) {
      refreshTokenRepository.findByTokenHash(hash(refreshToken.trim()))
        .ifPresent(token -> token.revoke("logout"));
    }
    return Map.of("ok", true, "authenticated", false);
  }

  private AuthIdentityEntity createIdentity(VerifiedOAuthIdentity verifiedIdentity) {
    UserEntity user = userRepository.saveAndFlush(new UserEntity(
      nextPublicId("usr"),
      displayNameOrDefault(verifiedIdentity.displayName()),
      blankToNull(verifiedIdentity.email()),
      blankToNull(verifiedIdentity.profileImageUrl())
    ));
    return authIdentityRepository.save(new AuthIdentityEntity(
      nextPublicId("aid"),
      user,
      verifiedIdentity.provider(),
      verifiedIdentity.providerSubject(),
      blankToNull(verifiedIdentity.email())
    ));
  }

  private void syncDefaultProfileFromProvider(UserEntity user, VerifiedOAuthIdentity verifiedIdentity) {
    String providerDisplayName = blankToNull(verifiedIdentity.displayName());
    String nextDisplayName = isDefaultDisplayName(user.getDisplayName()) && providerDisplayName != null
      ? providerDisplayName
      : null;
    String providerProfileImageUrl = blankToNull(verifiedIdentity.profileImageUrl());
    String nextProfileImageUrl = blankToNull(user.getProfileImageUrl()) == null
      ? providerProfileImageUrl
      : null;

    if (nextDisplayName != null || nextProfileImageUrl != null) {
      user.updateProfile(nextDisplayName, nextProfileImageUrl, null, null, null);
    }
  }

  private boolean isDefaultDisplayName(String displayName) {
    return displayName == null
      || displayName.isBlank()
      || "ONMU User".equals(displayName.trim())
      || "ONMU user".equals(displayName.trim());
  }

  private Map<String, Object> issueTokenResponse(
    UserEntity user,
    String clientIp,
    String userAgent,
    String previousTokenHash,
    UUID tokenFamilyId
  ) {
    IssuedAccessToken accessToken = accessTokenIssuer.issue(user);
    String refreshToken = randomToken();
    RefreshTokenEntity storedRefreshToken = new RefreshTokenEntity(
      nextPublicId("rt"),
      user,
      tokenFamilyId,
      hash(refreshToken),
      previousTokenHash,
      Instant.now(),
      Instant.now().plus(authProperties.refreshTokenTtl()),
      blankToNull(clientIp),
      blankToNull(userAgent)
    );
    refreshTokenRepository.save(storedRefreshToken);

    Map<String, Object> tokens = new LinkedHashMap<>();
    tokens.put("accessToken", accessToken.token());
    tokens.put("accessTokenExpiresAt", accessToken.expiresAt().toString());
    tokens.put("refreshToken", refreshToken);
    tokens.put("refreshTokenExpiresAt", storedRefreshToken.getExpiresAt().toString());
    tokens.put("tokenType", "Bearer");

    Map<String, Object> response = new LinkedHashMap<>();
    response.put("ok", true);
    response.put("authenticated", true);
    response.put("tokens", tokens);
    Map<String, Object> userPayload = new LinkedHashMap<>();
    userPayload.put("id", user.getPublicId());
    userPayload.put(
      "databaseId",
      user.getId() == null ? null : user.getId().toString()
    );
    userPayload.put("displayName", user.getDisplayName());
    userPayload.put("profileImageUrl", user.getProfileImageUrl());
    userPayload.put("onboardingStatus", user.getOnboardingStatus());
    response.put("user", userPayload);
    return response;
  }

  private String displayNameOrDefault(String displayName) {
    return displayName == null || displayName.isBlank() ? "ONMU User" : displayName.trim();
  }

  private String blankToNull(String value) {
    return value == null || value.isBlank() ? null : value.trim();
  }

  private String nextPublicId(String prefix) {
    return prefix + "_" + randomToken(18);
  }

  private String randomToken() {
    return randomToken(48);
  }

  private String randomToken(int byteCount) {
    byte[] bytes = new byte[byteCount];
    SECURE_RANDOM.nextBytes(bytes);
    return BASE64_URL_ENCODER.encodeToString(bytes);
  }

  private String hash(String token) {
    try {
      return BASE64_URL_ENCODER.encodeToString(MessageDigest.getInstance("SHA-256")
        .digest(token.getBytes(StandardCharsets.UTF_8)));
    } catch (Exception exception) {
      throw new IllegalStateException("Could not hash refresh token", exception);
    }
  }

  private ResponseStatusException unauthorized(String reason) {
    return new ResponseStatusException(HttpStatus.UNAUTHORIZED, reason);
  }
}
