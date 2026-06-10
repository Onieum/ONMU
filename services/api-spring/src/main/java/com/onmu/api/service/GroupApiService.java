package com.onmu.api.service;

import com.onmu.api.domain.GroupEntity;
import com.onmu.api.domain.GroupMemberEntity;
import com.onmu.api.domain.GroupMemberRepository;
import com.onmu.api.domain.GroupRepository;
import com.onmu.api.domain.UserEntity;
import com.onmu.api.domain.UserRepository;
import com.onmu.api.web.dto.UpdateGroupRequest;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
public class GroupApiService {
  private static final String DEFAULT_GROUP_DESCRIPTION = "ONMU 모임";

  private final UserRepository userRepository;
  private final GroupRepository groupRepository;
  private final GroupMemberRepository groupMemberRepository;
  private final OutboxService outboxService;

  public GroupApiService(
    UserRepository userRepository,
    GroupRepository groupRepository,
    GroupMemberRepository groupMemberRepository,
    OutboxService outboxService
  ) {
    this.userRepository = userRepository;
    this.groupRepository = groupRepository;
    this.groupMemberRepository = groupMemberRepository;
    this.outboxService = outboxService;
  }

  @Transactional(readOnly = true)
  public Map<String, Object> groupDetail(String groupId) {
    GroupEntity group = group(groupId);
    List<Map<String, Object>> memberProfiles = membersFor(group, true);
    List<String> memberNames = memberProfiles.stream()
      .map(member -> String.valueOf(member.get("name")))
      .toList();

    return groupCard(group, memberProfiles.size(), memberNames);
  }

