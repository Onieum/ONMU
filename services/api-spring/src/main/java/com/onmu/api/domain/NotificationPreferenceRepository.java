package com.onmu.api.domain;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface NotificationPreferenceRepository extends JpaRepository<NotificationPreferenceEntity, UUID> {
  List<NotificationPreferenceEntity> findByUser_Id(UUID userId);

  Optional<NotificationPreferenceEntity> findByUser_IdAndNotificationTypeAndChannel(
    UUID userId,
    String notificationType,
    String channel
  );
}
