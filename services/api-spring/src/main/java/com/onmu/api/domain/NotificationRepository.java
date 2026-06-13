package com.onmu.api.domain;

import java.util.List;
import java.util.UUID;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface NotificationRepository extends JpaRepository<NotificationEntity, UUID> {
  @Query("""
    select notification from NotificationEntity notification
    left join fetch notification.group
    left join fetch notification.plan
    where notification.user.id = :userId
    order by notification.createdAt desc, notification.id desc
    """)
  List<NotificationEntity> findInboxByUserId(UUID userId, Pageable pageable);
}
