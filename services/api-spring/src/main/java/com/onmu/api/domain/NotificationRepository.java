package com.onmu.api.domain;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface NotificationRepository extends JpaRepository<NotificationEntity, UUID> {
  @Query("""
    select notification from NotificationEntity notification
    left join fetch notification.group
    left join fetch notification.plan
    where notification.user.id = :userId
    order by notification.createdAt desc, notification.id desc
    """)
  List<NotificationEntity> findInboxByUserId(UUID userId, Pageable pageable);

  @Query("""
    select notification from NotificationEntity notification
    left join fetch notification.group
    left join fetch notification.plan
    where notification.id = :notificationId
      and notification.user.id = :userId
    """)
  Optional<NotificationEntity> findInboxItemByIdAndUserId(
    UUID notificationId,
    UUID userId
  );

  long countByUser_IdAndReadAtIsNull(UUID userId);

  @Modifying(clearAutomatically = true, flushAutomatically = true)
  @Query("""
    update NotificationEntity notification
       set notification.readAt = :readAt,
           notification.status = 'read'
     where notification.user.id = :userId
       and notification.readAt is null
    """)
  int markUnreadAsReadByUserId(
    @Param("userId") UUID userId,
    @Param("readAt") Instant readAt
  );

  @Modifying(clearAutomatically = true, flushAutomatically = true)
  @Query("""
    update NotificationEntity notification
       set notification.readAt = :readAt,
           notification.status = 'read'
     where notification.user.id = :userId
       and notification.group = :group
       and notification.notificationType = 'chat_message'
       and notification.readAt is null
    """)
  int markUnreadChatMessagesReadByUserIdAndGroup(
    @Param("userId") UUID userId,
    @Param("group") GroupEntity group,
    @Param("readAt") Instant readAt
  );
}
