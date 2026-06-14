package com.onmu.api.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.onmu.api.domain.NotificationDeliveryEntity;
import com.onmu.api.domain.NotificationDeliveryRepository;
import com.onmu.api.domain.NotificationDeliveryResult;
import com.onmu.api.domain.NotificationEntity;
import com.onmu.api.domain.NotificationRepository;
import com.onmu.api.domain.OutboxEventEntity;
import com.onmu.api.domain.UserEntity;
import java.time.Instant;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class NotificationDeliveryServiceTests {
  @Mock
  private NotificationRepository notificationRepository;
  @Mock
  private NotificationDeliveryRepository notificationDeliveryRepository;
  @Mock
  private NotificationPreferenceService notificationPreferenceService;
  @Mock
  private NotificationPushProvider notificationPushProvider;

  private NotificationDeliveryService service;
  private UserEntity user;
  private NotificationEntity notification;

  @BeforeEach
  void setUp() {
    service = new NotificationDeliveryService(
      notificationRepository,
      notificationDeliveryRepository,
      notificationPreferenceService,
      notificationPushProvider
    );
    user = new UserEntity(UUID.fromString("00000000-0000-0000-0000-000000000002"), "지민");
    notification = new NotificationEntity(
      user,
      null,
      null,
      "chat_message",
      "새 메시지",
      "메시지를 확인해 주세요.",
      "{}",
      "queued",
      null,
      Instant.parse("2026-06-09T05:12:00Z")
    );
  }

  @Test
  void processRequestedCreatesDevSkippedDeliveryWhenPushIsEnabled() {
    UUID notificationId = UUID.fromString("00000000-0000-0000-0000-000000001211");
    OutboxEventEntity event = notificationEvent(notificationId);
    when(notificationRepository.findById(notificationId)).thenReturn(Optional.of(notification));
    when(notificationPreferenceService.isEnabled(user.getId(), "chat_message", "push")).thenReturn(true);
    when(notificationPushProvider.deliver(notification, Map.of("notificationId", notificationId.toString())))
      .thenReturn(NotificationDeliveryResult.skippedDev("dev_push_delivery_disabled"));
    when(notificationDeliveryRepository.save(any(NotificationDeliveryEntity.class)))
      .thenAnswer(invocation -> invocation.getArgument(0));

    NotificationDeliveryOutcome outcome = service.processRequested(
      event,
      Map.of("notificationId", notificationId.toString())
    );

    ArgumentCaptor<NotificationDeliveryEntity> deliveryCaptor =
      ArgumentCaptor.forClass(NotificationDeliveryEntity.class);
    verify(notificationDeliveryRepository).save(deliveryCaptor.capture());
    assertThat(deliveryCaptor.getValue().getNotification()).isEqualTo(notification);
    assertThat(deliveryCaptor.getValue().getChannel()).isEqualTo("push");
    assertThat(deliveryCaptor.getValue().getProvider()).isEqualTo("dev");
    assertThat(deliveryCaptor.getValue().getStatus()).isEqualTo("skipped_dev");
    assertThat(deliveryCaptor.getValue().getErrorMessage()).isEqualTo("dev_push_delivery_disabled");
    assertThat(outcome.outboxStatus()).isEqualTo("skipped_dev");
    assertThat(outcome.lastError()).isNull();
  }

  @Test
  void processRequestedRecordsPreferenceDisabledWhenPushIsOff() {
    UUID notificationId = UUID.fromString("00000000-0000-0000-0000-000000001212");
    OutboxEventEntity event = notificationEvent(notificationId);
    when(notificationRepository.findById(notificationId)).thenReturn(Optional.of(notification));
    when(notificationPreferenceService.isEnabled(user.getId(), "chat_message", "push")).thenReturn(false);
    when(notificationDeliveryRepository.save(any(NotificationDeliveryEntity.class)))
      .thenAnswer(invocation -> invocation.getArgument(0));

    NotificationDeliveryOutcome outcome = service.processRequested(event, Map.of());

    ArgumentCaptor<NotificationDeliveryEntity> deliveryCaptor =
      ArgumentCaptor.forClass(NotificationDeliveryEntity.class);
    verify(notificationDeliveryRepository).save(deliveryCaptor.capture());
    assertThat(deliveryCaptor.getValue().getStatus()).isEqualTo("skipped_dev");
    assertThat(deliveryCaptor.getValue().getErrorMessage()).isEqualTo("preference_disabled");
    verify(notificationPushProvider, never()).deliver(any(), any());
    assertThat(outcome.outboxStatus()).isEqualTo("skipped_dev");
    assertThat(outcome.lastError()).isNull();
  }

  @Test
  void processRequestedMarksOutboxPublishedWhenProviderSends() {
    UUID notificationId = UUID.fromString("00000000-0000-0000-0000-000000001214");
    Instant deliveredAt = Instant.parse("2026-06-09T05:13:00Z");
    OutboxEventEntity event = notificationEvent(notificationId);
    when(notificationRepository.findById(notificationId)).thenReturn(Optional.of(notification));
    when(notificationPreferenceService.isEnabled(user.getId(), "chat_message", "push")).thenReturn(true);
    when(notificationPushProvider.deliver(notification, Map.of("notificationId", notificationId.toString())))
      .thenReturn(NotificationDeliveryResult.sent("fcm", "provider-message-1", deliveredAt));
    when(notificationDeliveryRepository.save(any(NotificationDeliveryEntity.class)))
      .thenAnswer(invocation -> invocation.getArgument(0));

    NotificationDeliveryOutcome outcome = service.processRequested(
      event,
      Map.of("notificationId", notificationId.toString())
    );

    ArgumentCaptor<NotificationDeliveryEntity> deliveryCaptor =
      ArgumentCaptor.forClass(NotificationDeliveryEntity.class);
    verify(notificationDeliveryRepository).save(deliveryCaptor.capture());
    assertThat(deliveryCaptor.getValue().getProvider()).isEqualTo("fcm");
    assertThat(deliveryCaptor.getValue().getStatus()).isEqualTo("sent");
    assertThat(deliveryCaptor.getValue().getProviderMessageId()).isEqualTo("provider-message-1");
    assertThat(deliveryCaptor.getValue().getDeliveredAt()).isEqualTo(deliveredAt);
    assertThat(outcome.outboxStatus()).isEqualTo("published");
    assertThat(outcome.lastError()).isNull();
  }

  @Test
  void processRequestedMarksOutboxFailedWhenProviderFails() {
    UUID notificationId = UUID.fromString("00000000-0000-0000-0000-000000001215");
    OutboxEventEntity event = notificationEvent(notificationId);
    when(notificationRepository.findById(notificationId)).thenReturn(Optional.of(notification));
    when(notificationPreferenceService.isEnabled(user.getId(), "chat_message", "push")).thenReturn(true);
    when(notificationPushProvider.deliver(notification, Map.of("notificationId", notificationId.toString())))
      .thenReturn(NotificationDeliveryResult.failed("fcm", "provider_unavailable"));
    when(notificationDeliveryRepository.save(any(NotificationDeliveryEntity.class)))
      .thenAnswer(invocation -> invocation.getArgument(0));

    NotificationDeliveryOutcome outcome = service.processRequested(
      event,
      Map.of("notificationId", notificationId.toString())
    );

    ArgumentCaptor<NotificationDeliveryEntity> deliveryCaptor =
      ArgumentCaptor.forClass(NotificationDeliveryEntity.class);
    verify(notificationDeliveryRepository).save(deliveryCaptor.capture());
    assertThat(deliveryCaptor.getValue().getProvider()).isEqualTo("fcm");
    assertThat(deliveryCaptor.getValue().getStatus()).isEqualTo("failed");
    assertThat(deliveryCaptor.getValue().getErrorMessage()).isEqualTo("provider_unavailable");
    assertThat(outcome.outboxStatus()).isEqualTo("failed");
    assertThat(outcome.lastError()).isEqualTo("provider_unavailable");
  }

  @Test
  void processRequestedSkipsWhenNotificationIdIsMissing() {
    OutboxEventEntity event = new OutboxEventEntity(
      "notification.requested",
      "settlement",
      UUID.randomUUID(),
      "{\"settlementId\":\"302\"}"
    );

    NotificationDeliveryOutcome outcome = service.processRequested(event, Map.of("settlementId", "302"));

    assertThat(outcome.outboxStatus()).isEqualTo("skipped_dev");
    assertThat(outcome.lastError()).isEqualTo("notification_id_missing");
    verify(notificationDeliveryRepository, never()).save(any());
  }

  @Test
  void processRequestedSkipsWhenNotificationDoesNotExist() {
    UUID notificationId = UUID.fromString("00000000-0000-0000-0000-000000001213");
    OutboxEventEntity event = notificationEvent(notificationId);
    when(notificationRepository.findById(notificationId)).thenReturn(Optional.empty());

    NotificationDeliveryOutcome outcome = service.processRequested(
      event,
      Map.of("notificationId", notificationId.toString())
    );

    assertThat(outcome.outboxStatus()).isEqualTo("skipped_dev");
    assertThat(outcome.lastError()).isEqualTo("notification_not_found");
    verify(notificationDeliveryRepository, never()).save(any());
  }

  private OutboxEventEntity notificationEvent(UUID notificationId) {
    return new OutboxEventEntity(
      "notification.requested",
      "notification",
      notificationId,
      "{\"notificationId\":\"" + notificationId + "\"}"
    );
  }
}
