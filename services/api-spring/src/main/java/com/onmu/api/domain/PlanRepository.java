package com.onmu.api.domain;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface PlanRepository extends JpaRepository<PlanEntity, UUID> {
  List<PlanEntity> findByGroupOrderByStartsAtAsc(GroupEntity group);

  @Query("""
    select plan
    from PlanEntity plan
    join PlanParticipantEntity participant on participant.plan = plan
    where plan.group = :group
      and participant.user = :user
      and (participant.status is null or lower(participant.status) not in ('left', 'declined'))
    order by plan.startsAt asc
    """)
  List<PlanEntity> findParticipatingByGroupAndUser(
    @Param("group") GroupEntity group,
    @Param("user") UserEntity user
  );

  Optional<PlanEntity> findByGroupAndPublicId(GroupEntity group, String publicId);

  @org.springframework.data.jpa.repository.Query(
    value = "SELECT EXISTS(SELECT 1 FROM plan_participants pp JOIN plans p ON pp.plan_id = p.id WHERE p.public_id = :planPublicId AND pp.user_id = :userId AND pp.status IN ('joined', 'invited', 'active'))",
    nativeQuery = true
  )
  boolean isUserParticipant(String planPublicId, java.util.UUID userId);
}
