package com.onmu.api.domain;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface GroupRepository extends JpaRepository<GroupEntity, UUID> {
  List<GroupEntity> findAllByOrderByCreatedAtAsc();

  Optional<GroupEntity> findByPublicId(String publicId);
}
