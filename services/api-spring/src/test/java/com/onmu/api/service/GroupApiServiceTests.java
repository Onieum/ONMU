package com.onmu.api.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.argThat;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.mock;
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
    currentUser = mock(UserEntity.class);
    lenient().when(currentUser.getDisplayName()).thenReturn("ONMU Dev User");
    group = new GroupEntity("1", "ONMU 개발 모임", currentUser);
  }

  @Test
  void groupDetailFallsBackWhenDescriptionIsNullAndMembersAreMissing() {
    when(userRepository.findFirstByOrderByCreatedAtAsc()).thenReturn(Optional.of(currentUser));
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(groupMemberRepository.findByGroupOrderByJoinedAtAsc(group)).thenReturn(List.of());

    Map<String, Object> detail = service.groupDetail("1");

    assertThat(detail)
      .containsEntry("id", "1")
      .containsEntry("name", "ONMU 개발 모임")
      .containsEntry("description", "ONMU 모임")
      .containsEntry("memberCount", 1);
    assertThat(detail.get("members")).isEqualTo(List.of("ONMU Dev User"));
  }

  @Test
  void updateGroupRejectsBlankName() {
    assertThatThrownBy(() -> service.updateGroup("1", new UpdateGroupRequest(" ", "설명")))
      .isInstanceOfSatisfying(ResponseStatusException.class, exception ->
        assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST));
  }

  @Test
  void updateGroupRecordsOutboxEvent() {
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));

    Map<String, Object> updated = service.updateGroup("1", new UpdateGroupRequest("새 이름", "새 설명"));

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
    when(userRepository.findFirstByOrderByCreatedAtAsc()).thenReturn(Optional.of(currentUser));
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(groupMemberRepository.findByGroupOrderByJoinedAtAsc(group)).thenReturn(List.of());

    List<Map<String, Object>> members = service.members("1");

    assertThat(members).hasSize(1);
    assertThat(members.getFirst())
      .containsEntry("name", "ONMU Dev User")
      .containsEntry("statusLabel", "참여 중")
      .containsEntry("invited", false);
  }

  @Test
  void leaveGroupSoftLeavesMembershipAndRecordsOutboxEvent() {
    when(userRepository.findFirstByOrderByCreatedAtAsc()).thenReturn(Optional.of(currentUser));
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    GroupMemberEntity membership = new GroupMemberEntity(group, currentUser, "member", "active");
    when(groupMemberRepository.findByGroupAndUser(group, currentUser)).thenReturn(Optional.of(membership));

    service.leaveGroup("1");

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
    when(userRepository.findFirstByOrderByCreatedAtAsc()).thenReturn(Optional.of(currentUser));
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(groupMemberRepository.findByGroupAndUser(group, currentUser)).thenReturn(Optional.empty());

    service.leaveGroup("1");
  }

  @Test
  void createGroupRecordsOutboxAndAddsOwnerMembership() {
    when(userRepository.findFirstByOrderByCreatedAtAsc()).thenReturn(Optional.of(currentUser));
    when(groupRepository.findAllByOrderByCreatedAtAsc()).thenReturn(List.of(group));
    when(groupRepository.save(any(GroupEntity.class))).thenAnswer(invocation -> invocation.getArgument(0));
    when(groupMemberRepository.save(any(GroupMemberEntity.class))).thenAnswer(invocation -> invocation.getArgument(0));

    Map<String, Object> created = service.createGroup("새 모임");

    assertThat(created).containsEntry("id", "2").containsEntry("name", "새 모임");
    verify(groupMemberRepository).save(argThat(member ->
      "owner".equals(member.getRole()) && "active".equals(member.getStatus())
    ));
    verify(outboxService).record(
      eq("group.created"),
      eq("group"),
      any(UUID.class),
      argThat(payload -> "2".equals(payload.get("groupId")) && "새 모임".equals(payload.get("name")))
    );
  }
}
