package com.onmu.api.domain;

import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ChatReadStateRepository extends JpaRepository<ChatReadStateEntity, UUID> {
  Optional<ChatReadStateEntity> findByGroupAndUser(GroupEntity group, UserEntity user);
}
