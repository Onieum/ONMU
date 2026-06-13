package com.onmu.api.service;

import java.time.Instant;
import java.util.Map;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.core.env.Environment;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestClientResponseException;
import org.springframework.web.server.ResponseStatusException;

@Service
public class GoogleIdTokenInfoHttpClient implements GoogleIdTokenInfoClient {
  private static final String DEFAULT_TOKEN_INFO_URL = "https://oauth2.googleapis.com/tokeninfo";
  private static final ParameterizedTypeReference<Map<String, Object>> MAP_TYPE =
    new ParameterizedTypeReference<>() {
    };

  private final RestClient restClient;
  private final String tokenInfoUrl;

  @Autowired
  public GoogleIdTokenInfoHttpClient(Environment environment) {
    this(RestClient.builder().build(), resolveTokenInfoUrl(environment));
  }

  GoogleIdTokenInfoHttpClient(RestClient restClient, String tokenInfoUrl) {
    this.restClient = restClient;
    this.tokenInfoUrl = tokenInfoUrl;
  }

  @Override
  public GoogleIdTokenInfo fetch(String providerIdToken) {
    try {
      Map<String, Object> payload = restClient.get()
        .uri(tokenInfoUrl + "?id_token={idToken}", providerIdToken)
        .retrieve()
        .body(MAP_TYPE);
      return mapTokenInfo(payload == null ? Map.of() : payload);
    } catch (RestClientResponseException exception) {
      if (exception.getStatusCode().is4xxClientError()) {
        throw unauthorized("invalid_google_provider_id_token");
      }
      throw unauthorized("google_token_info_unavailable");
    } catch (RestClientException exception) {
      throw unauthorized("google_token_info_unavailable");
    }
  }

  private GoogleIdTokenInfo mapTokenInfo(Map<String, Object> payload) {
    return new GoogleIdTokenInfo(
      readString(payload.get("iss")),
      readString(payload.get("aud")),
      readString(payload.get("sub")),
      readExpiry(payload.get("exp")),
      readString(payload.get("name")),
      readString(payload.get("email")),
      readString(payload.get("picture"))
    );
  }

  private Instant readExpiry(Object value) {
    String stringValue = readString(value);
    if (!StringUtils.hasText(stringValue)) {
      return null;
    }
    try {
      return Instant.ofEpochSecond(Long.parseLong(stringValue.trim()));
    } catch (NumberFormatException exception) {
      return null;
    }
  }

  private String readString(Object value) {
    return value == null ? null : value.toString();
  }

  private static String resolveTokenInfoUrl(Environment environment) {
    String configured = firstPresent(
      environment.getProperty("GOOGLE_OAUTH_TOKEN_INFO_URL"),
      environment.getProperty("onmu.oauth.google.token-info-url")
    );
    return StringUtils.hasText(configured) ? configured : DEFAULT_TOKEN_INFO_URL;
  }

  private static String firstPresent(String... candidates) {
    for (String candidate : candidates) {
      if (StringUtils.hasText(candidate)) {
        return candidate.trim();
      }
    }
    return "";
  }

  private ResponseStatusException unauthorized(String reason) {
    return new ResponseStatusException(HttpStatus.UNAUTHORIZED, reason);
  }
}
