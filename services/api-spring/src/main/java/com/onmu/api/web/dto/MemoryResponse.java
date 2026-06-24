package com.onmu.api.web.dto;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;

public record MemoryResponse(
  UUID id,
  String publicId,
  String type,
  String title,
  String memo,
  String date,
  UUID authorId,
  String authorName,
  String authorProfileImageUrl,
  UUID groupId,
  List<String> tags,
  List<String> imageUrls,
  List<Map<String, Object>> media,
  String visibility,
  Map<String, Object> characterSnapshot,
  Map<String, Object> payload,
  String aiStatus,
  Instant createdAt
) {}
