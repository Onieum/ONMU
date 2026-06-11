package com.onmu.api.service;

import java.util.Map;
import java.util.Optional;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.core.env.Environment;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.util.StringUtils;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;
import org.springframework.web.server.ResponseStatusException;

@Service
public class KakaoOAuthAuthorizationCodeExchanger implements OAuthProviderAuthorizationCodeExchanger {
  private static final String PROVIDER = "KAKAO";
  private static final String DEFAULT_TOKEN_URL = "https://kauth.kakao.com/oauth/token";
  private static final String DEFAULT_REDIRECT_URI = "https://dev-api.onmu.cloud/api/v1/auth/oauth/kakao/callback";

  private final RestClient restClient;
  private final String tokenUrl;
  private final String clientId;
  private final String clientSecret;
  private final String redirectUri;

  @Autowired
  public KakaoOAuthAuthorizationCodeExchanger(Environment environment) {
    this(RestClient.builder().build(), environment);
  }

  KakaoOAuthAuthorizationCodeExchanger(RestClient restClient, Environment environment) {
    this.restClient = restClient;
    this.tokenUrl = firstPresent(
      environment.getProperty("onmu.oauth.kakao.token-url"),
      environment.getProperty("KAKAO_OAUTH_TOKEN_URL"),
      DEFAULT_TOKEN_URL
    );
    this.clientId = firstPresent(
      environment.getProperty("KAKAO_REST_API_KEY"),
      environment.getProperty("KAKAO_OAUTH_CLIENT_ID"),
      environment.getProperty("onmu.oauth.kakao.client-id")
    );
    this.clientSecret = firstPresent(
      environment.getProperty("KAKAO_CLIENT_SECRET"),
      environment.getProperty("onmu.oauth.kakao.client-secret")
    );
    this.redirectUri = firstPresent(
      environment.getProperty("KAKAO_OAUTH_REDIRECT_URI"),
      environment.getProperty("onmu.oauth.kakao.redirect-uri"),
      DEFAULT_REDIRECT_URI
    );
  }

  @Override
  public boolean supports(String provider) {
    return PROVIDER.equalsIgnoreCase(provider);
  }

  @Override
  public Optional<String> exchange(String authorizationCode, String state) {
    if (!StringUtils.hasText(clientId) || !StringUtils.hasText(redirectUri)) {
      return Optional.empty();
    }

    MultiValueMap<String, String> body = new LinkedMultiValueMap<>();
    body.add("grant_type", "authorization_code");
    body.add("client_id", clientId);
    body.add("redirect_uri", redirectUri);
    body.add("code", authorizationCode);
    if (StringUtils.hasText(clientSecret)) {
      body.add("client_secret", clientSecret);
    }

    try {
      Map<String, Object> payload = restClient.post()
        .uri(tokenUrl)
        .contentType(MediaType.APPLICATION_FORM_URLENCODED)
        .body(body)
        .retrieve()
        .body(new ParameterizedTypeReference<>() {
        });
      String result = stringValue(payload, "access_token");
      return StringUtils.hasText(result) ? Optional.of(result.trim()) : Optional.empty();
    } catch (RestClientException exception) {
      throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "kakao_authorization_code_exchange_failed");
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
