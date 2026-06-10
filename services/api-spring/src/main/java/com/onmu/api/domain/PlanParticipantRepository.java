package com.onmu.api.domain;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PlanParticipantRepository extends JpaRepository<PlanParticipantEntity, UUID> {
  List<PlanParticipantEntity> findByPlanOrderByCreatedAtAsc(PlanEntity plan);

  Optional<PlanParticipantEntity> findByPlanAndUser(PlanEntity plan, UserEntity user);
}
