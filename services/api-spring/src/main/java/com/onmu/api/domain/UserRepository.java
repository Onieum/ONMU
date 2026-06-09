package com.onmu.api.domain;

import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserRepository extends JpaRepository<UserEntity, UUID> {
  Optional<UserEntity> findFirstByOrderByCreatedAtAsc();

  Optional<UserEntity> findByIdAndDeletedAtIsNull(UUID id);

  Optional<UserEntity> findByPublicIdAndDeletedAtIsNull(String publicId);
}
