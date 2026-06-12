package com.onmu.api.service;

import com.onmu.api.web.dto.OAuthLoginRequest;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.server.ResponseStatusException;

@Service
public class KakaoOAuthIdentityVerifier implements OAuthProviderVerifier {
  private static final String PROVIDER = "KAKAO";

  private final KakaoUserInfoClient kakaoUserInfoClient;
  private final OAuthAuthorizationCodeExchanger authorizationCodeExchanger;

  public KakaoOAuthIdentityVerifier(
    KakaoUserInfoClient kakaoUserInfoClient,
    OAuthAuthorizationCodeExchanger authorizationCodeExchanger
  ) {
    this.kakaoUserInfoClient = kakaoUserInfoClient;
    this.authorizationCodeExchanger = authorizationCodeExchanger;
  }

  @Override
  public boolean supports(String provider) {
    return PROVIDER.equals(provider);
  }

  @Override
  public VerifiedOAuthIdentity verify(String normalizedProvider, OAuthLoginRequest request) {
    String providerAccessToken = resolveProviderAccessToken(request);
    KakaoUserInfo userInfo = kakaoUserInfoClient.fetch(providerAccessToken);
    if (!StringUtils.hasText(userInfo.id())) {
      throw unauthorized("invalid_kakao_user_info");
    }

    return new VerifiedOAuthIdentity(
      PROVIDER,
      userInfo.id().trim(),
      blankToNull(userInfo.displayName()),
      blankToNull(userInfo.email()),
      blankToNull(userInfo.profileImageUrl())
    );
  }

  private String resolveProviderAccessToken(OAuthLoginRequest request) {
    if (StringUtils.hasText(request.providerAccessToken())) {
      return request.providerAccessToken().trim();
    }
    if (StringUtils.hasText(request.authorizationCode())) {
      return authorizationCodeExchanger.exchange(PROVIDER, request.authorizationCode().trim(), request.state())
        .filter(StringUtils::hasText)
        .map(String::trim)
        .orElseThrow(() -> unauthorized("kakao_authorization_code_exchange_unavailable"));
    }
    throw unauthorized("missing_kakao_provider_access_token");
  }

  private String blankToNull(String value) {
    return StringUtils.hasText(value) ? value.trim() : null;
  }

  private ResponseStatusException unauthorized(String reason) {
    return new ResponseStatusException(HttpStatus.UNAUTHORIZED, reason);
  }
}
