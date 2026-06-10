package com.onmu.api.domain;

import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserRepository extends JpaRepository<UserEntity, UUID> {
  Optional<UserEntity> findFirstByOrderByCreatedAtAsc();

  Optional<UserEntity> findByIdAndDeletedAtIsNull(UUID id);

  Optional<UserEntity> findByPublicIdAndDeletedAtIsNull(String publicId);
  @org.springframework.data.jpa.repository.Query(
    value = "SELECT COALESCE((SELECT consented FROM user_consents WHERE user_id = :userId AND consent_type = 'privacy' ORDER BY created_at DESC LIMIT 1), false)",
    nativeQuery = true
  )
  boolean checkPrivacyConsent(java.util.UUID userId);
}
