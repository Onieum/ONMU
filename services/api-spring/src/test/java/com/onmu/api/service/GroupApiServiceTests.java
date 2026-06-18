package com.onmu.api.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.argThat;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.onmu.api.domain.GroupEntity;
import com.onmu.api.domain.GroupMemberEntity;
import com.onmu.api.domain.GroupMemberRepository;
import com.onmu.api.domain.GroupRepository;
import com.onmu.api.domain.UserEntity;
import com.onmu.api.domain.UserRepository;
import com.onmu.api.web.dto.UpdateGroupRequest;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

@ExtendWith(MockitoExtension.class)
class GroupApiServiceTests {
  @Mock
  private UserRepository userRepository;
  @Mock
  private GroupRepository groupRepository;
  @Mock
  private GroupMemberRepository groupMemberRepository;
  @Mock
  private OutboxService outboxService;

  private GroupApiService service;
  private UserEntity currentUser;
  private GroupEntity group;

  @BeforeEach
  void setUp() {
    service = new GroupApiService(userRepository, groupRepository, groupMemberRepository, outboxService);
    currentUser = user("00000000-0000-0000-0000-000000000001", "ONMU Dev User");
    group = new GroupEntity("1", "ONMU 개발 모임", currentUser);
  }

  @Test
  void groupsReturnOnlyMembershipScopedGroups() {
    GroupEntity ownedGroup = new GroupEntity("2", "내 모임", currentUser);
    when(userRepository.findByIdAndDeletedAtIsNull(currentUser.getId())).thenReturn(Optional.of(currentUser));
    when(groupRepository.findVisibleForUserOrderByCreatedAtAsc(currentUser.getId())).thenReturn(List.of(ownedGroup));
    when(groupMemberRepository.findByGroupOrderByJoinedAtAsc(ownedGroup)).thenReturn(List.of(
      new GroupMemberEntity(ownedGroup, currentUser, "owner", "active")
    ));

    List<Map<String, Object>> groups = service.groups(currentUser.getId());

    assertThat(groups).singleElement().satisfies(value -> assertThat(value)
      .containsEntry("id", "2")
      .containsEntry("name", "내 모임")
      .containsEntry("memberCount", 1));
  }

