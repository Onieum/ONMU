package com.onmu.api.domain;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ExternalPlaceRepository extends JpaRepository<ExternalPlaceEntity, UUID> {
  Optional<ExternalPlaceEntity> findByProviderAndProviderPlaceId(String provider, String providerPlaceId);

  List<ExternalPlaceEntity> findByProviderAndCategoryInAndLatitudeIsNotNullAndLongitudeIsNotNull(
    String provider,
    Collection<String> categories
  );
}
