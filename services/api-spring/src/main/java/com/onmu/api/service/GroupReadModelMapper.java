package com.onmu.api.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.onmu.api.domain.CharacterProfileEntity;
import com.onmu.api.domain.CharacterProfileRepository;
import com.onmu.api.domain.GroupEntity;
import com.onmu.api.domain.GroupMemberEntity;
import com.onmu.api.domain.GroupMemberRepository;
import com.onmu.api.domain.UserEntity;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.springframework.stereotype.Component;

@Component
public class GroupReadModelMapper {
  private static final String DEFAULT_GROUP_DESCRIPTION = "ONMU 모임";

  private final GroupMemberRepository groupMemberRepository;
  private final CharacterProfileRepository characterProfileRepository;
  private final ObjectMapper objectMapper;

  public GroupReadModelMapper(
    GroupMemberRepository groupMemberRepository,
    CharacterProfileRepository characterProfileRepository,
    ObjectMapper objectMapper
  ) {
    this.groupMemberRepository = groupMemberRepository;
    this.characterProfileRepository = characterProfileRepository;
    this.objectMapper = objectMapper;
  }

  public Map<String, Object> groupCard(GroupEntity group) {
    List<Map<String, Object>> memberProfiles = membersFor(group, true);
    List<String> memberNames = memberProfiles.stream()
      .map(member -> String.valueOf(member.get("name")))
      .toList();
    return groupCard(group, memberProfiles.size(), memberNames, memberProfiles);
  }

  public Map<String, Object> groupCard(
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

  public List<Map<String, Object>> membersFor(GroupEntity group, boolean fallbackToOwner) {
    List<GroupMemberEntity> memberships = groupMemberRepository.findByGroupOrderByJoinedAtAsc(group);
    if (memberships == null) {
      memberships = List.of();
    }
    List<GroupMemberEntity> visibleMemberships = memberships.stream()
      .filter(membership -> !"left".equals(membership.getStatus()))
      .sorted(Comparator.comparingInt(this::memberStatusOrder))
      .toList();
    if (!visibleMemberships.isEmpty()) {
      return visibleMemberships.stream().map(this::memberProfile).toList();
    }
    if (!memberships.isEmpty() || !fallbackToOwner) {
      return List.of();
    }

    UserEntity fallbackUser = group.getOwnerUser();
    if (fallbackUser == null) {
      return List.of();
    }
    return List.of(userProfile(fallbackUser, "owner", "active"));
  }

  public Map<String, Object> memberProfile(GroupMemberEntity member) {
    return userProfile(member.getUser(), member.getRole(), member.getStatus(), memberName(member));
  }

  public Map<String, Object> userProfile(UserEntity user, String role, String status) {
    return userProfile(user, role, status, nickname(user));
  }

  public String safeDescription(GroupEntity group) {
    if (group.getDescription() == null || group.getDescription().isBlank()) {
      return DEFAULT_GROUP_DESCRIPTION;
    }
    return group.getDescription();
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
    value.put("pixelCharacter", pixelCharacter(user));
    return value;
  }

  private Map<String, Object> pixelCharacter(UserEntity user) {
    if (user == null || user.getId() == null) {
      return Map.of();
    }
    return characterProfileRepository.findByUserId(user.getId())
      .map(this::characterProfile)
      .orElseGet(() -> readJsonObject(user.getPixelCharacter()));
  }

  private Map<String, Object> characterProfile(CharacterProfileEntity character) {
    Map<String, Object> value = new LinkedHashMap<>();
    value.put("gender", character.getGender());
    value.put("skinTone", character.getSkinTone());
    value.put("hairStyle", character.getHairStyle());
    value.put("hairColor", character.getHairColor());
    value.put("eyeStyle", character.getEyeStyle());
    value.put("eyeColor", character.getEyeColor());
    value.put("clothes", character.getClothes());
    return value;
  }

  private Map<String, Object> readJsonObject(String payload) {
    if (payload == null || payload.isBlank()) {
      return Map.of();
    }
    try {
      Map<?, ?> parsed = objectMapper.readValue(payload, Map.class);
      Map<String, Object> values = new LinkedHashMap<>();
      parsed.forEach((key, value) -> values.put(String.valueOf(key), value));
      return values;
    } catch (JsonProcessingException exception) {
      return Map.of();
    }
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
}
