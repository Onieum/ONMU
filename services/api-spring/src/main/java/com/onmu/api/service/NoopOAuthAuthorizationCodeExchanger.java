package com.onmu.api.service;

import java.util.Optional;
import org.springframework.stereotype.Service;

@Service
public class NoopOAuthAuthorizationCodeExchanger implements OAuthAuthorizationCodeExchanger {
  @Override
  public Optional<String> exchange(String provider, String authorizationCode) {
    return Optional.empty();
  }
}
