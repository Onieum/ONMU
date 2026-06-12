package com.onmu.api.service;

import java.util.List;
import java.util.Optional;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

@Service
public class CompositeOAuthAuthorizationCodeExchanger implements OAuthAuthorizationCodeExchanger {
  private final List<OAuthProviderAuthorizationCodeExchanger> exchangers;

  public CompositeOAuthAuthorizationCodeExchanger(List<OAuthProviderAuthorizationCodeExchanger> exchangers) {
    this.exchangers = List.copyOf(exchangers);
  }

  @Override
  public Optional<String> exchange(String provider, String authorizationCode) {
    return exchange(provider, authorizationCode, null);
  }

  @Override
  public Optional<String> exchange(String provider, String authorizationCode, String state) {
    if (!StringUtils.hasText(provider) || !StringUtils.hasText(authorizationCode)) {
      return Optional.empty();
    }
    return exchangers.stream()
      .filter(exchanger -> exchanger.supports(provider.trim()))
      .findFirst()
      .flatMap(exchanger -> exchanger.exchange(authorizationCode.trim(), state));
  }
}
