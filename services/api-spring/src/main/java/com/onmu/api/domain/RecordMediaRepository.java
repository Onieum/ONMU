package com.onmu.api.domain;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface RecordMediaRepository extends JpaRepository<RecordMediaEntity, UUID> {
  List<RecordMediaEntity> findByRecordOrderBySortOrderAsc(RecordEntity record);
}
