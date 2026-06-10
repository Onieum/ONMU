package com.onmu.api.domain;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserRepository extends JpaRepository<UserEntity, UUID> {
  Optional<UserEntity> findFirstByOrderByCreatedAtAsc();

  List<UserEntity> findAllByOrderByCreatedAtAsc();

  List<UserEntity> findByPublicIdIn(Collection<String> publicIds);

  List<UserEntity> findByDisplayNameIn(Collection<String> displayNames);
  @org.springframework.data.jpa.repository.Query(
    value = "SELECT COALESCE((SELECT consented FROM user_consents WHERE user_id = :userId AND consent_type = 'privacy' ORDER BY created_at DESC LIMIT 1), false)",
    nativeQuery = true
  )
  boolean checkPrivacyConsent(java.util.UUID userId);
}
