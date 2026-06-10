package com.onmu.api.domain;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface SettlementRepository extends JpaRepository<SettlementEntity, UUID> {
  List<SettlementEntity> findByPlanOrderByCreatedAtDesc(PlanEntity plan);

  Optional<SettlementEntity> findFirstByPlanOrderByCreatedAtDesc(PlanEntity plan);

  Optional<SettlementEntity> findByPlanAndPublicId(PlanEntity plan, String publicId);
}
