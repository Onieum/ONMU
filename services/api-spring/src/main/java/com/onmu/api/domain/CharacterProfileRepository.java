package com.onmu.api.domain;

import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface CharacterProfileRepository extends JpaRepository<CharacterProfileEntity, UUID> {
  Optional<CharacterProfileEntity> findByUserId(UUID userId);
}
