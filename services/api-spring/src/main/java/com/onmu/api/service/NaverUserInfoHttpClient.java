package com.onmu.api.service;

import java.util.Map;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.core.env.Environment;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientResponseException;
import org.springframework.web.server.ResponseStatusException;

@Service
public class NaverUserInfoHttpClient implements NaverUserInfoClient {
  private static final String DEFAULT_USER_INFO_URL = "https://openapi.naver.com/v1/nid/me";
  private static final ParameterizedTypeReference<Map<String, Object>> MAP_TYPE =
    new ParameterizedTypeReference<>() {
    };

  private final RestClient restClient;
  private final String userInfoUrl;

  @Autowired
  public NaverUserInfoHttpClient(Environment environment) {
    this(RestClient.builder().build(), resolveUserInfoUrl(environment));
  }

  NaverUserInfoHttpClient(RestClient restClient, String userInfoUrl) {
    this.restClient = restClient;
    this.userInfoUrl = userInfoUrl;
  }

  @Override
  public NaverUserInfo fetch(String providerAccessToken) {
    try {
      Map<String, Object> payload = restClient.get()
        .uri(userInfoUrl)
        .header(HttpHeaders.AUTHORIZATION, "Bearer " + providerAccessToken)
        .retrieve()
        .body(MAP_TYPE);
      return mapUserInfo(payload == null ? Map.of() : payload);
    } catch (RestClientResponseException exception) {
      if (exception.getStatusCode().isSameCodeAs(HttpStatus.UNAUTHORIZED)
        || exception.getStatusCode().isSameCodeAs(HttpStatus.FORBIDDEN)) {
        throw unauthorized("invalid_naver_provider_access_token");
      }
      throw unauthorized("naver_user_info_unavailable");
    }
  }

  private NaverUserInfo mapUserInfo(Map<String, Object> payload) {
    Map<String, Object> response = readMap(payload.get("response"));
    return new NaverUserInfo(
      readString(response.get("id")),
      firstText(
        readString(response.get("name")),
        readString(response.get("nickname"))
      ),
      readString(response.get("email")),
      readString(response.get("profile_image"))
    );
  }

  @SuppressWarnings("unchecked")
  private Map<String, Object> readMap(Object value) {
    if (value instanceof Map<?, ?> map) {
      return (Map<String, Object>) map;
    }
    return Map.of();
  }

  private String readString(Object value) {
    return value == null ? null : value.toString();
  }

  private String firstText(String... values) {
    for (String value : values) {
      if (StringUtils.hasText(value)) {
        return value.trim();
      }
    }
    return null;
  }

  private static String resolveUserInfoUrl(Environment environment) {
    String configured = environment.getProperty("onmu.oauth.naver.user-info-url");
    if (!StringUtils.hasText(configured)) {
      configured = environment.getProperty("ONMU_OAUTH_NAVER_USER_INFO_URL");
    }
    return StringUtils.hasText(configured) ? configured.trim() : DEFAULT_USER_INFO_URL;
  }

  private ResponseStatusException unauthorized(String reason) {
    return new ResponseStatusException(HttpStatus.UNAUTHORIZED, reason);
  }
}
