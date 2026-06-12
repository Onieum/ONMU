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
  UUID groupId,
  List<String> tags,
  List<String> imageUrls,
  String visibility,
  Map<String, Object> characterSnapshot,
  String aiStatus,
  Instant createdAt
) {}
