package com.onmu.api.domain;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PlaceCandidateRepository extends JpaRepository<PlaceCandidateEntity, UUID> {
  List<PlaceCandidateEntity> findByPlanOrderByCreatedAtAsc(PlanEntity plan);

  Optional<PlaceCandidateEntity> findByPlanAndPublicId(PlanEntity plan, String publicId);

  Optional<PlaceCandidateEntity> findByPublicId(String publicId);
}
