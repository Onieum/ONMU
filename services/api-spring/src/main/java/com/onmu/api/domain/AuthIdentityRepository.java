package com.onmu.api.domain;

import java.util.Optional;
import java.util.UUID;
import java.time.Instant;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface AuthIdentityRepository extends JpaRepository<AuthIdentityEntity, UUID> {
  Optional<AuthIdentityEntity> findFirstByUserOrderByCreatedAtAsc(UserEntity user);

  Optional<AuthIdentityEntity> findByProviderAndProviderSubjectAndDeletedAtIsNull(
    String provider,
    String providerSubject
  );

  @Modifying
  @Query("""
    update AuthIdentityEntity identity
    set identity.deletedAt = :deletedAt
    where identity.user = :user
      and identity.deletedAt is null
    """)
  int softDeleteByUser(
    @Param("user") UserEntity user,
    @Param("deletedAt") Instant deletedAt
  );
}
