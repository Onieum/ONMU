package com.onmu.api.domain;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface SchedulePlaceRepository extends JpaRepository<SchedulePlaceEntity, UUID> {
  List<SchedulePlaceEntity> findByPlanOrderBySortOrderAsc(PlanEntity plan);
}
