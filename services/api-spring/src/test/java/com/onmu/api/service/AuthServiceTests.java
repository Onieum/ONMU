package com.onmu.api.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.argThat;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.onmu.api.config.AuthProperties;
import com.onmu.api.domain.AuthIdentityEntity;
import com.onmu.api.domain.AuthIdentityRepository;
import com.onmu.api.domain.RefreshTokenEntity;
import com.onmu.api.domain.RefreshTokenRepository;
import com.onmu.api.domain.UserEntity;
import com.onmu.api.domain.UserRepository;
import com.onmu.api.security.AccessTokenIssuer;
import com.onmu.api.security.AccessTokenIssuer.IssuedAccessToken;
import com.onmu.api.web.dto.OAuthLoginRequest;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

@ExtendWith(MockitoExtension.class)
class AuthServiceTests {
  @Mock
  private UserRepository userRepository;
  @Mock
  private AuthIdentityRepository authIdentityRepository;
  @Mock
  private RefreshTokenRepository refreshTokenRepository;
  @Mock
  private AccessTokenIssuer accessTokenIssuer;
  @Mock
  private OAuthIdentityVerifier oAuthIdentityVerifier;
  @Mock
  private UserCodeService userCodeService;

  private AuthService authService;
  private UserEntity user;

  @BeforeEach
  void setUp() {
    authService = new AuthService(
      userRepository,
      authIdentityRepository,
      refreshTokenRepository,
      accessTokenIssuer,
      new AuthProperties(
        "test-access-token-secret-with-enough-length",
        "onmu-api-test",
        "onmu-mobile-test",
        Duration.ofMinutes(30),
        Duration.ofDays(30),
        Duration.ZERO,
        List.of("http://localhost:*")
      ),
      oAuthIdentityVerifier,
      userCodeService
    );
    user = new UserEntity("usr_test", "ONMU User", "user@example.test", null);
    lenient().when(userCodeService.ensureActiveCode(any(UserEntity.class))).thenReturn("4839201746");
  }

  @Test
  void oauthLoginFailsClosedWhenProviderCannotVerifyIdentity() {
    OAuthLoginRequest request = new OAuthLoginRequest(null, null, null, null, null, null);
    when(oAuthIdentityVerifier.verify("NAVER", request))
      .thenThrow(new ResponseStatusException(HttpStatus.UNAUTHORIZED, "oauth_provider_verification_unavailable"));

    assertThatThrownBy(() -> authService.oauthLogin("NAVER", request, "127.0.0.1", "test-agent"))
      .isInstanceOfSatisfying(ResponseStatusException.class, exception ->
        assertThat(exception.getReason()).isEqualTo("oauth_provider_verification_unavailable"));
    verify(authIdentityRepository, never()).findByProviderAndProviderSubjectAndDeletedAtIsNull(anyString(), anyString());
  }

  @Test
  void oauthLoginUsesVerifiedSubjectAndIssuesTokens() {
    OAuthLoginRequest request = new OAuthLoginRequest(null, null, "naver-dev-subject", "ONMU User", "user@example.test", null);
    AuthIdentityEntity identity = new AuthIdentityEntity("aid_test", user, "NAVER", "naver-dev-subject", "user@example.test");
    when(oAuthIdentityVerifier.verify("NAVER", request))
      .thenReturn(new VerifiedOAuthIdentity("NAVER", "naver-dev-subject", "ONMU User", "user@example.test", null));
    when(authIdentityRepository.findByProviderAndProviderSubjectAndDeletedAtIsNull("NAVER", "naver-dev-subject"))
      .thenReturn(Optional.of(identity));
    when(accessTokenIssuer.issue(user))
      .thenReturn(new IssuedAccessToken("access-token", Instant.parse("2026-07-01T00:00:00Z")));
    when(refreshTokenRepository.save(any(RefreshTokenEntity.class))).thenAnswer(invocation -> invocation.getArgument(0));

    Map<String, Object> response = authService.oauthLogin("NAVER", request, "127.0.0.1", "test-agent");

    assertThat(response).containsEntry("authenticated", true);
    verify(userCodeService).ensureActiveCode(user);
    verify(refreshTokenRepository).save(any(RefreshTokenEntity.class));
  }

