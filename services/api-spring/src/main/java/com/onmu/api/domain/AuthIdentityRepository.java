package com.onmu.api.domain;

import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AuthIdentityRepository extends JpaRepository<AuthIdentityEntity, UUID> {
  Optional<AuthIdentityEntity> findFirstByUserOrderByCreatedAtAsc(UserEntity user);
}