  @Test
  void groupDetailRejectsNonMember() {
    when(userRepository.findByIdAndDeletedAtIsNull(currentUser.getId())).thenReturn(Optional.of(currentUser));
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(groupRepository.isUserMember("1", currentUser.getId())).thenReturn(false);

    assertThatThrownBy(() -> service.groupDetail("1", currentUser.getId()))
      .isInstanceOfSatisfying(ResponseStatusException.class, exception ->
        assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN));
  }

  @Test
  void groupDetailFallsBackWhenDescriptionIsNullAndMembersAreMissing() {
    when(userRepository.findByIdAndDeletedAtIsNull(currentUser.getId())).thenReturn(Optional.of(currentUser));
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(groupRepository.isUserMember("1", currentUser.getId())).thenReturn(true);
    when(groupMemberRepository.findByGroupOrderByJoinedAtAsc(group)).thenReturn(List.of());

    Map<String, Object> detail = service.groupDetail("1", currentUser.getId());

    assertThat(detail)
      .containsEntry("id", "1")
      .containsEntry("name", "ONMU 개발 모임")
      .containsEntry("description", "ONMU 모임")
      .containsEntry("memberCount", 1);
    assertThat(detail.get("members")).isEqualTo(List.of("ONMU Dev User"));
    assertThat(detail.get("memberProfiles")).asList().singleElement().satisfies(profile -> {
      Map<?, ?> profileMap = (Map<?, ?>) profile;
      assertThat(profileMap.get("name")).isEqualTo("ONMU Dev User");
      assertThat(profileMap.get("statusLabel")).isEqualTo("참여 중");
    });
  }

  @Test
  void updateGroupRejectsBlankName() {
    assertThatThrownBy(() -> service.updateGroup("1", currentUser.getId(), new UpdateGroupRequest(" ", "설명")))
      .isInstanceOfSatisfying(ResponseStatusException.class, exception ->
        assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST));
  }

  @Test
  void updateGroupRecordsOutboxEvent() {
    when(userRepository.findByIdAndDeletedAtIsNull(currentUser.getId())).thenReturn(Optional.of(currentUser));
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(groupRepository.isUserMember("1", currentUser.getId())).thenReturn(true);

    Map<String, Object> updated = service.updateGroup("1", currentUser.getId(), new UpdateGroupRequest("새 이름", "새 설명"));

    assertThat(updated)
      .containsEntry("name", "새 이름")
      .containsEntry("description", "새 설명");
    verify(outboxService).record(
      eq("group.updated"),
      eq("group"),
      eq(group.getId()),
      argThat(payload -> "1".equals(payload.get("groupId")) && "새 이름".equals(payload.get("name")))
    );
  }

  @Test
  void membersFallbackToOwnerWhenMembershipSeedIsMissing() {
    when(userRepository.findByIdAndDeletedAtIsNull(currentUser.getId())).thenReturn(Optional.of(currentUser));
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(groupRepository.isUserMember("1", currentUser.getId())).thenReturn(true);
    when(groupMemberRepository.findByGroupOrderByJoinedAtAsc(group)).thenReturn(List.of());

    List<Map<String, Object>> members = service.members("1", currentUser.getId());

    assertThat(members).hasSize(1);
    assertThat(members.getFirst())
      .containsEntry("name", "ONMU Dev User")
      .containsEntry("statusLabel", "참여 중")
      .containsEntry("invited", false);
  }

  @Test
  void membersExposeUserIdAndProfileImageForParticipantPicker() {
    UserEntity user = new UserEntity(
      UUID.fromString("00000000-0000-0000-0000-000000000001"),
      "지민"
    );
    user.updateProfile(null, "dev/avatars/jimin.png", null, null, null);
    GroupMemberEntity membership = new GroupMemberEntity(group, user, "member", "active");
    when(userRepository.findByIdAndDeletedAtIsNull(currentUser.getId())).thenReturn(Optional.of(currentUser));
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(groupRepository.isUserMember("1", currentUser.getId())).thenReturn(true);
    when(groupMemberRepository.findByGroupOrderByJoinedAtAsc(group)).thenReturn(List.of(membership));

    List<Map<String, Object>> members = service.members("1", currentUser.getId());

    assertThat(members).singleElement()
      .satisfies(member -> assertThat(member)
        .containsEntry("userId", user.getId().toString())
        .containsEntry("name", "지민")
        .containsEntry("profileImageUrl", "dev/avatars/jimin.png"));
  }

  @Test
  void leaveGroupSoftLeavesMembershipAndRecordsOutboxEvent() {
    when(userRepository.findByIdAndDeletedAtIsNull(currentUser.getId())).thenReturn(Optional.of(currentUser));
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(groupRepository.isUserMember("1", currentUser.getId())).thenReturn(true);
    GroupMemberEntity membership = new GroupMemberEntity(group, currentUser, "member", "active");
    when(groupMemberRepository.findByGroupAndUser(group, currentUser)).thenReturn(Optional.of(membership));

    service.leaveGroup("1", currentUser.getId());

    assertThat(membership.getStatus()).isEqualTo("left");
    assertThat(membership.getLeftAt()).isNotNull();
    verify(outboxService).record(
      eq("group.member_left"),
      eq("group"),
      eq(group.getId()),
      argThat(payload -> "1".equals(payload.get("groupId")))
    );
  }

  @Test
  void leaveGroupIsIdempotentWhenMembershipIsMissing() {
    when(userRepository.findByIdAndDeletedAtIsNull(currentUser.getId())).thenReturn(Optional.of(currentUser));
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(groupRepository.isUserMember("1", currentUser.getId())).thenReturn(true);
    when(groupMemberRepository.findByGroupAndUser(group, currentUser)).thenReturn(Optional.empty());

    service.leaveGroup("1", currentUser.getId());
  }

  @Test
  void createGroupRecordsOutboxAndAddsOwnerMembership() {
    when(userRepository.findByIdAndDeletedAtIsNull(currentUser.getId())).thenReturn(Optional.of(currentUser));
    when(groupRepository.findAllByOrderByCreatedAtAsc()).thenReturn(List.of(group));
    when(groupRepository.save(any(GroupEntity.class))).thenAnswer(invocation -> invocation.getArgument(0));
    when(groupMemberRepository.save(any(GroupMemberEntity.class))).thenAnswer(invocation -> invocation.getArgument(0));

    Map<String, Object> created = service.createGroup(currentUser.getId(), "새 모임", "새 소개");

    assertThat(created)
      .containsEntry("id", "2")
      .containsEntry("name", "새 모임")
      .containsEntry("description", "새 소개");
    verify(groupMemberRepository).save(argThat(member ->
      currentUser.equals(member.getUser()) &&
        "owner".equals(member.getRole()) &&
        "active".equals(member.getStatus())
    ));
    verify(outboxService).record(
      eq("group.created"),
      eq("group"),
      any(UUID.class),
      argThat(payload ->
        "2".equals(payload.get("groupId")) &&
          "새 모임".equals(payload.get("name")) &&
          "새 소개".equals(payload.get("description"))
      )
    );
  }

  private UserEntity user(String id, String nickname) {
    return new UserEntity(UUID.fromString(id), nickname);
  }
}
