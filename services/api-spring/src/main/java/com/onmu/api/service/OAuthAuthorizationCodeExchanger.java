package com.onmu.api.service;

import java.util.Optional;

public interface OAuthAuthorizationCodeExchanger {
  Optional<String> exchange(String provider, String authorizationCode);

  default Optional<String> exchange(String provider, String authorizationCode, String state) {
    return exchange(provider, authorizationCode);
  }
}
