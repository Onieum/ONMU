package com.onmu.api.domain;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface RecordTagRepository extends JpaRepository<RecordTagEntity, UUID> {
  List<RecordTagEntity> findByRecord(RecordEntity record);

  void deleteByRecord(RecordEntity record);
}
