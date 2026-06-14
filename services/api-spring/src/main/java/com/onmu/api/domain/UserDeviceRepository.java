package com.onmu.api.domain;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface UserDeviceRepository extends JpaRepository<UserDeviceEntity, UUID> {
  Optional<UserDeviceEntity> findFirstByUser_IdAndPushProviderAndPushTokenHashAndStatus(
    UUID userId,
    String pushProvider,
    String pushTokenHash,
    String status
  );

  @Modifying
  @Query("""
    update UserDeviceEntity device
    set device.status = 'inactive',
        device.pushTokenDisabledAt = :now,
        device.updatedAt = :now
    where device.pushProvider = :provider
      and device.pushTokenHash = :tokenHash
      and device.user.id <> :userId
      and device.status = 'active'
    """)
  int deactivateActiveTokenForOtherUsers(
    @Param("userId") UUID userId,
    @Param("provider") String provider,
    @Param("tokenHash") String tokenHash,
    @Param("now") Instant now
  );
}
