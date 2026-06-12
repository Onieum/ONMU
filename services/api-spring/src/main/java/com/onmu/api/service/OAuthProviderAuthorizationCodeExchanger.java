package com.onmu.api.service;

import java.util.Optional;

public interface OAuthProviderAuthorizationCodeExchanger {
  boolean supports(String provider);

  Optional<String> exchange(String authorizationCode, String state);
}
