package com.onmu.api.domain;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface ChatActivityEventRepository extends JpaRepository<ChatActivityEventEntity, UUID> {
  List<ChatActivityEventEntity> findByGroupOrderByCreatedAtAsc(GroupEntity group);

  Optional<ChatActivityEventEntity> findFirstByGroupOrderByCreatedAtDesc(GroupEntity group);

  Optional<ChatActivityEventEntity> findByIdAndGroup(UUID id, GroupEntity group);

  @Query("""
    select event from ChatActivityEventEntity event
    where event.group = :group
    order by event.createdAt desc, event.id desc
    """)
  List<ChatActivityEventEntity> findLatestPage(GroupEntity group, Pageable pageable);

  @Query("""
    select event from ChatActivityEventEntity event
    where event.group = :group
      and event.createdAt < :beforeCreatedAt
    order by event.createdAt desc, event.id desc
    """)
  List<ChatActivityEventEntity> findPageBefore(GroupEntity group, Instant beforeCreatedAt, Pageable pageable);

  @Query("""
    select event from ChatActivityEventEntity event
    where event.group = :group
      and event.createdAt > :afterCreatedAt
    order by event.createdAt asc, event.id asc
    """)
  List<ChatActivityEventEntity> findPageAfter(GroupEntity group, Instant afterCreatedAt, Pageable pageable);

  @Query("""
    select count(event) from ChatActivityEventEntity event
    where event.group = :group
      and (event.actorUser is null or event.actorUser.id <> :currentUserId)
    """)
  long countUnread(GroupEntity group, UUID currentUserId);

  @Query("""
    select count(event) from ChatActivityEventEntity event
    where event.group = :group
      and event.createdAt > :lastReadAt
      and (event.actorUser is null or event.actorUser.id <> :currentUserId)
    """)
  long countUnreadAfter(GroupEntity group, UUID currentUserId, Instant lastReadAt);
}
