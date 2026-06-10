package com.onmu.api.domain;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface GroupRepository extends JpaRepository<GroupEntity, UUID> {
  List<GroupEntity> findAllByOrderByCreatedAtAsc();

  Optional<GroupEntity> findByPublicId(String publicId);

  @org.springframework.data.jpa.repository.Query(
    value = "SELECT EXISTS(SELECT 1 FROM group_members gm JOIN groups g ON gm.group_id = g.id WHERE g.public_id = :groupPublicId AND gm.user_id = :userId AND gm.status IN ('active', 'joined')) OR EXISTS(SELECT 1 FROM groups WHERE public_id = :groupPublicId AND owner_user_id = :userId)",
    nativeQuery = true
  )
  boolean isUserMember(String groupPublicId, java.util.UUID userId);
}
