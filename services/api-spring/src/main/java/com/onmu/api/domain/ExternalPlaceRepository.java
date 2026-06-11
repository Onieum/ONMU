package com.onmu.api.domain;

import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ExternalPlaceRepository extends JpaRepository<ExternalPlaceEntity, UUID> {
  Optional<ExternalPlaceEntity> findByProviderAndProviderPlaceId(String provider, String providerPlaceId);
}
