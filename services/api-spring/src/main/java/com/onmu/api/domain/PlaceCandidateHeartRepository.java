package com.onmu.api.domain;

import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PlaceCandidateHeartRepository extends JpaRepository<PlaceCandidateHeartEntity, UUID> {
  long countByCandidate(PlaceCandidateEntity candidate);

  boolean existsByCandidateAndUser(PlaceCandidateEntity candidate, UserEntity user);

  Optional<PlaceCandidateHeartEntity> findByCandidateAndUser(PlaceCandidateEntity candidate, UserEntity user);
}
