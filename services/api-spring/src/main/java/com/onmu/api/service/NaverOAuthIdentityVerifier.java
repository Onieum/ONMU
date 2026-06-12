package com.onmu.api.service;

import com.onmu.api.web.dto.OAuthLoginRequest;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.server.ResponseStatusException;

@Service
public class NaverOAuthIdentityVerifier implements OAuthProviderVerifier {
  private static final String PROVIDER = "NAVER";

  private final NaverUserInfoClient naverUserInfoClient;
  private final OAuthAuthorizationCodeExchanger authorizationCodeExchanger;
  private final DevOAuthIdentityVerifier devOAuthIdentityVerifier;

  public NaverOAuthIdentityVerifier(
    NaverUserInfoClient naverUserInfoClient,
    OAuthAuthorizationCodeExchanger authorizationCodeExchanger,
    DevOAuthIdentityVerifier devOAuthIdentityVerifier
  ) {
    this.naverUserInfoClient = naverUserInfoClient;
    this.authorizationCodeExchanger = authorizationCodeExchanger;
    this.devOAuthIdentityVerifier = devOAuthIdentityVerifier;
  }

  @Override
  public boolean supports(String provider) {
    return PROVIDER.equals(provider);
  }

  @Override
  public VerifiedOAuthIdentity verify(String normalizedProvider, OAuthLoginRequest request) {
    if (StringUtils.hasText(request.providerAccessToken()) || StringUtils.hasText(request.authorizationCode())) {
      String providerAccessToken = resolveProviderAccessToken(request);
      NaverUserInfo userInfo = naverUserInfoClient.fetch(providerAccessToken);
      if (!StringUtils.hasText(userInfo.id())) {
        throw unauthorized("invalid_naver_user_info");
      }

      return new VerifiedOAuthIdentity(
        PROVIDER,
        userInfo.id().trim(),
        blankToNull(userInfo.displayName()),
        blankToNull(userInfo.email()),
        blankToNull(userInfo.profileImageUrl())
      );
    }

    return devOAuthIdentityVerifier.verify(PROVIDER, request);
  }

  private String resolveProviderAccessToken(OAuthLoginRequest request) {
    if (StringUtils.hasText(request.providerAccessToken())) {
      return request.providerAccessToken().trim();
    }
    if (StringUtils.hasText(request.authorizationCode())) {
      return authorizationCodeExchanger.exchange(PROVIDER, request.authorizationCode().trim(), request.state())
        .filter(StringUtils::hasText)
        .map(String::trim)
        .orElseThrow(() -> unauthorized("naver_authorization_code_exchange_unavailable"));
    }
    throw unauthorized("missing_naver_provider_access_token");
  }

  private String blankToNull(String value) {
    return StringUtils.hasText(value) ? value.trim() : null;
  }

  private ResponseStatusException unauthorized(String reason) {
    return new ResponseStatusException(HttpStatus.UNAUTHORIZED, reason);
  }
}
