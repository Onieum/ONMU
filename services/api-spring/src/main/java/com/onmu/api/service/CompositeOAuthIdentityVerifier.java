package com.onmu.api.service;

import com.onmu.api.web.dto.OAuthLoginRequest;
import java.util.List;
import java.util.Locale;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.server.ResponseStatusException;

@Service
public class CompositeOAuthIdentityVerifier implements OAuthIdentityVerifier {
  private final List<OAuthProviderVerifier> providerVerifiers;

  public CompositeOAuthIdentityVerifier(List<OAuthProviderVerifier> providerVerifiers) {
    this.providerVerifiers = providerVerifiers;
  }

  @Override
  public VerifiedOAuthIdentity verify(String provider, OAuthLoginRequest request) {
    String normalizedProvider = normalizeProvider(provider);
    return providerVerifiers.stream()
      .filter(verifier -> verifier.supports(normalizedProvider))
      .findFirst()
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.BAD_REQUEST, "unsupported_oauth_provider"))
      .verify(normalizedProvider, request);
  }

  private String normalizeProvider(String provider) {
    if (!StringUtils.hasText(provider)) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "unsupported_oauth_provider");
    }
    return provider.trim().toUpperCase(Locale.ROOT);
  }
}
