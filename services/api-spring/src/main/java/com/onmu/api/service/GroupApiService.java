package com.onmu.api.service;

import com.onmu.api.domain.GroupEntity;
import com.onmu.api.domain.GroupMemberEntity;
import com.onmu.api.domain.GroupMemberRepository;
import com.onmu.api.domain.GroupRepository;
import com.onmu.api.domain.UserEntity;
import com.onmu.api.domain.UserRepository;
import com.onmu.api.web.dto.AddGroupMemberRequest;
import com.onmu.api.web.dto.UpdateGroupRequest;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
public class GroupApiService {
  private final UserRepository userRepository;
  private final GroupRepository groupRepository;
  private final GroupMemberRepository groupMemberRepository;
  private final GroupReadModelMapper groupReadModelMapper;
  private final OutboxService outboxService;

  public GroupApiService(
    UserRepository userRepository,
    GroupRepository groupRepository,
    GroupMemberRepository groupMemberRepository,
    GroupReadModelMapper groupReadModelMapper,
    OutboxService outboxService
  ) {
    this.userRepository = userRepository;
    this.groupRepository = groupRepository;
    this.groupMemberRepository = groupMemberRepository;
    this.groupReadModelMapper = groupReadModelMapper;
    this.outboxService = outboxService;
  }

  @Transactional(readOnly = true)
  public List<Map<String, Object>> groups(UUID userId) {
    UserEntity user = user(userId);
    return groupRepository.findVisibleForUserOrderByCreatedAtAsc(user.getId()).stream()
      .map(groupReadModelMapper::groupCard)
      .toList();
  }

  @Transactional(readOnly = true)
  public Map<String, Object> groupDetail(String groupId, UUID userId) {
    UserEntity user = user(userId);
    GroupEntity group = memberGroup(groupId, user);
    return groupReadModelMapper.groupCard(group);
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
        "description", groupReadModelMapper.safeDescription(group)
      )
    );

    return groupReadModelMapper.groupCard(group);
  }

  @Transactional(readOnly = true)
  public List<Map<String, Object>> members(String groupId, UUID userId) {
    UserEntity user = user(userId);
    return groupReadModelMapper.membersFor(memberGroup(groupId, user), true);
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
    return groupReadModelMapper.memberProfile(membership);
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
        "description", groupReadModelMapper.safeDescription(group),
        "ownerUserId", user.getId() == null ? "" : user.getId().toString()
      )
    );

    return groupReadModelMapper.groupCard(
      group,
      1,
      List.of(nickname(user)),
      List.of(groupReadModelMapper.userProfile(user, "owner", "active"))
    );
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

  private String nickname(UserEntity user) {
    if (user == null) {
      return "ONMU 사용자";
    }
    if (user.getNickname() != null && !user.getNickname().isBlank()) {
      return user.getNickname();
    }
    return "ONMU 사용자";
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
