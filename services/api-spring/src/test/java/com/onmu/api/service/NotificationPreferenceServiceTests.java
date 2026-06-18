package com.onmu.api.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.onmu.api.domain.NotificationPreferenceEntity;
import com.onmu.api.domain.NotificationPreferenceRepository;
import com.onmu.api.domain.UserEntity;
import com.onmu.api.domain.UserRepository;
import com.onmu.api.web.dto.NotificationPreferenceUpdateRequest;
import com.onmu.api.web.dto.UpdateNotificationPreferencesRequest;
import java.util.List;
import java.util.Map;
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
class NotificationPreferenceServiceTests {
  @Mock
  private NotificationPreferenceRepository notificationPreferenceRepository;
  @Mock
  private UserRepository userRepository;

  private NotificationPreferenceService service;
  private UserEntity user;

  @BeforeEach
  void setUp() {
    service = new NotificationPreferenceService(
      notificationPreferenceRepository,
      userRepository,
      new ObjectMapper()
    );
    user = new UserEntity(UUID.fromString("00000000-0000-0000-0000-000000000002"), "지민");
  }

  @Test
  void preferencesReturnsDefaultTypesAndChannelsWhenNoRowsExist() {
    when(notificationPreferenceRepository.findByUser_Id(user.getId())).thenReturn(List.of());

    var response = service.preferences(user.getId());

    assertThat(response.preferences()).hasSize(10);
    assertThat(response.preferences())
      .anySatisfy(preference -> {
        assertThat(preference.notificationType()).isEqualTo("chat_message");
        assertThat(preference.channel()).isEqualTo("in_app");
        assertThat(preference.enabled()).isTrue();
        assertThat(preference.quietHours()).isEmpty();
      });
  }

  @Test
  void updateUpsertsPreferenceAndReturnsStoredView() {
    when(userRepository.findById(user.getId())).thenReturn(Optional.of(user));
    when(notificationPreferenceRepository.findByUser_IdAndNotificationTypeAndChannel(
      user.getId(),
      "chat_message",
      "push"
    )).thenReturn(Optional.empty());
    when(notificationPreferenceRepository.save(any(NotificationPreferenceEntity.class)))
      .thenAnswer(invocation -> invocation.getArgument(0));
    when(notificationPreferenceRepository.findByUser_Id(user.getId())).thenReturn(List.of(
      new NotificationPreferenceEntity(user, "chat_message", "push", false, "{\"start\":\"22:00\"}")
    ));

    var response = service.update(user.getId(), new UpdateNotificationPreferencesRequest(List.of(
      new NotificationPreferenceUpdateRequest(
        "chat_message",
        "push",
        false,
        Map.of("start", "22:00")
      )
    )));

    ArgumentCaptor<NotificationPreferenceEntity> preferenceCaptor =
      ArgumentCaptor.forClass(NotificationPreferenceEntity.class);
    verify(notificationPreferenceRepository).save(preferenceCaptor.capture());
    assertThat(preferenceCaptor.getValue().isEnabled()).isFalse();
    assertThat(response.preferences())
      .anySatisfy(preference -> {
        assertThat(preference.notificationType()).isEqualTo("chat_message");
        assertThat(preference.channel()).isEqualTo("push");
        assertThat(preference.enabled()).isFalse();
        assertThat(preference.quietHours()).containsEntry("start", "22:00");
      });
  }

  @Test
  void isEnabledReturnsStoredValueOrDefaultTrue() {
    when(notificationPreferenceRepository.findByUser_IdAndNotificationTypeAndChannel(
      user.getId(),
      "chat_message",
      "in_app"
    )).thenReturn(Optional.of(new NotificationPreferenceEntity(
      user,
      "chat_message",
      "in_app",
      false,
      "{}"
    )));
    when(notificationPreferenceRepository.findByUser_IdAndNotificationTypeAndChannel(
      user.getId(),
      "chat_message",
      "push"
    )).thenReturn(Optional.empty());

    assertThat(service.isEnabled(user.getId(), "chat_message", "in_app")).isFalse();
    assertThat(service.isEnabled(user.getId(), "chat_message", "push")).isTrue();
  }

  @Test
  void updateRejectsUnsupportedType() {
    when(userRepository.findById(user.getId())).thenReturn(Optional.of(user));

    assertThatThrownBy(() -> service.update(user.getId(), new UpdateNotificationPreferencesRequest(List.of(
      new NotificationPreferenceUpdateRequest("marketing", "push", true, Map.of())
    ))))
      .isInstanceOf(ResponseStatusException.class)
      .hasMessageContaining("unsupported_notification_type");
  }

  @Test
  void updateRejectsUnsupportedChannel() {
    when(userRepository.findById(user.getId())).thenReturn(Optional.of(user));

    assertThatThrownBy(() -> service.update(user.getId(), new UpdateNotificationPreferencesRequest(List.of(
      new NotificationPreferenceUpdateRequest("chat_message", "email", true, Map.of())
    ))))
      .isInstanceOf(ResponseStatusException.class)
      .hasMessageContaining("unsupported_notification_channel");
  }
}
