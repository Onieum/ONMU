package com.onmu.api.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.onmu.api.domain.NotificationPreferenceEntity;
import com.onmu.api.domain.NotificationPreferenceRepository;
import com.onmu.api.domain.UserEntity;
import com.onmu.api.domain.UserRepository;
import com.onmu.api.web.dto.NotificationPreferenceItemResponse;
import com.onmu.api.web.dto.NotificationPreferenceUpdateRequest;
import com.onmu.api.web.dto.NotificationPreferencesResponse;
import com.onmu.api.web.dto.UpdateNotificationPreferencesRequest;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
public class NotificationPreferenceService {
  public static final List<String> DEFAULT_NOTIFICATION_TYPES = List.of(
    "chat_message",
    "plan_reminder",
    "vote_created",
    "settlement_requested",
    "record_created"
  );
  public static final List<String> DEFAULT_CHANNELS = List.of("in_app", "push");

  private static final Set<String> ALLOWED_TYPES = Set.copyOf(DEFAULT_NOTIFICATION_TYPES);
  private static final Set<String> ALLOWED_CHANNELS = Set.copyOf(DEFAULT_CHANNELS);
  private static final TypeReference<Map<String, Object>> MAP_TYPE = new TypeReference<>() {
  };

  private final NotificationPreferenceRepository notificationPreferenceRepository;
  private final UserRepository userRepository;
  private final ObjectMapper objectMapper;

  public NotificationPreferenceService(
    NotificationPreferenceRepository notificationPreferenceRepository,
    UserRepository userRepository,
    ObjectMapper objectMapper
  ) {
    this.notificationPreferenceRepository = notificationPreferenceRepository;
    this.userRepository = userRepository;
    this.objectMapper = objectMapper;
  }

  @Transactional(readOnly = true)
  public NotificationPreferencesResponse preferences(UUID currentUserId) {
    Map<String, NotificationPreferenceEntity> stored = new LinkedHashMap<>();
    for (NotificationPreferenceEntity preference : notificationPreferenceRepository.findByUser_Id(currentUserId)) {
      stored.put(key(preference.getNotificationType(), preference.getChannel()), preference);
    }

    return new NotificationPreferencesResponse(DEFAULT_NOTIFICATION_TYPES.stream()
      .flatMap(notificationType -> DEFAULT_CHANNELS.stream()
        .map(channel -> responseFor(stored.get(key(notificationType, channel)), notificationType, channel)))
      .toList());
  }

  @Transactional
  public NotificationPreferencesResponse update(UUID currentUserId, UpdateNotificationPreferencesRequest request) {
    UserEntity user = userRepository.findById(currentUserId)
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "user_not_found"));
    List<NotificationPreferenceUpdateRequest> items = request == null || request.preferences() == null
      ? List.of()
      : request.preferences();

    for (NotificationPreferenceUpdateRequest item : items) {
      String notificationType = requireAllowed(item.notificationType(), ALLOWED_TYPES, "unsupported_notification_type");
      String channel = requireAllowed(item.channel(), ALLOWED_CHANNELS, "unsupported_notification_channel");
      boolean enabled = item.enabled() == null || item.enabled();
      String quietHours = toJson(item.quietHours() == null ? Map.of() : item.quietHours());
      NotificationPreferenceEntity preference = notificationPreferenceRepository
        .findByUser_IdAndNotificationTypeAndChannel(currentUserId, notificationType, channel)
        .orElseGet(() -> new NotificationPreferenceEntity(user, notificationType, channel, enabled, quietHours));
      preference.update(enabled, quietHours);
      notificationPreferenceRepository.save(preference);
    }

    return preferences(currentUserId);
  }

  @Transactional(readOnly = true)
  public boolean isEnabled(UUID userId, String notificationType, String channel) {
    String normalizedType = normalize(notificationType);
    String normalizedChannel = normalize(channel);
    if (!ALLOWED_TYPES.contains(normalizedType) || !ALLOWED_CHANNELS.contains(normalizedChannel)) {
      return true;
    }
    return notificationPreferenceRepository
      .findByUser_IdAndNotificationTypeAndChannel(userId, normalizedType, normalizedChannel)
      .map(NotificationPreferenceEntity::isEnabled)
      .orElse(true);
  }

  private NotificationPreferenceItemResponse responseFor(
    NotificationPreferenceEntity preference,
    String notificationType,
    String channel
  ) {
    return new NotificationPreferenceItemResponse(
      notificationType,
      channel,
      preference == null || preference.isEnabled(),
      preference == null ? Map.of() : readMap(preference.getQuietHours())
    );
  }

  private String requireAllowed(String value, Set<String> allowed, String error) {
    String normalized = normalize(value);
    if (!allowed.contains(normalized)) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, error);
    }
    return normalized;
  }

  private String normalize(String value) {
    return value == null ? "" : value.trim();
  }

  private String key(String notificationType, String channel) {
    return notificationType + ":" + channel;
  }

  private String toJson(Map<String, Object> payload) {
    try {
      return objectMapper.writeValueAsString(payload);
    } catch (JsonProcessingException exception) {
      throw new IllegalStateException("Could not serialize notification preference", exception);
    }
  }

  private Map<String, Object> readMap(String json) {
    if (json == null || json.isBlank()) {
      return Map.of();
    }
    try {
      return objectMapper.readValue(json, MAP_TYPE);
    } catch (JsonProcessingException exception) {
      return Map.of();
    }
  }
}
