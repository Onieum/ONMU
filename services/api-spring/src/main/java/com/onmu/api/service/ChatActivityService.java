package com.onmu.api.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.onmu.api.domain.ChatActivityEventEntity;
import com.onmu.api.domain.ChatActivityEventRepository;
import com.onmu.api.domain.GroupEntity;
import com.onmu.api.domain.GroupRepository;
import com.onmu.api.domain.UserEntity;
import com.onmu.api.domain.UserRepository;
import com.onmu.api.web.dto.CreateChatMessageRequest;
import java.time.Instant;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
public class ChatActivityService {
  private static final TypeReference<Map<String, Object>> MAP_TYPE = new TypeReference<>() {
  };
  private static final DateTimeFormatter TIME_LABEL_FORMATTER = DateTimeFormatter
    .ofPattern("HH:mm")
    .withZone(ZoneId.of("Asia/Seoul"));

  private final ChatActivityEventRepository chatActivityEventRepository;
  private final GroupRepository groupRepository;
  private final UserRepository userRepository;
  private final ObjectMapper objectMapper;

  public ChatActivityService(
    ChatActivityEventRepository chatActivityEventRepository,
    GroupRepository groupRepository,
    UserRepository userRepository,
    ObjectMapper objectMapper
  ) {
    this.chatActivityEventRepository = chatActivityEventRepository;
    this.groupRepository = groupRepository;
    this.userRepository = userRepository;
    this.objectMapper = objectMapper;
  }

  @Transactional(readOnly = true)
  public Map<String, Object> messages(String groupId, UUID currentUserId) {
    GroupEntity group = findMemberGroup(groupId, currentUserId);
    List<Map<String, Object>> messages = chatActivityEventRepository.findByGroupOrderByCreatedAtAsc(group)
      .stream()
      .map(event -> toMessage(event, currentUserId))
      .toList();
    return Map.of("messages", messages);
  }

  @Transactional
  public Map<String, Object> createMessage(String groupId, UUID currentUserId, CreateChatMessageRequest request) {
    GroupEntity group = findMemberGroup(groupId, currentUserId);
    String message = request == null ? null : request.message();
    if (message == null || message.isBlank()) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "blank_chat_message");
    }
    UserEntity actorUser = userRepository.findByIdAndDeletedAtIsNull(currentUserId)
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "user_not_found"));

    Map<String, Object> payload = new LinkedHashMap<>();
    payload.put("senderName", displayName(actorUser));
    payload.put("message", message.trim());
    payload.put("messageType", "message");
    payload.put("source", "spring_api");

    ChatActivityEventEntity event = chatActivityEventRepository.save(new ChatActivityEventEntity(
      group,
      actorUser,
      "chat.message",
      toJson(payload),
      Instant.now()
    ));
    return toMessage(event, currentUserId);
  }

  private GroupEntity findMemberGroup(String groupId, UUID currentUserId) {
    GroupEntity group = groupRepository.findByPublicId(groupId)
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "group_not_found"));
    if (!groupRepository.isUserMember(group.getPublicId(), currentUserId)) {
      throw new ResponseStatusException(HttpStatus.FORBIDDEN, "group_member_required");
    }
    return group;
  }

  private Map<String, Object> toMessage(ChatActivityEventEntity event, UUID currentUserId) {
    Map<String, Object> payload = readPayload(event.getPayload());
    UserEntity actorUser = event.getActorUser();
    String messageType = messageType(event, payload);
    String message = firstText(payload, "message", "content");
    if (message == null || message.isBlank()) {
      message = fallbackMessage(messageType);
    }

    Map<String, Object> response = new LinkedHashMap<>();
    response.put("id", event.getId().toString());
    response.put("senderUserId", actorUser == null ? null : actorUser.getPublicId());
    response.put("senderName", senderName(payload, actorUser, messageType));
    response.put("message", message);
    response.put("messageType", messageType);
    response.put("cardType", textValue(payload.get("cardType")));
    response.put("createdAt", event.getCreatedAt().toString());
    response.put("timeLabel", TIME_LABEL_FORMATTER.format(event.getCreatedAt()));
    response.put("isMine", actorUser != null && actorUser.getId().equals(currentUserId));
    return response;
  }

  private String messageType(ChatActivityEventEntity event, Map<String, Object> payload) {
    String payloadType = textValue(payload.get("messageType"));
    if (payloadType != null && !payloadType.isBlank()) {
      return payloadType;
    }
    String cardType = textValue(payload.get("cardType"));
    if (cardType != null && !cardType.isBlank()) {
      return switch (cardType) {
        case "plan", "plan_card" -> "plan_card";
        case "vote", "vote_card" -> "vote_card";
        case "settlement", "settlement_card" -> "settlement_card";
        default -> "system";
      };
    }
    if ("chat.message".equals(event.getEventType())) {
      return "message";
    }
    return "system";
  }

  private String senderName(Map<String, Object> payload, UserEntity actorUser, String messageType) {
    String senderName = textValue(payload.get("senderName"));
    if (senderName != null && !senderName.isBlank()) {
      return senderName;
    }
    if (actorUser != null) {
      return displayName(actorUser);
    }
    return "message".equals(messageType) ? "알 수 없음" : "ONMU";
  }

  private String displayName(UserEntity user) {
    if (user.getDisplayName() != null && !user.getDisplayName().isBlank()) {
      return user.getDisplayName();
    }
    if (user.getNickname() != null && !user.getNickname().isBlank()) {
      return user.getNickname();
    }
    return "ONMU 사용자";
  }

  private String fallbackMessage(String messageType) {
    if (!"message".equals(messageType)) {
      return "새 활동이 있어요.";
    }
    return "메시지를 확인해 주세요.";
  }

  private String firstText(Map<String, Object> payload, String firstKey, String secondKey) {
    String first = textValue(payload.get(firstKey));
    if (first != null && !first.isBlank()) {
      return first;
    }
    return textValue(payload.get(secondKey));
  }

  private String textValue(Object value) {
    if (value == null) {
      return null;
    }
    String text = String.valueOf(value).trim();
    return text.isBlank() ? null : text;
  }

  private Map<String, Object> readPayload(String json) {
    if (json == null || json.isBlank()) {
      return Map.of();
    }
    try {
      return objectMapper.readValue(json, MAP_TYPE);
    } catch (JsonProcessingException exception) {
      return Map.of();
    }
  }

  private String toJson(Map<String, Object> payload) {
    try {
      return objectMapper.writeValueAsString(payload);
    } catch (JsonProcessingException exception) {
      throw new IllegalStateException("Could not serialize chat payload", exception);
    }
  }
}
