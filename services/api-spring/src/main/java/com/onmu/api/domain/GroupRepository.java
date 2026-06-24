package com.onmu.api.domain;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface GroupRepository extends JpaRepository<GroupEntity, UUID> {
  List<GroupEntity> findAllByOrderByCreatedAtAsc();

  Optional<GroupEntity> findByPublicId(String publicId);

  @Query("""
    select distinct g
    from GroupEntity g
      left join GroupMemberEntity gm
        on gm.group = g
        and gm.user.id = :userId
        and gm.status in ('active', 'joined')
      left join GroupMemberEntity userMembership
        on userMembership.group = g
        and userMembership.user.id = :userId
    where gm.id is not null
      or (g.ownerUser.id = :userId and userMembership.id is null)
    order by g.createdAt asc
    """)
  List<GroupEntity> findVisibleForUserOrderByCreatedAtAsc(@Param("userId") UUID userId);

  @org.springframework.data.jpa.repository.Query(
    value = "SELECT EXISTS(SELECT 1 FROM group_members gm JOIN groups g ON gm.group_id = g.id WHERE g.public_id = :groupPublicId AND gm.user_id = :userId AND gm.status IN ('active', 'joined')) OR (EXISTS(SELECT 1 FROM groups WHERE public_id = :groupPublicId AND owner_user_id = :userId) AND NOT EXISTS(SELECT 1 FROM group_members gm JOIN groups g ON gm.group_id = g.id WHERE g.public_id = :groupPublicId AND gm.user_id = :userId))",
    nativeQuery = true
  )
  boolean isUserMember(String groupPublicId, java.util.UUID userId);
}
