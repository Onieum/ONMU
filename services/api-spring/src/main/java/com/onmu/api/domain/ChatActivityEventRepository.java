package com.onmu.api.domain;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ChatActivityEventRepository extends JpaRepository<ChatActivityEventEntity, UUID> {
  List<ChatActivityEventEntity> findByGroupOrderByCreatedAtAsc(GroupEntity group);
}
