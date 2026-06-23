package com.onmu.api.domain;

import java.util.Optional;
import java.util.UUID;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface SettlementDraftRepository extends JpaRepository<SettlementDraftEntity, UUID> {
  Optional<SettlementDraftEntity> findByPlan(PlanEntity plan);

  @Query("select draft from SettlementDraftEntity draft where draft.plan = :plan and draft.status = 'draft'")
  Optional<SettlementDraftEntity> findActiveByPlan(@Param("plan") PlanEntity plan);

  @Lock(LockModeType.PESSIMISTIC_WRITE)
  @Query("select draft from SettlementDraftEntity draft where draft.plan = :plan and draft.status = 'draft'")
  Optional<SettlementDraftEntity> findActiveByPlanForUpdate(@Param("plan") PlanEntity plan);

  @Lock(LockModeType.PESSIMISTIC_WRITE)
  @Query("select draft from SettlementDraftEntity draft where draft.plan = :plan")
  Optional<SettlementDraftEntity> findByPlanForUpdate(@Param("plan") PlanEntity plan);
}
