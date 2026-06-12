package com.onmu.api.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.onmu.api.domain.ChatActivityEventEntity;
import com.onmu.api.domain.ChatActivityEventRepository;
import com.onmu.api.domain.ChatReadStateEntity;
import com.onmu.api.domain.ChatReadStateRepository;
import com.onmu.api.domain.GroupEntity;
import com.onmu.api.domain.GroupRepository;
import com.onmu.api.domain.UserEntity;
import com.onmu.api.domain.UserRepository;
import com.onmu.api.web.dto.CreateChatMessageRequest;
import com.onmu.api.web.dto.UpdateChatReadStateRequest;
import java.util.ArrayList;
import java.util.Collections;
import java.time.Instant;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;
import org.springframework.web.server.ResponseStatusException;

@Service
public class ChatActivityService {
  private static final int DEFAULT_MESSAGE_LIMIT = 50;
  private static final int MAX_MESSAGE_LIMIT = 100;
  private static final TypeReference<Map<String, Object>> MAP_TYPE = new TypeReference<>() {
  };
  private static final DateTimeFormatter TIME_LABEL_FORMATTER = DateTimeFormatter
    .ofPattern("HH:mm")
    .withZone(ZoneId.of("Asia/Seoul"));

  private final ChatActivityEventRepository chatActivityEventRepository;
  private final ChatReadStateRepository chatReadStateRepository;
  private final GroupRepository groupRepository;
  private final UserRepository userRepository;
  private final ObjectMapper objectMapper;
  private final ChatRealtimePublisher chatRealtimePublisher;
  private final OutboxService outboxService;

  public ChatActivityService(
    ChatActivityEventRepository chatActivityEventRepository,
    ChatReadStateRepository chatReadStateRepository,
    GroupRepository groupRepository,
    UserRepository userRepository,
    ObjectMapper objectMapper,
    ChatRealtimePublisher chatRealtimePublisher,
    OutboxService outboxService
  ) {
    this.chatActivityEventRepository = chatActivityEventRepository;
    this.chatReadStateRepository = chatReadStateRepository;
    this.groupRepository = groupRepository;
    this.userRepository = userRepository;
    this.objectMapper = objectMapper;
    this.chatRealtimePublisher = chatRealtimePublisher;
    this.outboxService = outboxService;
  }

  @Transactional(readOnly = true)
  public Map<String, Object> messages(String groupId, UUID currentUserId, String beforeCursor, Integer limit) {
    GroupEntity group = findMemberGroup(groupId, currentUserId);
    int pageLimit = boundedLimit(limit);
    Instant beforeCreatedAt = parseCursor(beforeCursor);
    List<ChatActivityEventEntity> eventsDesc = new ArrayList<>(
      chatActivityEventRepository.findPageBefore(
        group,
        beforeCreatedAt,
        PageRequest.of(0, pageLimit + 1)
      )
    );
    boolean hasMore = eventsDesc.size() > pageLimit;
    if (hasMore) {
      eventsDesc = new ArrayList<>(eventsDesc.subList(0, pageLimit));
    }
    Collections.reverse(eventsDesc);

    List<Map<String, Object>> messages = eventsDesc
      .stream()
      .map(event -> toMessage(event, currentUserId))
      .toList();
    String nextCursor = hasMore && !eventsDesc.isEmpty() ? cursorFor(eventsDesc.getFirst()) : null;

    Map<String, Object> response = new LinkedHashMap<>();
    response.put("messages", messages);
    response.put("nextCursor", nextCursor);
    response.put("hasMore", hasMore);
    response.put("limit", pageLimit);
    response.put("unreadCount", unreadCount(group, currentUserId));
    return response;
  }

  @Transactional(readOnly = true)
  public SseEmitter events(String groupId, UUID currentUserId, String afterCursor) {
    GroupEntity group = findMemberGroup(groupId, currentUserId);
    UserEntity currentUser = findUser(currentUserId);
    List<Map<String, Object>> replayMessages = replayMessagesAfter(group, currentUserId, afterCursor);
    return chatRealtimePublisher.subscribe(group.getPublicId(), currentUser.getPublicId(), replayMessages);
  }