  @Test
  void newOAuthUserGetsNumericUserCode() {
    OAuthLoginRequest request = new OAuthLoginRequest(null, null, "naver-new-subject", "New User", "new@example.test", null);
    when(oAuthIdentityVerifier.verify("NAVER", request))
      .thenReturn(new VerifiedOAuthIdentity("NAVER", "naver-new-subject", "New User", "new@example.test", null));
    when(authIdentityRepository.findByProviderAndProviderSubjectAndDeletedAtIsNull("NAVER", "naver-new-subject"))
      .thenReturn(Optional.empty());
    when(userRepository.saveAndFlush(any(UserEntity.class))).thenAnswer(invocation -> invocation.getArgument(0));
    when(authIdentityRepository.save(any(AuthIdentityEntity.class))).thenAnswer(invocation -> invocation.getArgument(0));
    when(userCodeService.ensureActiveCode(any(UserEntity.class))).thenReturn("4839201746");
    when(accessTokenIssuer.issue(any(UserEntity.class)))
      .thenReturn(new IssuedAccessToken("access-token", Instant.parse("2026-07-01T00:00:00Z")));
    when(refreshTokenRepository.save(any(RefreshTokenEntity.class))).thenAnswer(invocation -> invocation.getArgument(0));

    Map<String, Object> response = authService.oauthLogin("NAVER", request, "127.0.0.1", "test-agent");

    assertThat(response).containsEntry("authenticated", true);
    verify(userCodeService).ensureActiveCode(argThat(createdUser ->
      createdUser != null
        && "New User".equals(createdUser.getDisplayName())
        && "4839201746".matches("\\d{10}")));
  }

  @Test
  void googleOAuthLoginUsesVerifiedIdTokenSubjectAndIssuesOnmuTokens() {
    OAuthLoginRequest request = new OAuthLoginRequest(null, null, "google-id-token", null, null, null, null, null);
    AuthIdentityEntity identity = new AuthIdentityEntity("aid_google", user, "GOOGLE", "google-subject", "google@example.test");
    when(oAuthIdentityVerifier.verify("GOOGLE", request))
      .thenReturn(new VerifiedOAuthIdentity("GOOGLE", "google-subject", "Google User", "google@example.test", null));
    when(authIdentityRepository.findByProviderAndProviderSubjectAndDeletedAtIsNull("GOOGLE", "google-subject"))
      .thenReturn(Optional.of(identity));
    when(accessTokenIssuer.issue(user))
      .thenReturn(new IssuedAccessToken("onmu-access-token", Instant.parse("2026-07-01T00:00:00Z")));
    when(refreshTokenRepository.save(any(RefreshTokenEntity.class))).thenAnswer(invocation -> invocation.getArgument(0));

    Map<String, Object> response = authService.oauthLogin("GOOGLE", request, "127.0.0.1", "test-agent");

    assertThat(response).containsEntry("authenticated", true);
    assertThat(response).extracting("tokens")
      .isInstanceOfSatisfying(Map.class, tokens ->
        assertThat(tokens).containsEntry("accessToken", "onmu-access-token"));
    verify(userCodeService).ensureActiveCode(user);
    verify(refreshTokenRepository).save(any(RefreshTokenEntity.class));
  }

  @Test
  void existingOAuthUserWithDefaultNameIsUpdatedFromVerifiedProviderProfile() {
    OAuthLoginRequest request = new OAuthLoginRequest("kakao-auth-code", null, null, null, null, null, "state-123");
    AuthIdentityEntity identity = new AuthIdentityEntity("aid_kakao", user, "KAKAO", "kakao-subject", null);
    when(oAuthIdentityVerifier.verify("KAKAO", request))
      .thenReturn(new VerifiedOAuthIdentity(
        "KAKAO",
        "kakao-subject",
        "카카오 사용자",
        "kakao@example.test",
        "https://example.test/kakao.png"
      ));
    when(authIdentityRepository.findByProviderAndProviderSubjectAndDeletedAtIsNull("KAKAO", "kakao-subject"))
      .thenReturn(Optional.of(identity));
    when(accessTokenIssuer.issue(user))
      .thenReturn(new IssuedAccessToken("access-token", Instant.parse("2026-07-01T00:00:00Z")));
    when(refreshTokenRepository.save(any(RefreshTokenEntity.class))).thenAnswer(invocation -> invocation.getArgument(0));

    Map<String, Object> response = authService.oauthLogin("KAKAO", request, "127.0.0.1", "test-agent");

    assertThat(response).containsEntry("authenticated", true);
    assertThat(user.getDisplayName()).isEqualTo("카카오 사용자");
    assertThat(user.getProfileImageUrl()).isEqualTo("https://example.test/kakao.png");
    assertThat(response).extracting("user")
      .isInstanceOfSatisfying(Map.class, userPayload ->
        assertThat(userPayload).containsEntry("displayName", "카카오 사용자"));
  }

