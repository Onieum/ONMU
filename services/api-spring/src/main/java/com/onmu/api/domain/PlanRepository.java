package com.onmu.api.domain;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PlanRepository extends JpaRepository<PlanEntity, UUID> {
  List<PlanEntity> findByGroupOrderByStartsAtAsc(GroupEntity group);

  Optional<PlanEntity> findByGroupAndPublicId(GroupEntity group, String publicId);

  @org.springframework.data.jpa.repository.Query(
    value = "SELECT EXISTS(SELECT 1 FROM plan_participants pp JOIN plans p ON pp.plan_id = p.id WHERE p.public_id = :planPublicId AND pp.user_id = :userId AND pp.status IN ('joined', 'invited', 'active'))",
    nativeQuery = true
  )
  boolean isUserParticipant(String planPublicId, java.util.UUID userId);
}
