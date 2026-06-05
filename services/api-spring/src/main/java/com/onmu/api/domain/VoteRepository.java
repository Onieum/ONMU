package com.onmu.api.domain;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface VoteRepository extends JpaRepository<VoteEntity, UUID> {
  List<VoteEntity> findByGroupOrderByCreatedAtAsc(GroupEntity group);

  Optional<VoteEntity> findByGroupAndPublicId(GroupEntity group, String publicId);
}
