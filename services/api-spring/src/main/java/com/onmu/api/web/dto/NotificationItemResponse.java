package com.onmu.api.web.dto;

import java.util.Map;

public record NotificationItemResponse(
  String id,
  String type,
  String notificationType,
  String title,
  String body,
  String status,
  String readAt,
  String createdAt,
  String timeLabel,
  String groupId,
  String planId,
  Map<String, Object> payload,
  boolean isRead
) {
}
