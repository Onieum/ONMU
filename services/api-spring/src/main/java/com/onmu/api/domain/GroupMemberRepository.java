package com.onmu.api.domain;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface GroupMemberRepository extends JpaRepository<GroupMemberEntity, UUID> {
  List<GroupMemberEntity> findByGroupOrderByJoinedAtAsc(GroupEntity group);

  Optional<GroupMemberEntity> findByGroupAndUser(GroupEntity group, UserEntity user);
}
