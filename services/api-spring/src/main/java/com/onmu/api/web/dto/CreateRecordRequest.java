package com.onmu.api.web.dto;

import jakarta.validation.constraints.NotBlank;
import java.util.List;

public record CreateRecordRequest(
  @NotBlank String title,
  String summary,
  String visibility,
  String recordType,
  String body,
  String recordedAt,
  List<String> moodTags,
  List<RecordMediaInput> media
) {
}
