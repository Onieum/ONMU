package com.onmu.api.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.onmu.api.domain.UserDeviceEntity;
import com.onmu.api.domain.UserDeviceRepository;
import com.onmu.api.domain.UserEntity;
import com.onmu.api.domain.UserRepository;
import com.onmu.api.web.dto.PushTokenRegistrationRequest;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.web.server.ResponseStatusException;

@ExtendWith(MockitoExtension.class)
class PushTokenServiceTests {
  private static final Instant NOW = Instant.parse("2026-06-14T01:00:00Z");

  @Mock
  private UserRepository userRepository;
  @Mock
  private UserDeviceRepository userDeviceRepository;

  private PushTokenService service;
  private UserEntity user;

  @BeforeEach
  void setUp() {
    service = new PushTokenService(
      userRepository,
      userDeviceRepository,
      Clock.fixed(NOW, ZoneOffset.UTC)
    );
    user = new UserEntity(UUID.fromString("00000000-0000-0000-0000-000000000002"), "지민");
  }

  @Test
  void registerCreatesActivePushDeviceWithoutReturningFullToken() {
    when(userRepository.findByIdAndDeletedAtIsNull(user.getId())).thenReturn(Optional.of(user));
    when(userDeviceRepository.findFirstByUser_IdAndPushProviderAndPushTokenHashAndStatus(
      any(),
      any(),
      any(),
      any()
    )).thenReturn(Optional.empty());
    when(userDeviceRepository.save(any(UserDeviceEntity.class)))
      .thenAnswer(invocation -> invocation.getArgument(0));

    var response = service.register(user.getId(), request("fcm-token-1234567890"));

    ArgumentCaptor<UserDeviceEntity> deviceCaptor = ArgumentCaptor.forClass(UserDeviceEntity.class);
    verify(userDeviceRepository).save(deviceCaptor.capture());
    assertThat(deviceCaptor.getValue().getUser()).isEqualTo(user);
    assertThat(deviceCaptor.getValue().getPushProvider()).isEqualTo("fcm");
    assertThat(deviceCaptor.getValue().getPushToken()).isEqualTo("fcm-token-1234567890");
    assertThat(deviceCaptor.getValue().getPushTokenHash()).hasSize(64);
    assertThat(deviceCaptor.getValue().getPushTokenLast4()).isEqualTo("7890");
    assertThat(deviceCaptor.getValue().getStatus()).isEqualTo("active");
    assertThat(response.registered()).isTrue();
    assertThat(response.tokenLast4()).isEqualTo("7890");
    assertThat(response.toString()).doesNotContain("fcm-token-1234567890");
  }

  @Test
  void registerDeactivatesSameTokenForOtherUsersBeforeUpsert() {
    when(userRepository.findByIdAndDeletedAtIsNull(user.getId())).thenReturn(Optional.of(user));
    when(userDeviceRepository.save(any(UserDeviceEntity.class)))
      .thenAnswer(invocation -> invocation.getArgument(0));

    service.register(user.getId(), request("same-device-token-9999"));

    verify(userDeviceRepository).deactivateActiveTokenForOtherUsers(
      any(),
      any(),
      any(),
      any()
    );
  }

  @Test
  void deactivateMarksCurrentUsersActiveTokenInactive() {
    UserDeviceEntity device = new UserDeviceEntity(user, "android", NOW);
    device.registerPushToken(
      "fcm",
      "fcm-token-1234567890",
      "hash",
      "7890",
      "android",
      "1.0.0",
      "android-test",
      "Pixel",
      null,
      NOW
    );
    when(userDeviceRepository.findFirstByUser_IdAndPushProviderAndPushTokenHashAndStatus(
      any(),
      any(),
      any(),
      any()
    )).thenReturn(Optional.of(device));
    when(userDeviceRepository.save(any(UserDeviceEntity.class)))
      .thenAnswer(invocation -> invocation.getArgument(0));

    var response = service.deactivate(user.getId(), request("fcm-token-1234567890"));

    assertThat(response.registered()).isFalse();
    assertThat(response.status()).isEqualTo("inactive");
    assertThat(device.getPushTokenDisabledAt()).isEqualTo(NOW);
    verify(userDeviceRepository).save(device);
  }

  @Test
  void deactivateIsIdempotentWhenTokenIsAlreadyAbsent() {
    when(userDeviceRepository.findFirstByUser_IdAndPushProviderAndPushTokenHashAndStatus(
      any(),
      any(),
      any(),
      any()
    )).thenReturn(Optional.empty());

    var response = service.deactivate(user.getId(), request("fcm-token-1234567890"));

    assertThat(response.registered()).isFalse();
    assertThat(response.status()).isEqualTo("inactive");
    assertThat(response.deviceId()).isNull();
  }

  @Test
  void registerRejectsUnsupportedProvider() {
    assertThatThrownBy(() -> service.register(user.getId(), new PushTokenRegistrationRequest(
      "expo",
      "fcm-token-1234567890",
      "android",
      null,
      null,
      null,
      null
    )))
      .isInstanceOfSatisfying(ResponseStatusException.class, exception ->
        assertThat(exception.getReason()).isEqualTo("unsupported_push_provider"));
  }

  @Test
  void registerRejectsBlankToken() {
    assertThatThrownBy(() -> service.register(user.getId(), new PushTokenRegistrationRequest(
      "fcm",
      " ",
      "android",
      null,
      null,
      null,
      null
    )))
      .isInstanceOfSatisfying(ResponseStatusException.class, exception ->
        assertThat(exception.getReason()).isEqualTo("missing_push_token"));
  }

  private PushTokenRegistrationRequest request(String token) {
    return new PushTokenRegistrationRequest(
      "FCM",
      token,
      "Android",
      "1.0.0",
      "android-test",
      "Pixel",
      "device-hash"
    );
  }
}
