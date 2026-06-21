package com.onmu.api.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.onmu.api.domain.CharacterProfileEntity;
import com.onmu.api.domain.CharacterProfileRepository;
import com.onmu.api.domain.OotdAvatarGenerationJobEntity;
import com.onmu.api.domain.OotdAvatarGenerationJobRepository;
import com.onmu.api.domain.RecordEntity;
import com.onmu.api.domain.RecordMediaEntity;
import com.onmu.api.domain.RecordMediaRepository;
import com.onmu.api.domain.RecordRepository;
import com.onmu.api.domain.UserEntity;
import com.onmu.api.domain.UserRepository;
import com.onmu.api.security.AuthenticatedUser;
import com.onmu.api.web.dto.OotdAvatarGenerationRequest;
import com.onmu.api.web.dto.OotdAvatarGenerationResponse;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
public class OotdAvatarGenerationService {
  private static final Logger log = LoggerFactory.getLogger(OotdAvatarGenerationService.class);

  private static final String PHOTO_REFERENCE = "PHOTO_REFERENCE";
  private static final String TEXT_PROMPT = "TEXT_PROMPT";

  private final OotdAvatarGenerationJobRepository jobRepository;
  private final RecordRepository recordRepository;
  private final RecordMediaRepository recordMediaRepository;
  private final UserRepository userRepository;
  private final CharacterProfileRepository characterProfileRepository;
  private final OutboxService outboxService;
  private final ObjectMapper objectMapper;

  public OotdAvatarGenerationService(
    OotdAvatarGenerationJobRepository jobRepository,
    RecordRepository recordRepository,
    RecordMediaRepository recordMediaRepository,
    UserRepository userRepository,
    CharacterProfileRepository characterProfileRepository,
    OutboxService outboxService,
    ObjectMapper objectMapper
  ) {
    this.jobRepository = jobRepository;
    this.recordRepository = recordRepository;
    this.recordMediaRepository = recordMediaRepository;
    this.userRepository = userRepository;
    this.characterProfileRepository = characterProfileRepository;
    this.outboxService = outboxService;
    this.objectMapper = objectMapper;
  }

