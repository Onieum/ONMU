package com.onmu.api.service;

import com.onmu.api.domain.GroupEntity;
import com.onmu.api.domain.GroupMemberEntity;
import com.onmu.api.domain.GroupMemberRepository;
import com.onmu.api.domain.GroupRepository;
import com.onmu.api.domain.UserEntity;
import com.onmu.api.domain.UserRepository;
import com.onmu.api.web.dto.AddGroupMemberRequest;
import com.onmu.api.web.dto.UpdateGroupRequest;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
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
  public List<Map<String, Object>> groups(UUID userId) {
    UserEntity user = user(userId);
    return groupRepository.findVisibleForUserOrderByCreatedAtAsc(user.getId()).stream()
      .map(this::groupCard)
      .toList();
  }

  @Transactional(readOnly = true)
  public Map<String, Object> groupDetail(String groupId, UUID userId) {
    UserEntity user = user(userId);
    GroupEntity group = memberGroup(groupId, user);
    List<Map<String, Object>> memberProfiles = membersFor(group, true);
    List<String> memberNames = memberProfiles.stream()
      .map(member -> String.valueOf(member.get("name")))
      .toList();

    return groupCard(group, memberProfiles.size(), memberNames, memberProfiles);
  }

  @Transactional
  public Map<String, Object> updateGroup(String groupId, UUID userId, UpdateGroupRequest request) {
    if (request == null || request.name() == null || request.name().isBlank()) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "missing_group_name");
    }

    UserEntity user = user(userId);
    GroupEntity group = memberGroup(groupId, user);
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
    return groupCard(group, memberProfiles.size(), memberNames, memberProfiles);
  }

  @Transactional(readOnly = true)
  public List<Map<String, Object>> members(String groupId, UUID userId) {
    UserEntity user = user(userId);
    return membersFor(memberGroup(groupId, user), true);
  }

  @Transactional
  public Map<String, Object> addMember(String groupId, UUID userId, AddGroupMemberRequest request) {
    if (request == null || request.userId() == null || request.userId().isBlank()) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "missing_user_id");
    }
    UserEntity currentUser = user(userId);
    GroupEntity group = memberGroup(groupId, currentUser);
    UserEntity targetUser = user(parseUserId(request.userId()));
    GroupMemberEntity membership = groupMemberRepository.findByGroupAndUser(group, targetUser)
      .map(existing -> {
        if ("left".equals(existing.getStatus())) {
          existing.markActive();
          return groupMemberRepository.save(existing);
        }
        return existing;
      })
      .orElseGet(() -> groupMemberRepository.save(new GroupMemberEntity(group, targetUser, "member", "active")));
    outboxService.record(
      "group.member_added",
      "group",
      group.getId(),
      Map.of(
        "groupId", group.getPublicId(),
        "userId", targetUser.getId() == null ? "" : targetUser.getId().toString()
      )
    );
    return memberProfile(membership);
  }

  @Transactional
  public void leaveGroup(String groupId, UUID userId) {
    UserEntity user = user(userId);
    GroupEntity group = memberGroup(groupId, user);
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
  public Map<String, Object> createGroup(UUID userId, String name, String description) {
    if (name == null || name.isBlank()) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "missing_group_name");
    }

    UserEntity user = user(userId);
    String publicId = nextPublicId(groupRepository.findAllByOrderByCreatedAtAsc().stream()
      .map(GroupEntity::getPublicId)
      .toList());
    GroupEntity group = new GroupEntity(publicId, name.trim(), user);
    group.update(name, description, user);
    group = groupRepository.save(group);
    groupMemberRepository.save(new GroupMemberEntity(group, user, "owner", "active"));
    outboxService.record(
      "group.created",
      "group",
      group.getId(),
      Map.of(
        "groupId", group.getPublicId(),
        "name", group.getName(),
        "description", safeDescription(group),
        "ownerUserId", user.getId() == null ? "" : user.getId().toString()
      )
    );

    return groupCard(group, 1, List.of(nickname(user)), List.of(userProfile(user, "owner", "active")));
  }

  private Map<String, Object> groupCard(GroupEntity group) {
    List<Map<String, Object>> memberProfiles = membersFor(group, true);
    List<String> memberNames = memberProfiles.stream()
      .map(member -> String.valueOf(member.get("name")))
      .toList();
    return groupCard(group, memberProfiles.size(), memberNames, memberProfiles);
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

    UserEntity fallbackUser = group.getOwnerUser();
    return List.of(userProfile(fallbackUser, "owner", "active"));
  }

  private Map<String, Object> memberProfile(GroupMemberEntity member) {
    return userProfile(member.getUser(), member.getRole(), member.getStatus(), memberName(member));
  }

  private Map<String, Object> userProfile(UserEntity user, String role, String status) {
    return userProfile(user, role, status, nickname(user));
  }

  private Map<String, Object> userProfile(UserEntity user, String role, String status, String name) {
    Map<String, Object> value = new LinkedHashMap<>();
    value.put("userId", user == null || user.getId() == null ? "" : user.getId().toString());
    value.put("name", name);
    value.put("nickname", nickname(user));
    value.put("note", roleNote(role));
    value.put("statusLabel", statusLabel(status));
    value.put("invited", isInvited(status));
    value.put("profileImageUrl", user == null ? null : user.getProfileImageUrl());
    return value;
  }

  private Map<String, Object> groupCard(
    GroupEntity group,
    int memberCount,
    List<String> members,
    List<Map<String, Object>> memberProfiles
  ) {
    Map<String, Object> value = new LinkedHashMap<>();
    value.put("id", group.getPublicId());
    value.put("name", group.getName());
    value.put("description", safeDescription(group));
    value.put("members", members);
    value.put("memberProfiles", memberProfiles);
    value.put("memberCount", memberCount);
    value.put("memberCountLabel", memberCount + "명");
    value.put("role", "모임장");
    value.put("lastMessage", "");
    value.put("unreadCount", 0);
    value.put("pinnedPlanTitle", "");
    return value;
  }

  private GroupEntity group(String groupId) {
    return groupRepository.findByPublicId(groupId)
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "group_not_found"));
  }

  private GroupEntity memberGroup(String groupId, UserEntity user) {
    GroupEntity group = group(groupId);
    if (user.getId() == null || !groupRepository.isUserMember(group.getPublicId(), user.getId())) {
      throw new ResponseStatusException(HttpStatus.FORBIDDEN, "group_forbidden");
    }
    return group;
  }

  private UserEntity user(UUID userId) {
    return userRepository.findByIdAndDeletedAtIsNull(userId)
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "user_not_found"));
  }

  private UUID parseUserId(String value) {
    try {
      return UUID.fromString(value.trim());
    } catch (IllegalArgumentException exception) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "invalid_user_id");
    }
  }

  private String safeDescription(GroupEntity group) {
    if (group.getDescription() == null || group.getDescription().isBlank()) {
      return DEFAULT_GROUP_DESCRIPTION;
    }
    return group.getDescription();
  }

  private String memberName(GroupMemberEntity member) {
    if (member.getNameOverride() != null && !member.getNameOverride().isBlank()) {
      return member.getNameOverride();
    }
    return nickname(member.getUser());
  }

  private String nickname(UserEntity user) {
    if (user == null) {
      return "ONMU 사용자";
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
