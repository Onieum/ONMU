package com.onmu.api.service;

import com.onmu.api.web.dto.OAuthLoginRequest;

public interface OAuthProviderVerifier {
  boolean supports(String provider);

  VerifiedOAuthIdentity verify(String normalizedProvider, OAuthLoginRequest request);
}