  @Transactional
  public OotdAvatarGenerationResponse create(AuthenticatedUser authenticatedUser, OotdAvatarGenerationRequest request) {
    UserEntity user = resolveUser(authenticatedUser);
    RecordEntity record = recordRepository.findByPublicIdAndDeletedAtIsNull(request.recordId())
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "record_not_found"));
    if (!record.getAuthor().getId().equals(user.getId())) {
      log.warn(
        "ootd avatar generation forbidden reason=record_owner_required recordId={} recordAuthorId={} userId={}",
        record.getPublicId(),
        record.getAuthor().getId(),
        user.getId()
      );
      throw new ResponseStatusException(HttpStatus.FORBIDDEN, "record_owner_required");
    }

    String inputType = normalizeInputType(request.inputType());
    RecordMediaEntity outfitPhotoMedia = null;
    String outfitDescription = request.outfitDescription() != null ? request.outfitDescription().trim() : null;

    if (PHOTO_REFERENCE.equals(inputType)) {
      if (request.outfitPhotoMediaId() == null && !hasText(request.outfitPhotoStorageKey())) {
        throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "outfit_photo_required");
      }
      if (outfitDescription != null && !outfitDescription.isBlank()) {
        throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "choose_photo_or_text_only");
      }
      outfitPhotoMedia = resolveOutfitPhotoMedia(record, request);
    } else if (TEXT_PROMPT.equals(inputType)) {
      if (request.outfitPhotoMediaId() != null || hasText(request.outfitPhotoStorageKey())) {
        throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "choose_photo_or_text_only");
      }
      if (outfitDescription == null || outfitDescription.isBlank()) {
        throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "outfit_description_required");
      }
    }

    String publicId = "ootd_job_" + UUID.randomUUID().toString().replace("-", "");
    Map<String, Object> payload = buildPayload(record, user, inputType, outfitPhotoMedia, outfitDescription, request.characterOverrides());
    OotdAvatarGenerationJobEntity job = new OotdAvatarGenerationJobEntity(
      publicId,
      record,
      user,
      inputType,
      outfitPhotoMedia,
      outfitDescription,
      toJson(payload)
    );
    OotdAvatarGenerationJobEntity saved = jobRepository.save(job);

    Map<String, Object> outboxPayload = new LinkedHashMap<>(payload);
    outboxPayload.put("jobId", saved.getPublicId());
    outboxPayload.put("jobDatabaseId", saved.getId().toString());
    outboxService.record("ootd.avatar_generation.requested", "ootd_avatar_generation_job", saved.getId(), outboxPayload);
    log.info(
      "ootd avatar generation job queued jobId={} recordId={} inputType={} mediaId={}",
      saved.getPublicId(),
      record.getPublicId(),
      saved.getInputType(),
      outfitPhotoMedia == null ? null : outfitPhotoMedia.getId()
    );

    return toResponse(saved);
  }

  @Transactional(readOnly = true)
  public OotdAvatarGenerationResponse get(AuthenticatedUser authenticatedUser, String jobId) {
    UserEntity user = resolveUser(authenticatedUser);
    OotdAvatarGenerationJobEntity job = jobRepository.findByPublicId(jobId)
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "job_not_found"));
    if (!job.getUser().getId().equals(user.getId())) {
      throw new ResponseStatusException(HttpStatus.FORBIDDEN, "job_owner_required");
    }
    return toResponse(job);
  }

  private String normalizeInputType(String inputType) {
    String normalized = inputType != null ? inputType.trim().toUpperCase() : "";
    if (PHOTO_REFERENCE.equals(normalized) || TEXT_PROMPT.equals(normalized)) {
      return normalized;
    }
    throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "unsupported_input_type");
  }

  private RecordMediaEntity resolveOutfitPhotoMedia(RecordEntity record, OotdAvatarGenerationRequest request) {
    RecordMediaEntity mediaById = null;
    if (request.outfitPhotoMediaId() != null) {
      mediaById = recordMediaRepository.findById(request.outfitPhotoMediaId())
        .orElse(null);
      if (mediaById != null && mediaById.getRecord().getId().equals(record.getId())) {
        return mediaById;
      }
    }

    if (hasText(request.outfitPhotoStorageKey())) {
      String expectedStorageKey = request.outfitPhotoStorageKey().trim();
      RecordMediaEntity mediaByStorageKey = recordMediaRepository.findByRecordOrderBySortOrderAsc(record)
        .stream()
        .filter(media -> expectedStorageKey.equals(media.getStorageKey()))
        .findFirst()
        .orElse(null);
      if (mediaByStorageKey != null) {
        if (mediaById != null) {
          log.warn(
            "ootd avatar generation media id mismatch recovered by storageKey recordId={} requestedMediaId={} requestedStorageKey={} mediaIdRecordId={} resolvedMediaId={}",
            record.getPublicId(),
            request.outfitPhotoMediaId(),
            expectedStorageKey,
            mediaById.getRecord().getPublicId(),
            mediaByStorageKey.getId()
          );
        }
        return mediaByStorageKey;
      }
    }

    if (mediaById == null) {
      log.warn(
        "ootd avatar generation media not found recordId={} requestedMediaId={} requestedStorageKey={}",
        record.getPublicId(),
        request.outfitPhotoMediaId(),
        request.outfitPhotoStorageKey()
      );
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, "outfit_photo_not_found");
    }

    log.warn(
      "ootd avatar generation forbidden reason=outfit_photo_record_mismatch recordId={} requestedMediaId={} requestedStorageKey={} mediaRecordId={}",
      record.getPublicId(),
      request.outfitPhotoMediaId(),
      request.outfitPhotoStorageKey(),
      mediaById.getRecord().getPublicId()
    );
    throw new ResponseStatusException(HttpStatus.FORBIDDEN, "outfit_photo_record_mismatch");
  }

  private boolean hasText(String value) {
    return value != null && !value.isBlank();
  }

  private Map<String, Object> buildPayload(
    RecordEntity record,
    UserEntity user,
    String inputType,
    RecordMediaEntity outfitPhotoMedia,
    String outfitDescription,
    Map<String, Object> requestCharacterOverrides
  ) {
    Map<String, Object> recordPayload = readObject(record.getPayload());
    Map<String, Object> characterProfile = characterProfileRepository.findByUserId(user.getId())
      .map(this::characterProfilePayload)
      .orElseGet(() -> new LinkedHashMap<String, Object>());
    Map<String, Object> characterOverrides = mergeCharacterOverrides(
      extractRecordCharacterOverrides(recordPayload),
      sanitizeCharacterOverrides(requestCharacterOverrides)
    );
    characterProfile.putAll(characterOverrides);

    Map<String, Object> payload = new LinkedHashMap<>();
    payload.put("recordId", record.getPublicId());
    payload.put("userId", user.getId().toString());
    payload.put("inputType", inputType);
    payload.put("outfitDescription", outfitDescription);
    payload.put("recordPayload", recordPayload);
    payload.put("characterProfile", characterProfile);
    if (!characterOverrides.isEmpty()) {
      payload.put("characterOverrides", characterOverrides);
    }
    if (outfitPhotoMedia != null) {
      Map<String, Object> media = new LinkedHashMap<>();
      media.put("id", outfitPhotoMedia.getId().toString());
      media.put("storageKey", outfitPhotoMedia.getStorageKey());
      media.put("publicUrl", outfitPhotoMedia.getPublicUrl());
      media.put("mediaType", outfitPhotoMedia.getMediaType());
      payload.put("outfitPhotoMedia", media);
    }
    return payload;
  }

  private Map<String, Object> characterProfilePayload(CharacterProfileEntity profile) {
    Map<String, Object> value = new LinkedHashMap<>();
    value.put("gender", profile.getGender());
    value.put("skinTone", profile.getSkinTone());
    value.put("hairStyle", profile.getHairStyle());
    value.put("hairColor", profile.getHairColor());
    value.put("eyeStyle", profile.getEyeStyle());
    value.put("eyeColor", profile.getEyeColor());
    value.put("clothes", profile.getClothes());
    return value;
  }

  private Map<String, Object> extractRecordCharacterOverrides(Map<String, Object> recordPayload) {
    Object snapshot = recordPayload.get("characterSnapshot");
    if (!(snapshot instanceof Map<?, ?> snapshotMap)) {
      return Map.of();
    }
    Map<String, Object> overrides = new LinkedHashMap<>();
    putStringOverride(overrides, "hairStyle", snapshotMap.get("hair_style"));
    putStringOverride(overrides, "hairColor", snapshotMap.get("hair_color"));
    putStringOverride(overrides, "eyeStyle", snapshotMap.get("eye_style"));
    putStringOverride(overrides, "eyeColor", snapshotMap.get("eye_color"));
    return overrides;
  }

  private Map<String, Object> sanitizeCharacterOverrides(Map<String, Object> rawOverrides) {
    if (rawOverrides == null || rawOverrides.isEmpty()) {
      return Map.of();
    }
    Map<String, Object> overrides = new LinkedHashMap<>();
    putStringOverride(overrides, "hairStyle", rawOverrides.get("hairStyle"));
    putStringOverride(overrides, "hairColor", rawOverrides.get("hairColor"));
    putStringOverride(overrides, "eyeStyle", rawOverrides.get("eyeStyle"));
    putStringOverride(overrides, "eyeColor", rawOverrides.get("eyeColor"));
    return overrides;
  }

  private Map<String, Object> mergeCharacterOverrides(Map<String, Object> recordOverrides, Map<String, Object> requestOverrides) {
    Map<String, Object> merged = new LinkedHashMap<>();
    if (recordOverrides != null) {
      merged.putAll(recordOverrides);
    }
    if (requestOverrides != null) {
      merged.putAll(requestOverrides);
    }
    return merged;
  }

  private void putStringOverride(Map<String, Object> target, String key, Object value) {
    if (value instanceof String stringValue && !stringValue.isBlank()) {
      target.put(key, stringValue);
    }
  }

  private OotdAvatarGenerationResponse toResponse(OotdAvatarGenerationJobEntity job) {
    return new OotdAvatarGenerationResponse(
      job.getPublicId(),
      job.getStatus(),
      job.getRecord().getPublicId(),
      job.getResultPublicUrl(),
      job.getErrorCode(),
      Boolean.TRUE.equals(job.getRetryable()),
      job.getCreatedAt(),
      job.getUpdatedAt()
    );
  }

  private UserEntity resolveUser(AuthenticatedUser authenticatedUser) {
    if (authenticatedUser == null) {
      throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "unauthorized");
    }

    return userRepository.findByIdAndDeletedAtIsNull(authenticatedUser.userId())
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "user_not_found"));
  }

  private String toJson(Object obj) {
    try {
      return objectMapper.writeValueAsString(obj);
    } catch (JsonProcessingException exception) {
      throw new IllegalStateException("Serialization error", exception);
    }
  }

  private Map<String, Object> readObject(String json) {
    try {
      return objectMapper.readValue(json, Map.class);
    } catch (JsonProcessingException exception) {
      return Map.of();
    }
  }
}
