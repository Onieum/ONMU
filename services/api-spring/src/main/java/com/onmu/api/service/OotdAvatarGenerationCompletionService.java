package com.onmu.api.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.onmu.api.domain.OotdAvatarGenerationJobEntity;
import com.onmu.api.domain.OotdAvatarGenerationJobRepository;
import com.onmu.api.web.dto.UploadMediaResponse;
import java.util.Base64;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

@Service
public class OotdAvatarGenerationCompletionService {
  private static final TypeReference<Map<String, Object>> MAP_TYPE = new TypeReference<>() {
  };

  private final OotdAvatarGenerationJobRepository jobRepository;
  private final MediaService mediaService;
  private final ObjectMapper objectMapper;

  public OotdAvatarGenerationCompletionService(
    OotdAvatarGenerationJobRepository jobRepository,
    MediaService mediaService,
    ObjectMapper objectMapper
  ) {
    this.jobRepository = jobRepository;
    this.mediaService = mediaService;
    this.objectMapper = objectMapper;
  }

  @Transactional
  public void completeFromWorkerResponse(UUID jobId, String responseBody) {
    if (jobId == null || !StringUtils.hasText(responseBody)) {
      return;
    }
    Map<String, Object> body = readMap(responseBody);
    if (body.isEmpty()) {
      return;
    }

    OotdAvatarGenerationJobEntity job = jobRepository.findById(jobId)
      .orElseThrow(() -> new IllegalStateException("ootd_avatar_generation_job_not_found"));
    String status = text(body.get("status")).toLowerCase(Locale.ROOT);
    if ("failed".equals(status)) {
      job.markFailed(firstText(body, "errorCode", "message", "error"), isRetryable(body));
      updateRecordPayload(job, "", "", "", "", "FAILED");
      jobRepository.save(job);
      return;
    }
    if (!"completed".equals(status) && !"succeeded".equals(status)) {
      return;
    }

    String publicUrl = firstText(body, "generatedImageUrl", "imageUrl", "publicUrl");
    String storageKey = firstText(body, "generatedImageStorageKey", "storageKey");
    String imageBase64 = firstText(body, "imageBase64", "generatedImageBase64");
    if (StringUtils.hasText(imageBase64)) {
      UploadMediaResponse uploaded = mediaService.uploadGeneratedImage(
        decodeImageBase64(imageBase64),
        firstText(body, "mimeType", "contentType")
      );
      storageKey = uploaded.storageKey();
      publicUrl = uploaded.publicUrl();
    }

    String avatarImageUrl = "";
    String avatarImageStorageKey = "";
    String avatarBase64 = firstText(body, "avatarBase64", "generatedAvatarBase64");
    if (StringUtils.hasText(avatarBase64)) {
      try {
        UploadMediaResponse uploadedAvatar = mediaService.uploadGeneratedImage(
          decodeImageBase64(avatarBase64),
          "image/png"
        );
        avatarImageStorageKey = uploadedAvatar.storageKey();
        avatarImageUrl = uploadedAvatar.publicUrl();
      } catch (Exception e) {
        System.err.println("Failed to upload avatar-only image: " + e.getMessage());
      }
    }

    if (!StringUtils.hasText(publicUrl)) {
      job.markFailed("GENERATION_RESULT_MISSING", true);
      updateRecordPayload(job, "", "", "", "", "FAILED");
      jobRepository.save(job);
      return;
    }
    job.markCompleted(storageKey, publicUrl);
    updateRecordPayload(job, storageKey, publicUrl, avatarImageStorageKey, avatarImageUrl, "SUCCESS");
    jobRepository.save(job);
  }

  private void updateRecordPayload(
    OotdAvatarGenerationJobEntity job,
    String storageKey,
    String publicUrl,
    String avatarStorageKey,
    String avatarPublicUrl,
    String aiStatus
  ) {
    Map<String, Object> payload = readMap(job.getRecord().getPayload());
    payload.put("aiStatus", aiStatus);
    if (StringUtils.hasText(publicUrl)) {
      payload.put("generatedImageUrl", publicUrl);
    }
    if (StringUtils.hasText(storageKey)) {
      payload.put("generatedImageStorageKey", storageKey);
    }
    if (StringUtils.hasText(avatarPublicUrl)) {
      payload.put("avatarImageUrl", avatarPublicUrl);
    }
    if (StringUtils.hasText(avatarStorageKey)) {
      payload.put("avatarImageStorageKey", avatarStorageKey);
    }
    try {
      job.getRecord().setPayload(objectMapper.writeValueAsString(payload));
    } catch (JsonProcessingException exception) {
      throw new IllegalStateException("failed_to_update_ootd_record_payload", exception);
    }
  }

  private Map<String, Object> readMap(String responseBody) {
    try {
      return objectMapper.readValue(responseBody, MAP_TYPE);
    } catch (Exception exception) {
      throw new IllegalStateException("invalid_ootd_worker_response", exception);
    }
  }

  private byte[] decodeImageBase64(String imageBase64) {
    String value = imageBase64.trim();
    int commaIndex = value.indexOf(',');
    if (value.startsWith("data:") && commaIndex >= 0) {
      value = value.substring(commaIndex + 1);
    }
    return Base64.getDecoder().decode(value);
  }

  private boolean isRetryable(Map<String, Object> body) {
    Object value = body.get("retryable");
    if (value instanceof Boolean retryable) {
      return retryable;
    }
    return Boolean.parseBoolean(text(value));
  }

  private String firstText(Map<String, Object> body, String... keys) {
    for (String key : keys) {
      String value = text(body.get(key));
      if (StringUtils.hasText(value)) {
        return value;
      }
    }
    return "";
  }

  private String text(Object value) {
    return value == null ? "" : value.toString().trim();
  }
}
