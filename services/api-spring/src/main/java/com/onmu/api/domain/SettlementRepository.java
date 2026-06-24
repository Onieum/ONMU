package com.onmu.api.domain;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface SettlementRepository extends JpaRepository<SettlementEntity, UUID> {
  @Query("select settlement.publicId from SettlementEntity settlement")
  List<String> findPublicIds();

  List<SettlementEntity> findByPlanOrderByCreatedAtDesc(PlanEntity plan);

  Optional<SettlementEntity> findFirstByPlanOrderByCreatedAtDesc(PlanEntity plan);

  Optional<SettlementEntity> findFirstByPlanAndStatusInOrderByCreatedAtDesc(PlanEntity plan, List<String> statuses);

  Optional<SettlementEntity> findByPlanAndPublicId(PlanEntity plan, String publicId);

  @Lock(LockModeType.PESSIMISTIC_WRITE)
  @Query("select settlement from SettlementEntity settlement where settlement.plan = :plan and settlement.publicId = :publicId")
  Optional<SettlementEntity> findByPlanAndPublicIdForUpdate(
    @Param("plan") PlanEntity plan,
    @Param("publicId") String publicId
  );
}