  @Transactional
  public Map<String, Object> updateGroup(String groupId, UpdateGroupRequest request) {
    if (request == null || request.name() == null || request.name().isBlank()) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "missing_group_name");
    }

    GroupEntity group = group(groupId);
    UserEntity user = userRepository.findFirstByOrderByCreatedAtAsc().orElse(null);
    group.update(request.name(), request.description(), user);
    groupRepository.save(group);
    outboxService.record(
      "group.updated",
      "group",
      group.getId(),
      Map.of(
        "groupId", group.getPublicId(),
        "name", group.getName(),
        "description", safeDescription(group)
      )
    );

    List<Map<String, Object>> memberProfiles = membersFor(group, true);
    List<String> memberNames = memberProfiles.stream()
      .map(member -> String.valueOf(member.get("name")))
      .toList();
    return groupCard(group, memberProfiles.size(), memberNames);
  }

  @Transactional(readOnly = true)
  public List<Map<String, Object>> members(String groupId) {
    return membersFor(group(groupId), true);
  }

  @Transactional
  public void leaveGroup(String groupId) {
    UserEntity user = currentUser();
    GroupEntity group = group(groupId);
    groupMemberRepository.findByGroupAndUser(group, user)
      .filter(membership -> !"left".equals(membership.getStatus()))
      .ifPresent(membership -> {
        membership.markLeft();
        groupMemberRepository.save(membership);
        outboxService.record(
          "group.member_left",
          "group",
          group.getId(),
          Map.of(
            "groupId", group.getPublicId(),
            "userId", user.getId() == null ? "" : user.getId().toString()
          )
        );
      });
  }

  @Transactional
  public Map<String, Object> createGroup(String name) {
    if (name == null || name.isBlank()) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "missing_group_name");
    }

    UserEntity user = currentUser();
    String publicId = nextPublicId(groupRepository.findAllByOrderByCreatedAtAsc().stream()
      .map(GroupEntity::getPublicId)
      .toList());
    GroupEntity group = groupRepository.save(new GroupEntity(publicId, name.trim(), user));
    groupMemberRepository.save(new GroupMemberEntity(group, user, "owner", "active"));
    outboxService.record(
      "group.created",
      "group",
      group.getId(),
      Map.of(
        "groupId", group.getPublicId(),
        "name", group.getName(),
        "ownerUserId", user.getId() == null ? "" : user.getId().toString()
      )
    );

    return groupCard(group, 1, List.of(displayName(user)));
  }

  private List<Map<String, Object>> membersFor(GroupEntity group, boolean fallbackToOwner) {
    List<GroupMemberEntity> memberships = groupMemberRepository.findByGroupOrderByJoinedAtAsc(group);
    List<GroupMemberEntity> visibleMemberships = memberships.stream()
      .filter(membership -> !"left".equals(membership.getStatus()))
      .sorted(Comparator.comparingInt(this::memberStatusOrder))
      .toList();
    if (!visibleMemberships.isEmpty()) {
      return visibleMemberships.stream().map(this::memberProfile).toList();
    }
    if (!memberships.isEmpty()) {
      return List.of();
    }
    if (!fallbackToOwner) {
      return List.of();
    }

    UserEntity fallbackUser = userRepository.findFirstByOrderByCreatedAtAsc()
      .orElse(group.getOwnerUser());
    return List.of(Map.of(
      "name", displayName(fallbackUser),
      "note", roleNote("owner"),
      "statusLabel", "참여 중",
      "invited", false
    ));
  }

  private Map<String, Object> memberProfile(GroupMemberEntity member) {
    String status = member.getStatus();
    return Map.of(
      "name", memberDisplayName(member),
      "note", roleNote(member.getRole()),
      "statusLabel", statusLabel(status),
      "invited", isInvited(status)
    );
  }

  private Map<String, Object> groupCard(GroupEntity group, int memberCount, List<String> members) {
    return Map.of(
      "id", group.getPublicId(),
      "name", group.getName(),
      "description", safeDescription(group),
      "members", members,
      "memberCount", memberCount,
      "memberCountLabel", memberCount + "명",
      "role", "모임장",
      "lastMessage", "",
      "unreadCount", 0,
      "pinnedPlanTitle", ""
    );
  }

  private GroupEntity group(String groupId) {
    return groupRepository.findByPublicId(groupId)
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "group_not_found"));
  }

  private UserEntity currentUser() {
    return userRepository.findFirstByOrderByCreatedAtAsc()
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "user_not_found"));
  }

  private String safeDescription(GroupEntity group) {
    if (group.getDescription() == null || group.getDescription().isBlank()) {
      return DEFAULT_GROUP_DESCRIPTION;
    }
    return group.getDescription();
  }

  private String memberDisplayName(GroupMemberEntity member) {
    if (member.getDisplayNameOverride() != null && !member.getDisplayNameOverride().isBlank()) {
      return member.getDisplayNameOverride();
    }
    return displayName(member.getUser());
  }

  private String displayName(UserEntity user) {
    if (user == null) {
      return "ONMU 사용자";
    }
    if (user.getDisplayName() != null && !user.getDisplayName().isBlank()) {
      return user.getDisplayName();
    }
    if (user.getNickname() != null && !user.getNickname().isBlank()) {
      return user.getNickname();
    }
    return "ONMU 사용자";
  }

  private String roleNote(String role) {
    if ("owner".equals(role)) {
      return "모임장";
    }
    return "멤버";
  }

  private String statusLabel(String status) {
    return switch (status) {
      case "pending", "invited" -> "초대 중";
      case "left" -> "나감";
      default -> "참여 중";
    };
  }

  private boolean isInvited(String status) {
    return "pending".equals(status) || "invited".equals(status);
  }

  private int memberStatusOrder(GroupMemberEntity member) {
    return switch (member.getStatus()) {
      case "active" -> 0;
      case "pending", "invited" -> 1;
      case "left" -> 2;
      default -> 3;
    };
  }

  private String nextPublicId(List<String> values) {
    return values.stream()
      .map(value -> {
        try {
          return Integer.parseInt(value);
        } catch (NumberFormatException ignored) {
          return 0;
        }
      })
      .max(Integer::compareTo)
      .map(value -> value + 1)
      .orElse(1)
      .toString();
  }
}
