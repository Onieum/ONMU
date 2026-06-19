package com.onmu.api.web.dto;

import jakarta.validation.constraints.NotBlank;
import java.util.List;
import java.util.Map;

public record CreateMemoryRequest(
  @NotBlank String type, // DAILY, OOTD, GROUP_MEETUP
  String title,
  String memo,
  @NotBlank String date, // yyyy-MM-dd
  List<String> tags,
  List<String> imageUrls,
  List<RecordMediaInput> media,
  @NotBlank String visibility, // PRIVATE, GROUP_ONLY, PARTICIPANT_ONLY, PUBLIC
  
  // Custom character overrides for OOTD
  String hairStyle,
  String hairColor,
  String eyeColor,
  Map<String, Object> payload
) {}
