package com.onmu.api.service;

import java.util.Map;
import java.util.Optional;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.core.env.Environment;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;
import org.springframework.web.server.ResponseStatusException;

@Service
public class NaverOAuthAuthorizationCodeExchanger implements OAuthAuthorizationCodeExchanger {
  private static final String PROVIDER = "NAVER";
  private static final String DEFAULT_TOKEN_URL = "https://nid.naver.com/oauth2.0/token";

  private final RestClient restClient;
  private final String tokenUrl;
  private final String clientId;
  private final String clientSecret;

  public NaverOAuthAuthorizationCodeExchanger(Environment environment) {
    this(RestClient.builder().build(), environment);
  }

  NaverOAuthAuthorizationCodeExchanger(RestClient restClient, Environment environment) {
    this.restClient = restClient;
    this.tokenUrl = firstPresent(
      environment.getProperty("onmu.oauth.naver.token-url"),
      environment.getProperty("NAVER_OAUTH_TOKEN_URL"),
      DEFAULT_TOKEN_URL
    );
    this.clientId = firstPresent(
      environment.getProperty("NAVER_OAUTH_CLIENT_ID"),
      environment.getProperty("onmu.oauth.naver.client-id")
    );
    this.clientSecret = firstPresent(
      environment.getProperty("NAVER_OAUTH_CLIENT_SECRET"),
      environment.getProperty("onmu.oauth.naver.client-secret")
    );
  }

  @Override
  public Optional<String> exchange(String provider, String authorizationCode) {
    return exchange(provider, authorizationCode, null);
  }

  @Override
  public Optional<String> exchange(String provider, String authorizationCode, String state) {
    if (!PROVIDER.equalsIgnoreCase(provider)) {
      return Optional.empty();
    }
    if (!StringUtils.hasText(clientId) || !StringUtils.hasText(clientSecret) || !StringUtils.hasText(state)) {
      return Optional.empty();
    }

    MultiValueMap<String, String> body = new LinkedMultiValueMap<>();
    body.add("grant_type", "authorization_code");
    body.add("client_id", clientId);
    body.add("client_secret", clientSecret);
    body.add("code", authorizationCode);
    body.add("state", state.trim());

    try {
      Map<String, Object> payload = restClient.post()
        .uri(tokenUrl)
        .contentType(MediaType.APPLICATION_FORM_URLENCODED)
        .body(body)
        .retrieve()
        .body(new ParameterizedTypeReference<>() {
        });
      String accessToken = stringValue(payload, "access_token");
      return StringUtils.hasText(accessToken) ? Optional.of(accessToken.trim()) : Optional.empty();
    } catch (RestClientException exception) {
      throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "naver_authorization_code_exchange_failed");
    }
  }

  private String stringValue(Map<String, Object> payload, String key) {
    if (payload == null || payload.get(key) == null) {
      return null;
    }
    return payload.get(key).toString();
  }

  private String firstPresent(String... candidates) {
    for (String candidate : candidates) {
      if (StringUtils.hasText(candidate)) {
        return candidate.trim();
      }
    }
    return "";
  }
}
