package com.onmu.api.service;

import com.onmu.api.domain.NotificationDeliveryEntity;
import com.onmu.api.domain.NotificationDeliveryRepository;
import com.onmu.api.domain.NotificationDeliveryResult;
import com.onmu.api.domain.NotificationEntity;
import com.onmu.api.domain.NotificationRepository;
import com.onmu.api.domain.OutboxEventEntity;
import java.time.Instant;
import java.util.Map;
import java.util.UUID;
import org.springframework.stereotype.Service;

@Service
public class NotificationDeliveryService {
  private final NotificationRepository notificationRepository;
  private final NotificationDeliveryRepository notificationDeliveryRepository;
  private final NotificationPreferenceService notificationPreferenceService;
  private final NotificationPushProvider notificationPushProvider;

  public NotificationDeliveryService(
    NotificationRepository notificationRepository,
    NotificationDeliveryRepository notificationDeliveryRepository,
    NotificationPreferenceService notificationPreferenceService,
    NotificationPushProvider notificationPushProvider
  ) {
    this.notificationRepository = notificationRepository;
    this.notificationDeliveryRepository = notificationDeliveryRepository;
    this.notificationPreferenceService = notificationPreferenceService;
    this.notificationPushProvider = notificationPushProvider;
  }

  public NotificationDeliveryOutcome processRequested(OutboxEventEntity event, Map<String, Object> payload) {
    UUID notificationId = notificationId(event, payload);
    if (notificationId == null) {
      return NotificationDeliveryOutcome.skippedDev("notification_id_missing");
    }

    NotificationEntity notification = notificationRepository.findById(notificationId).orElse(null);
    if (notification == null) {
      return NotificationDeliveryOutcome.skippedDev("notification_not_found");
    }

    boolean pushEnabled = notificationPreferenceService.isEnabled(
      notification.getUser().getId(),
      notification.getNotificationType(),
      "push"
    );
    NotificationDeliveryResult result = pushEnabled
      ? notificationPushProvider.deliver(notification, payload)
      : NotificationDeliveryResult.skippedDev("preference_disabled");

    Instant attemptedAt = Instant.now();
    NotificationDeliveryEntity delivery = new NotificationDeliveryEntity(
      notification,
      "push",
      result.provider(),
      attemptedAt
    );
    delivery.apply(result, attemptedAt);
    notificationDeliveryRepository.save(delivery);
    return NotificationDeliveryOutcome.fromDeliveryResult(result);
  }

  private UUID notificationId(OutboxEventEntity event, Map<String, Object> payload) {
    Object payloadNotificationId = payload.get("notificationId");
    if (payloadNotificationId != null) {
      try {
        return UUID.fromString(payloadNotificationId.toString());
      } catch (IllegalArgumentException ignored) {
        return null;
      }
    }
    if ("notification".equals(event.getAggregateType())) {
      return event.getAggregateId();
    }
    return null;
  }
}
