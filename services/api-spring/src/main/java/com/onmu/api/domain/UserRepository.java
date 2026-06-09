package com.onmu.api.domain;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserRepository extends JpaRepository<UserEntity, UUID> {
  Optional<UserEntity> findFirstByOrderByCreatedAtAsc();

  List<UserEntity> findAllByOrderByCreatedAtAsc();

  List<UserEntity> findByPublicIdIn(Collection<String> publicIds);

  List<UserEntity> findByDisplayNameIn(Collection<String> displayNames);
}
