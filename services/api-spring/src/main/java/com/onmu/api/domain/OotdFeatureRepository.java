package com.onmu.api.domain;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface OotdFeatureRepository extends JpaRepository<OotdFeatureEntity, UUID> {
  Optional<OotdFeatureEntity> findFirstByRecordOrderByCreatedAtDesc(RecordEntity record);
}
