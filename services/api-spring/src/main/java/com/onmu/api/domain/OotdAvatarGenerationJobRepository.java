package com.onmu.api.domain;

import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface OotdAvatarGenerationJobRepository extends JpaRepository<OotdAvatarGenerationJobEntity, UUID> {
  Optional<OotdAvatarGenerationJobEntity> findByPublicId(String publicId);
}
