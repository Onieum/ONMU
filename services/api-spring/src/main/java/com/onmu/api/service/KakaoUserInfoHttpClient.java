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
public class KakaoUserInfoHttpClient implements KakaoUserInfoClient {
  private static final String DEFAULT_USER_INFO_URL = "https://kapi.kakao.com/v2/user/me";
  private static final ParameterizedTypeReference<Map<String, Object>> MAP_TYPE =
    new ParameterizedTypeReference<>() {
    };

  private final RestClient restClient;
  private final String userInfoUrl;

  @Autowired
  public KakaoUserInfoHttpClient(Environment environment) {
    this(RestClient.builder().build(), resolveUserInfoUrl(environment));
  }

  KakaoUserInfoHttpClient(RestClient restClient, String userInfoUrl) {
    this.restClient = restClient;
    this.userInfoUrl = userInfoUrl;
  }

  @Override
  public KakaoUserInfo fetch(String providerAccessToken) {
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
        throw unauthorized("invalid_kakao_provider_access_token");
      }
      throw unauthorized("kakao_user_info_unavailable");
    }
  }

  private KakaoUserInfo mapUserInfo(Map<String, Object> payload) {
    String id = readString(payload.get("id"));
    Map<String, Object> account = readMap(payload.get("kakao_account"));
    Map<String, Object> accountProfile = readMap(account.get("profile"));
    Map<String, Object> properties = readMap(payload.get("properties"));

    return new KakaoUserInfo(
      id,
      firstText(
        readString(accountProfile.get("nickname")),
        readString(properties.get("nickname"))
      ),
      readString(account.get("email")),
      firstText(
        readString(accountProfile.get("profile_image_url")),
        readString(properties.get("profile_image"))
      )
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
    String configured = environment.getProperty("onmu.oauth.kakao.user-info-url");
    if (!StringUtils.hasText(configured)) {
      configured = environment.getProperty("ONMU_OAUTH_KAKAO_USER_INFO_URL");
    }
    return StringUtils.hasText(configured) ? configured.trim() : DEFAULT_USER_INFO_URL;
  }

  private ResponseStatusException unauthorized(String reason) {
    return new ResponseStatusException(HttpStatus.UNAUTHORIZED, reason);
  }
}
