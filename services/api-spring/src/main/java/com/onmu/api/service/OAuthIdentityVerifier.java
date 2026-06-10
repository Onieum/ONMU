package com.onmu.api.service;

import com.onmu.api.web.dto.OAuthLoginRequest;

public interface OAuthIdentityVerifier {
  VerifiedOAuthIdentity verify(String provider, OAuthLoginRequest request);
}
