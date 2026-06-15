package com.onmu.api.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.onmu.api.domain.GroupEntity;
import com.onmu.api.domain.NotificationEntity;
import com.onmu.api.domain.NotificationRepository;
import com.onmu.api.domain.PlanEntity;
import com.onmu.api.web.dto.NotificationItemResponse;
import com.onmu.api.web.dto.NotificationReadAllResponse;
import com.onmu.api.web.dto.NotificationUnreadCountResponse;
import java.time.Instant;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
public class NotificationService {
  private static final int DEFAULT_LIMIT = 50;
  private static final int MAX_LIMIT = 100;
  private static final TypeReference<Map<String, Object>> MAP_TYPE = new TypeReference<>() {
  };
  private static final DateTimeFormatter TIME_LABEL_FORMATTER = DateTimeFormatter
    .ofPattern("HH:mm")
    .withZone(ZoneOffset.UTC);

  private final NotificationRepository notificationRepository;
  private final ObjectMapper objectMapper;

  public NotificationService(
    NotificationRepository notificationRepository,
    ObjectMapper objectMapper
  ) {
    this.notificationRepository = notificationRepository;
    this.objectMapper = objectMapper;
  }

  @Transactional(readOnly = true)
  public List<NotificationItemResponse> inbox(UUID currentUserId, Integer limit) {
    return notificationRepository.findInboxByUserId(
        currentUserId,
        PageRequest.of(0, boundedLimit(limit))
      )
      .stream()
      .map(this::toResponse)
      .toList();
  }

  @Transactional(readOnly = true)
  public NotificationUnreadCountResponse unreadCount(UUID currentUserId) {
    return new NotificationUnreadCountResponse(
      notificationRepository.countByUser_IdAndReadAtIsNull(currentUserId)
    );
  }

  @Transactional
  public NotificationItemResponse markRead(UUID currentUserId, UUID notificationId) {
    NotificationEntity notification = notificationRepository
      .findInboxItemByIdAndUserId(notificationId, currentUserId)
      .orElseThrow(() ->
        new ResponseStatusException(HttpStatus.NOT_FOUND, "notification_not_found")
      );
    notification.markRead(
      notification.getReadAt() == null ? Instant.now() : notification.getReadAt()
    );
    return toResponse(notification);
  }

  @Transactional
  public NotificationReadAllResponse markAllRead(UUID currentUserId) {
    int updatedCount = notificationRepository.markUnreadAsReadByUserId(
      currentUserId,
      Instant.now()
    );
    return new NotificationReadAllResponse(updatedCount);
  }

  private NotificationItemResponse toResponse(NotificationEntity notification) {
    Map<String, Object> payload = readPayload(notification.getPayload());
    String groupId = publicGroupId(notification.getGroup(), payload);
    String planId = publicPlanId(notification.getPlan(), payload);
    return new NotificationItemResponse(
      notification.getId().toString(),
      notification.getNotificationType(),
      notification.getNotificationType(),
      notification.getTitle(),
      notification.getBody(),
      notification.getStatus(),
      notification.getReadAt() == null ? null : notification.getReadAt().toString(),
      notification.getCreatedAt().toString(),
      TIME_LABEL_FORMATTER.format(notification.getCreatedAt()),
      groupId,
      planId,
      payload,
      notification.getReadAt() != null
    );
  }

  private Map<String, Object> readPayload(String payload) {
    if (payload == null || payload.isBlank()) {
      return Map.of();
    }
    try {
      return objectMapper.readValue(payload, MAP_TYPE);
    } catch (JsonProcessingException exception) {
      return Map.of();
    }
  }

  private String publicGroupId(GroupEntity group, Map<String, Object> payload) {
    if (group != null && group.getPublicId() != null && !group.getPublicId().isBlank()) {
      return group.getPublicId();
    }
    return textValue(payload.get("groupId"));
  }

  private String publicPlanId(PlanEntity plan, Map<String, Object> payload) {
    if (plan != null && plan.getPublicId() != null && !plan.getPublicId().isBlank()) {
      return plan.getPublicId();
    }
    return textValue(payload.get("planId"));
  }

  private String textValue(Object value) {
    if (value == null) {
      return null;
    }
    String text = value.toString().trim();
    return text.isEmpty() ? null : text;
  }

  private int boundedLimit(Integer limit) {
    if (limit == null) {
      return DEFAULT_LIMIT;
    }
    return Math.max(1, Math.min(limit, MAX_LIMIT));
  }
}
