package com.onmu.api.service;

import com.onmu.api.web.dto.OAuthLoginRequest;
import java.time.Clock;
import java.time.Instant;
import java.util.Set;
import org.springframework.core.env.Environment;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.server.ResponseStatusException;

@Service
public class GoogleOAuthIdentityVerifier implements OAuthProviderVerifier {
  private static final String PROVIDER = "GOOGLE";
  private static final Set<String> VALID_ISSUERS = Set.of("https://accounts.google.com", "accounts.google.com");

  private final GoogleIdTokenInfoClient idTokenInfoClient;
  private final String clientId;
  private final Clock clock;

  public GoogleOAuthIdentityVerifier(
    GoogleIdTokenInfoClient idTokenInfoClient,
    Environment environment
  ) {
    this(idTokenInfoClient, resolveClientId(environment), Clock.systemUTC());
  }

  GoogleOAuthIdentityVerifier(
    GoogleIdTokenInfoClient idTokenInfoClient,
    String clientId,
    Clock clock
  ) {
    this.idTokenInfoClient = idTokenInfoClient;
    this.clientId = clientId;
    this.clock = clock;
  }

  @Override
  public boolean supports(String provider) {
    return PROVIDER.equals(provider);
  }

  @Override
  public VerifiedOAuthIdentity verify(String normalizedProvider, OAuthLoginRequest request) {
    if (!StringUtils.hasText(request.providerIdToken())) {
      throw unauthorized("missing_google_provider_id_token");
    }
    if (!StringUtils.hasText(clientId)) {
      throw unauthorized("google_oauth_client_id_unavailable");
    }

    GoogleIdTokenInfo tokenInfo = idTokenInfoClient.fetch(request.providerIdToken().trim());
    validate(tokenInfo);
    return new VerifiedOAuthIdentity(
      PROVIDER,
      tokenInfo.subject().trim(),
      blankToNull(tokenInfo.displayName()),
      blankToNull(tokenInfo.email()),
      blankToNull(tokenInfo.profileImageUrl())
    );
  }

  private void validate(GoogleIdTokenInfo tokenInfo) {
    if (!StringUtils.hasText(tokenInfo.issuer()) || !VALID_ISSUERS.contains(tokenInfo.issuer().trim())) {
      throw unauthorized("invalid_google_id_token_issuer");
    }
    if (!clientId.equals(tokenInfo.audience())) {
      throw unauthorized("invalid_google_id_token_audience");
    }
    if (!StringUtils.hasText(tokenInfo.subject())) {
      throw unauthorized("invalid_google_id_token_subject");
    }
    Instant expiresAt = tokenInfo.expiresAt();
    if (expiresAt == null || !expiresAt.isAfter(Instant.now(clock))) {
      throw unauthorized("google_id_token_expired");
    }
  }

  private static String resolveClientId(Environment environment) {
    return firstPresent(
      environment.getProperty("GOOGLE_OAUTH_CLIENT_ID"),
      environment.getProperty("GOOGLE_SERVER_CLIENT_ID"),
      environment.getProperty("onmu.oauth.google.client-id")
    );
  }

  private static String firstPresent(String... candidates) {
    for (String candidate : candidates) {
      if (StringUtils.hasText(candidate)) {
        return candidate.trim();
      }
    }
    return "";
  }

  private String blankToNull(String value) {
    return StringUtils.hasText(value) ? value.trim() : null;
  }

  private ResponseStatusException unauthorized(String reason) {
    return new ResponseStatusException(HttpStatus.UNAUTHORIZED, reason);
  }
}