  @Transactional
  public Map<String, Object> createMessage(String groupId, UUID currentUserId, CreateChatMessageRequest request) {
    GroupEntity group = findMemberGroup(groupId, currentUserId);
    String message = request == null ? null : request.message();
    if (message == null || message.isBlank()) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "blank_chat_message");
    }
    UserEntity actorUser = findUser(currentUserId);

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
    Map<String, Object> response = toMessage(event, currentUserId);
    outboxService.record("chat.message", "chat_activity_event", event.getId(), Map.of(
      "groupId", group.getPublicId(),
      "chatActivityEventId", event.getId().toString()
    ));
    publishAfterCommit(group.getPublicId(), response);
    return response;
  }

  @Transactional
  public Map<String, Object> markRead(String groupId, UUID currentUserId, UpdateChatReadStateRequest request) {
    GroupEntity group = findMemberGroup(groupId, currentUserId);
    UserEntity user = userRepository.findByIdAndDeletedAtIsNull(currentUserId)
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "user_not_found"));
    ChatActivityEventEntity lastReadEvent = lastReadEvent(group, request);
    Instant now = Instant.now();
    ChatReadStateEntity readState = chatReadStateRepository.findByGroupAndUser(group, user)
      .orElseGet(() -> new ChatReadStateEntity(group, user, lastReadEvent, now));
    readState.markRead(lastReadEvent, now);
    ChatReadStateEntity saved = chatReadStateRepository.save(readState);

    Map<String, Object> response = new LinkedHashMap<>();
    response.put("lastReadMessageId", saved.getLastReadEvent() == null ? null : saved.getLastReadEvent().getId().toString());
    response.put("lastReadAt", saved.getLastReadAt().toString());
    response.put("unreadCount", unreadCount(group, currentUserId));
    return response;
  }

  private GroupEntity findMemberGroup(String groupId, UUID currentUserId) {
    GroupEntity group = groupRepository.findByPublicId(groupId)
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "group_not_found"));
    if (!groupRepository.isUserMember(group.getPublicId(), currentUserId)) {
      throw new ResponseStatusException(HttpStatus.FORBIDDEN, "group_member_required");
    }
    return group;
  }

  private UserEntity findUser(UUID currentUserId) {
    return userRepository.findByIdAndDeletedAtIsNull(currentUserId)
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "user_not_found"));
  }

  private List<Map<String, Object>> replayMessagesAfter(GroupEntity group, UUID currentUserId, String afterCursor) {
    String cursor = textValue(afterCursor);
    if (cursor == null) {
      return List.of();
    }
    Instant afterCreatedAt = parseCursor(cursor);
    return chatActivityEventRepository.findPageAfter(
        group,
        afterCreatedAt,
        PageRequest.of(0, MAX_MESSAGE_LIMIT)
      )
      .stream()
      .map(event -> toMessage(event, currentUserId))
      .toList();
  }

  private void publishAfterCommit(String groupId, Map<String, Object> message) {
    if (!TransactionSynchronizationManager.isSynchronizationActive()) {
      chatRealtimePublisher.publishMessage(groupId, message);
      return;
    }
    TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
      @Override
      public void afterCommit() {
        chatRealtimePublisher.publishMessage(groupId, message);
      }
    });
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
    response.put("cursor", cursorFor(event));
    response.put("timeLabel", TIME_LABEL_FORMATTER.format(event.getCreatedAt()));
    response.put("isMine", actorUser != null && actorUser.getId().equals(currentUserId));
    response.put("sendStatus", "sent");
    return response;
  }

  private long unreadCount(GroupEntity group, UUID currentUserId) {
    Instant lastReadAt = chatReadStateRepository.findByGroupAndUser(
        group,
        userRepository.findByIdAndDeletedAtIsNull(currentUserId)
          .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "user_not_found"))
      )
      .map(ChatReadStateEntity::getLastReadAt)
      .orElse(null);
    return chatActivityEventRepository.countUnreadAfter(group, currentUserId, lastReadAt);
  }

  private ChatActivityEventEntity lastReadEvent(GroupEntity group, UpdateChatReadStateRequest request) {
    String messageId = request == null ? null : textValue(request.lastReadMessageId());
    if (messageId == null) {
      return chatActivityEventRepository.findFirstByGroupOrderByCreatedAtDesc(group).orElse(null);
    }
    UUID eventId;
    try {
      eventId = UUID.fromString(messageId);
    } catch (IllegalArgumentException exception) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "invalid_chat_message_id");
    }
    return chatActivityEventRepository.findByIdAndGroup(eventId, group)
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "chat_message_not_found"));
  }

  private int boundedLimit(Integer limit) {
    if (limit == null) {
      return DEFAULT_MESSAGE_LIMIT;
    }
    return Math.max(1, Math.min(limit, MAX_MESSAGE_LIMIT));
  }

  private Instant parseCursor(String beforeCursor) {
    String cursor = textValue(beforeCursor);
    if (cursor == null) {
      return null;
    }
    try {
      return Instant.parse(cursor);
    } catch (RuntimeException exception) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "invalid_chat_cursor");
    }
  }

  private String cursorFor(ChatActivityEventEntity event) {
    return event.getCreatedAt().toString();
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
