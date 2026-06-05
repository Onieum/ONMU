package com.onmu.api.domain;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PlanRepository extends JpaRepository<PlanEntity, UUID> {
  List<PlanEntity> findByGroupOrderByStartsAtAsc(GroupEntity group);

  Optional<PlanEntity> findByGroupAndPublicId(GroupEntity group, String publicId);
}
