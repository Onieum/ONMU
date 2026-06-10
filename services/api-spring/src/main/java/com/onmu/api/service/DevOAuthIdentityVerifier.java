package com.onmu.api.service;

import com.onmu.api.web.dto.OAuthLoginRequest;
import java.util.Locale;
import org.springframework.core.env.Environment;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.server.ResponseStatusException;

@Service
public class DevOAuthIdentityVerifier implements OAuthIdentityVerifier {
  private final Environment environment;

  public DevOAuthIdentityVerifier(Environment environment) {
    this.environment = environment;
  }

  @Override
  public VerifiedOAuthIdentity verify(String provider, OAuthLoginRequest request) {
    String normalizedProvider = normalizeProvider(provider);
    if (!request.hasVerificationInput()) {
      throw unauthorized("missing_oauth_verification_input");
    }
    if (!devVerificationEnabled()) {
      throw unauthorized("oauth_provider_verification_unavailable");
    }
    if (!StringUtils.hasText(request.devVerifiedSubject())) {
      throw unauthorized("missing_dev_verified_subject");
    }
    return new VerifiedOAuthIdentity(
      normalizedProvider,
      request.devVerifiedSubject().trim(),
      blankToNull(request.displayName()),
      blankToNull(request.email()),
      blankToNull(request.profileImageUrl())
    );
  }

  private String normalizeProvider(String provider) {
    String value = provider == null ? "" : provider.trim().toUpperCase(Locale.ROOT);
    if (!"NAVER".equals(value)) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "unsupported_oauth_provider");
    }
    return value;
  }

  private boolean devVerificationEnabled() {
    return Boolean.parseBoolean(environment.getProperty("onmu.auth.dev-oauth-enabled", "false"))
      || Boolean.parseBoolean(environment.getProperty("ONMU_DEV_OAUTH_ENABLED", "false"));
  }

  private String blankToNull(String value) {
    return StringUtils.hasText(value) ? value.trim() : null;
  }

  private ResponseStatusException unauthorized(String reason) {
    return new ResponseStatusException(HttpStatus.UNAUTHORIZED, reason);
  }
}
