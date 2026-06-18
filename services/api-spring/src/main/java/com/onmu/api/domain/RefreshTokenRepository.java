package com.onmu.api.domain;

import jakarta.persistence.LockModeType;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface RefreshTokenRepository extends JpaRepository<RefreshTokenEntity, UUID> {
  Optional<RefreshTokenEntity> findByTokenHash(String tokenHash);

  @Lock(LockModeType.PESSIMISTIC_WRITE)
  @Query("select token from RefreshTokenEntity token where token.tokenHash = :tokenHash")
  Optional<RefreshTokenEntity> findByTokenHashForUpdate(@Param("tokenHash") String tokenHash);

  @Modifying
  @Query("""
    update RefreshTokenEntity token
    set token.revokedAt = :revokedAt,
        token.revokedReason = :reason
    where token.tokenFamilyId = :tokenFamilyId
      and token.revokedAt is null
    """)
  int revokeFamily(
    @Param("tokenFamilyId") UUID tokenFamilyId,
    @Param("revokedAt") Instant revokedAt,
    @Param("reason") String reason
  );

  @Modifying
  @Query("""
    update RefreshTokenEntity token
    set token.revokedAt = :revokedAt,
        token.revokedReason = :reason
    where token.user = :user
      and token.revokedAt is null
    """)
  int revokeAllByUser(
    @Param("user") UserEntity user,
    @Param("revokedAt") Instant revokedAt,
    @Param("reason") String reason
  );
}