  @Test
  void existingOAuthUserWithCustomNameIsNotOverwrittenByProviderProfile() {
    UserEntity customUser = new UserEntity("usr_custom", "건동", "user@example.test", "https://example.test/me.png");
    OAuthLoginRequest request = new OAuthLoginRequest("kakao-auth-code", null, null, null, null, null, "state-123");
    AuthIdentityEntity identity = new AuthIdentityEntity("aid_kakao", customUser, "KAKAO", "kakao-subject", null);
    when(oAuthIdentityVerifier.verify("KAKAO", request))
      .thenReturn(new VerifiedOAuthIdentity(
        "KAKAO",
        "kakao-subject",
        "카카오 사용자",
        "kakao@example.test",
        "https://example.test/kakao.png"
      ));
    when(authIdentityRepository.findByProviderAndProviderSubjectAndDeletedAtIsNull("KAKAO", "kakao-subject"))
      .thenReturn(Optional.of(identity));
    when(accessTokenIssuer.issue(customUser))
      .thenReturn(new IssuedAccessToken("access-token", Instant.parse("2026-07-01T00:00:00Z")));
    when(refreshTokenRepository.save(any(RefreshTokenEntity.class))).thenAnswer(invocation -> invocation.getArgument(0));

    Map<String, Object> response = authService.oauthLogin("KAKAO", request, "127.0.0.1", "test-agent");

    assertThat(response).containsEntry("authenticated", true);
    assertThat(customUser.getDisplayName()).isEqualTo("건동");
    assertThat(customUser.getProfileImageUrl()).isEqualTo("https://example.test/me.png");
  }

  @Test
  void refreshRotatesActiveToken() {
    UUID familyId = UUID.randomUUID();
    RefreshTokenEntity currentToken = new RefreshTokenEntity(
      "rt_current",
      user,
      familyId,
      "stored-hash",
      null,
      Instant.now().minusSeconds(60),
      Instant.now().plusSeconds(3600),
      "127.0.0.1",
      "test-agent"
    );
    when(refreshTokenRepository.findByTokenHashForUpdate(anyString())).thenReturn(Optional.of(currentToken));
    when(accessTokenIssuer.issue(user))
      .thenReturn(new IssuedAccessToken("access-token", Instant.parse("2026-07-01T00:00:00Z")));
    when(refreshTokenRepository.save(any(RefreshTokenEntity.class))).thenAnswer(invocation -> invocation.getArgument(0));

    Map<String, Object> response = authService.refresh("refresh-token", "127.0.0.1", "test-agent");

    assertThat(response).containsEntry("authenticated", true);
    assertThat(currentToken.getRevokedAt()).isNotNull();
    verify(refreshTokenRepository).save(any(RefreshTokenEntity.class));
  }

  @Test
  void refreshReuseRevokesTokenFamily() {
    UUID familyId = UUID.randomUUID();
    RefreshTokenEntity reusedToken = new RefreshTokenEntity(
      "rt_reused",
      user,
      familyId,
      "stored-hash",
      null,
      Instant.now().minusSeconds(120),
      Instant.now().plusSeconds(3600),
      "127.0.0.1",
      "test-agent"
    );
    reusedToken.markRotated();
    when(refreshTokenRepository.findByTokenHashForUpdate(anyString())).thenReturn(Optional.of(reusedToken));

    assertThatThrownBy(() -> authService.refresh("refresh-token", "127.0.0.1", "test-agent"))
      .isInstanceOfSatisfying(ResponseStatusException.class, exception ->
        assertThat(exception.getReason()).isEqualTo("refresh_token_reuse_detected"));
    verify(refreshTokenRepository).revokeFamily(any(UUID.class), any(Instant.class), anyString());
  }
}
