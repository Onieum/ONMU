package com.onmu.api.domain;

import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface SettlementDraftRepository extends JpaRepository<SettlementDraftEntity, UUID> {
  Optional<SettlementDraftEntity> findByPlan(PlanEntity plan);
}
