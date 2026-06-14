package com.onmu.api.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.onmu.api.domain.ChatActivityEventEntity;
import com.onmu.api.domain.ChatActivityEventRepository;
import com.onmu.api.domain.ChatReadStateEntity;
import com.onmu.api.domain.ChatReadStateRepository;
import com.onmu.api.domain.GroupEntity;
import com.onmu.api.domain.GroupMemberEntity;
import com.onmu.api.domain.GroupMemberRepository;
import com.onmu.api.domain.GroupRepository;
import com.onmu.api.domain.NotificationEntity;
import com.onmu.api.domain.NotificationRepository;
import com.onmu.api.domain.UserEntity;
import com.onmu.api.domain.UserRepository;
import com.onmu.api.web.dto.ChatMessageAttachmentRequest;
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
  private static final int MAX_ATTACHMENT_COUNT = 4;
  private static final TypeReference<Map<String, Object>> MAP_TYPE = new TypeReference<>() {
  };
  private static final DateTimeFormatter TIME_LABEL_FORMATTER = DateTimeFormatter
    .ofPattern("HH:mm")
    .withZone(ZoneId.of("Asia/Seoul"));

  private final ChatActivityEventRepository chatActivityEventRepository;
  private final ChatReadStateRepository chatReadStateRepository;
  private final GroupRepository groupRepository;
  private final GroupMemberRepository groupMemberRepository;
  private final NotificationRepository notificationRepository;
  private final NotificationPreferenceService notificationPreferenceService;
  private final UserRepository userRepository;
  private final ObjectMapper objectMapper;
  private final ChatRealtimePublisher chatRealtimePublisher;
  private final OutboxService outboxService;

  public ChatActivityService(
    ChatActivityEventRepository chatActivityEventRepository,
    ChatReadStateRepository chatReadStateRepository,
    GroupRepository groupRepository,
    GroupMemberRepository groupMemberRepository,
    NotificationRepository notificationRepository,
    NotificationPreferenceService notificationPreferenceService,
    UserRepository userRepository,
    ObjectMapper objectMapper,
    ChatRealtimePublisher chatRealtimePublisher,
    OutboxService outboxService
  ) {
    this.chatActivityEventRepository = chatActivityEventRepository;
    this.chatReadStateRepository = chatReadStateRepository;
    this.groupRepository = groupRepository;
    this.groupMemberRepository = groupMemberRepository;
    this.notificationRepository = notificationRepository;
    this.notificationPreferenceService = notificationPreferenceService;
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
    PageRequest pageable = PageRequest.of(0, pageLimit + 1);
    List<ChatActivityEventEntity> eventsDesc = new ArrayList<>(
      beforeCreatedAt == null
        ? chatActivityEventRepository.findLatestPage(group, pageable)
        : chatActivityEventRepository.findPageBefore(group, beforeCreatedAt, pageable)
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
    String message = textValue(request == null ? null : request.message());
    List<Map<String, Object>> attachments = normalizeAttachments(request == null ? null : request.attachments());
    if (message == null && attachments.isEmpty()) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "blank_chat_message");
    }
    UserEntity actorUser = findUser(currentUserId);

    Map<String, Object> payload = new LinkedHashMap<>();
    payload.put("senderName", displayName(actorUser));
    payload.put("message", message == null ? "" : message);
    payload.put("attachments", attachments);
    payload.put("messageType", "message");
    payload.put("source", "spring_api");

    ChatActivityEventEntity event = chatActivityEventRepository.save(new ChatActivityEventEntity(
      group,
      actorUser,
      "chat.message",
      toJson(payload),
      Instant.now()
    ));
    createMessageNotifications(group, actorUser, event, message, attachments.size());
    Map<String, Object> response = toMessage(event, currentUserId);
    outboxService.record("chat.message", "chat_activity_event", event.getId(), Map.of(
      "groupId", group.getPublicId(),
      "chatActivityEventId", event.getId().toString(),
      "attachmentCount", attachments.size()
    ));
    publishAfterCommit(group.getPublicId(), response);
    return response;
  }

  private void createMessageNotifications(
    GroupEntity group,
    UserEntity actorUser,
    ChatActivityEventEntity event,
    String message,
    int attachmentCount
  ) {
    Map<UUID, UserEntity> recipients = new LinkedHashMap<>();
    for (GroupMemberEntity member : groupMemberRepository.findByGroupOrderByJoinedAtAsc(group)) {
      UserEntity memberUser = member.getUser();
      if (memberUser == null || !isActiveChatRecipient(member) || memberUser.getId().equals(actorUser.getId())) {
        continue;
      }
      recipients.putIfAbsent(memberUser.getId(), memberUser);
    }

    UserEntity ownerUser = group.getOwnerUser();
    if (ownerUser != null && !ownerUser.getId().equals(actorUser.getId())) {
      recipients.putIfAbsent(ownerUser.getId(), ownerUser);
    }

    if (recipients.isEmpty()) {
      return;
    }

    Instant createdAt = Instant.now();
    String senderName = displayName(actorUser);
    String body = messagePreview(message, attachmentCount);
    String payload = toJson(Map.of(
      "groupId", group.getPublicId(),
      "messageId", event.getId().toString(),
      "senderUserId", actorUser.getPublicId(),
      "chatActivityEventId", event.getId().toString()
    ));
    for (UserEntity recipient : recipients.values()) {
      if (!notificationPreferenceService.isEnabled(recipient.getId(), "chat_message", "in_app")) {
        continue;
      }
      NotificationEntity notification = notificationRepository.save(new NotificationEntity(
        recipient,
        group,
        null,
        "chat_message",
        senderName + "님의 새 메시지",
        body,
        payload,
        "queued",
        null,
        createdAt
      ));
      outboxService.record("notification.requested", "notification", notification.getId(), Map.of(
        "groupId", group.getPublicId(),
        "notificationId", notification.getId().toString(),
        "notificationType", notification.getNotificationType(),
        "channels", List.of("push")
      ));
    }
  }

  private boolean isActiveChatRecipient(GroupMemberEntity member) {
    return member.getLeftAt() == null && ("active".equals(member.getStatus()) || "joined".equals(member.getStatus()));
  }

  private String messagePreview(String message, int attachmentCount) {
    if (message == null || message.isBlank()) {
      return attachmentCount > 0 ? "사진을 보냈어요." : "메시지를 확인해 주세요.";
    }
    String normalized = message.replaceAll("\\R+", " ").replaceAll("[\\t ]+", " ").trim();
    if (normalized.length() <= 80) {
      return normalized;
    }
    return normalized.substring(0, 80);
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
    List<Map<String, Object>> attachments = attachmentPayloads(payload.get("attachments"));
    if ((message == null || message.isBlank()) && attachments.isEmpty()) {
      message = fallbackMessage(messageType);
    } else if (message == null) {
      message = "";
    }

    Map<String, Object> response = new LinkedHashMap<>();
    response.put("id", event.getId().toString());
    response.put("senderUserId", actorUser == null ? null : actorUser.getPublicId());
    response.put("senderName", senderName(payload, actorUser, messageType));
    response.put("message", message);
    response.put("attachments", attachments);
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
    if (lastReadAt == null) {
      return chatActivityEventRepository.countUnread(group, currentUserId);
    }
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

  private List<Map<String, Object>> normalizeAttachments(List<ChatMessageAttachmentRequest> attachments) {
    if (attachments == null || attachments.isEmpty()) {
      return List.of();
    }
    if (attachments.size() > MAX_ATTACHMENT_COUNT) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "too_many_chat_attachments");
    }
    return attachments.stream()
      .map(this::normalizeAttachment)
      .toList();
  }

  private Map<String, Object> normalizeAttachment(ChatMessageAttachmentRequest attachment) {
    if (attachment == null) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "invalid_chat_attachment");
    }
    String type = textValue(attachment.type());
    if (!"image".equals(type)) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "unsupported_chat_attachment_type");
    }
    String storageKey = textValue(attachment.storageKey());
    if (!MediaService.isAllowedPublicMediaKey(storageKey)) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "invalid_chat_attachment_storage_key");
    }
    String contentType = textValue(attachment.contentType());
    if (contentType != null && !contentType.toLowerCase().startsWith("image/")) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "invalid_chat_attachment_content_type");
    }

    Map<String, Object> normalized = new LinkedHashMap<>();
    normalized.put("type", type);
    normalized.put("storageKey", storageKey);
    normalized.put("publicUrl", MediaService.publicMediaUrl(storageKey));
    normalized.put("contentType", contentType);
    normalized.put("fileName", textValue(attachment.fileName()));
    normalized.put("width", positiveDimension(attachment.width()));
    normalized.put("height", positiveDimension(attachment.height()));
    return normalized;
  }

  private Integer positiveDimension(Integer value) {
    if (value == null || value <= 0) {
      return null;
    }
    return value;
  }

  private List<Map<String, Object>> attachmentPayloads(Object value) {
    if (!(value instanceof List<?> values)) {
      return List.of();
    }
    return values.stream()
      .map(this::mapValue)
      .filter(map -> "image".equals(textValue(map.get("type"))))
      .map(map -> {
        String storageKey = textValue(map.get("storageKey"));
        String publicUrl = textValue(map.get("publicUrl"));
        Map<String, Object> attachment = new LinkedHashMap<>();
        attachment.put("type", "image");
        attachment.put("storageKey", storageKey);
        attachment.put("publicUrl", publicUrl == null && MediaService.isAllowedPublicMediaKey(storageKey)
          ? MediaService.publicMediaUrl(storageKey)
          : publicUrl);
        attachment.put("contentType", textValue(map.get("contentType")));
        attachment.put("fileName", textValue(map.get("fileName")));
        attachment.put("width", integerValue(map.get("width")));
        attachment.put("height", integerValue(map.get("height")));
        return attachment;
      })
      .toList();
  }

  private Map<String, Object> mapValue(Object value) {
    if (!(value instanceof Map<?, ?> raw)) {
      return Map.of();
    }
    Map<String, Object> mapped = new LinkedHashMap<>();
    raw.forEach((key, item) -> mapped.put(String.valueOf(key), item));
    return mapped;
  }

  private Integer integerValue(Object value) {
    if (value instanceof Number number) {
      return number.intValue();
    }
    try {
      return value == null ? null : Integer.parseInt(value.toString());
    } catch (NumberFormatException exception) {
      return null;
    }
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
