package com.onmu.api.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.onmu.api.domain.GroupEntity;
import com.onmu.api.domain.GroupRepository;
import com.onmu.api.domain.OotdFeatureEntity;
import com.onmu.api.domain.OotdFeatureRepository;
import com.onmu.api.domain.PlanEntity;
import com.onmu.api.domain.PlanRepository;
import com.onmu.api.domain.RecordEntity;
import com.onmu.api.domain.RecordMediaEntity;
import com.onmu.api.domain.RecordMediaRepository;
import com.onmu.api.domain.RecordRepository;
import com.onmu.api.domain.RecordTagEntity;
import com.onmu.api.domain.RecordTagRepository;
import com.onmu.api.domain.UserEntity;
import com.onmu.api.domain.UserRepository;
import com.onmu.api.web.dto.CreateRecordRequest;
import com.onmu.api.web.dto.OotdCallbackRequest;
import com.onmu.api.web.dto.RecordMediaInput;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
public class RecordService {
  private final RecordRepository recordRepository;
  private final RecordMediaRepository recordMediaRepository;
  private final RecordTagRepository recordTagRepository;
  private final OotdFeatureRepository ootdFeatureRepository;
  private final GroupRepository groupRepository;
  private final PlanRepository planRepository;
  private final UserRepository userRepository;
  private final OutboxService outboxService;
  private final ObjectMapper objectMapper;

  public RecordService(
    RecordRepository recordRepository,
    RecordMediaRepository recordMediaRepository,
    RecordTagRepository recordTagRepository,
    OotdFeatureRepository ootdFeatureRepository,
    GroupRepository groupRepository,
    PlanRepository planRepository,
    UserRepository userRepository,
    OutboxService outboxService,
    ObjectMapper objectMapper
  ) {
    this.recordRepository = recordRepository;
    this.recordMediaRepository = recordMediaRepository;
    this.recordTagRepository = recordTagRepository;
    this.ootdFeatureRepository = ootdFeatureRepository;
    this.groupRepository = groupRepository;
    this.planRepository = planRepository;
    this.userRepository = userRepository;
    this.outboxService = outboxService;
    this.objectMapper = objectMapper;
  }

  @Transactional
  public Map<String, Object> createRecord(String groupId, String planId, CreateRecordRequest request) {
    GroupEntity group = groupRepository.findByPublicId(groupId)
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "group_not_found"));
    PlanEntity plan = planRepository.findByGroupAndPublicId(group, planId)
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "plan_not_found"));
    UserEntity author = currentUser();

    if (!groupRepository.isUserMember(groupId, author.getId())) {
      throw new ResponseStatusException(HttpStatus.FORBIDDEN, "not_group_member");
    }
    if (!planRepository.isUserParticipant(planId, author.getId())) {
      throw new ResponseStatusException(HttpStatus.FORBIDDEN, "not_plan_participant");
    }

    String publicId = "rec_" + UUID.randomUUID().toString().replace("-", "");
    String moodTagsJson = toJson(request.moodTags() != null ? request.moodTags() : List.of());

    Map<String, Object> recordPayload = new LinkedHashMap<>();
    recordPayload.put("body", request.body() != null ? request.body().trim() : "");
    recordPayload.put("recordType", request.recordType() != null ? request.recordType().trim() : "OOTD");
    recordPayload.put("recordedAt", request.recordedAt() != null ? request.recordedAt().trim() : Instant.now().toString());
    String payloadJson = toJson(recordPayload);

    RecordEntity record = new RecordEntity(
      publicId,
      group,
      plan,
      author,
      request.title().trim(),
      request.visibility() != null ? request.visibility().toLowerCase() : "participants",
      payloadJson,
      moodTagsJson
    );
    record.setSummary(request.summary() != null ? request.summary().trim() : null);
    RecordEntity savedRecord = recordRepository.save(record);

    // Save media
    List<Map<String, Object>> mediaPayloads = new ArrayList<>();
    if (request.media() != null) {
      for (RecordMediaInput mediaInput : request.media()) {
        RecordMediaEntity mediaEntity = new RecordMediaEntity(
          savedRecord,
          mediaInput.mediaType() != null ? mediaInput.mediaType() : "IMAGE",
          mediaInput.storageKey(),
          mediaInput.publicUrl(),
          mediaInput.width(),
          mediaInput.height(),
          mediaInput.durationSeconds(),
          mediaInput.sortOrder(),
          "{}"
        );
        recordMediaRepository.save(mediaEntity);
        
        Map<String, Object> mInfo = new LinkedHashMap<>();
        mInfo.put("mediaType", mediaEntity.getMediaType());
        mInfo.put("storageKey", mediaEntity.getStorageKey());
        mInfo.put("publicUrl", mediaEntity.getPublicUrl());
        mediaPayloads.add(mInfo);
      }
    }

    // Save tags
    if (request.moodTags() != null) {
      for (String tag : request.moodTags()) {
        recordTagRepository.save(new RecordTagEntity(savedRecord, "user", tag));
      }
    }

    // Record outbox event for FastAPI worker if user consented to AI
    boolean hasConsent = userRepository.checkPrivacyConsent(author.getId());
    if (hasConsent) {
      Map<String, Object> outboxPayload = new LinkedHashMap<>();
      outboxPayload.put("groupId", group.getPublicId());
      outboxPayload.put("planId", plan.getPublicId());
      outboxPayload.put("recordId", savedRecord.getPublicId());
      outboxPayload.put("authorId", author.getId().toString());
      outboxPayload.put("title", savedRecord.getTitle());
      outboxPayload.put("media", mediaPayloads);
      outboxService.record("record.created", "record", savedRecord.getId(), outboxPayload);
    }

    return getRecordCard(savedRecord);
  }

  @Transactional(readOnly = true)
  public List<Map<String, Object>> getRecentRecords() {
    UserEntity author = currentUser();
    List<RecordEntity> records = recordRepository.findByAuthorAndDeletedAtIsNullOrderByCreatedAtDesc(author);
    return records.stream().map(this::getRecordCard).toList();
  }

  @Transactional(readOnly = true)
  public Map<String, Object> getRecordDetail(String recordId) {
    RecordEntity record = recordRepository.findByPublicIdAndDeletedAtIsNull(recordId)
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "record_not_found"));
    UserEntity user = currentUser();
    if (!groupRepository.isUserMember(record.getGroup().getPublicId(), user.getId())) {
      throw new ResponseStatusException(HttpStatus.FORBIDDEN, "not_group_member");
    }

    String visibility = record.getVisibility() != null ? record.getVisibility().toLowerCase() : "participants";
    if ("private".equals(visibility)) {
      if (!record.getAuthor().getId().equals(user.getId())) {
        throw new ResponseStatusException(HttpStatus.FORBIDDEN, "private_record_access_denied");
      }
    } else if ("participants".equals(visibility)) {
      if (!planRepository.isUserParticipant(record.getPlan().getPublicId(), user.getId())) {
        throw new ResponseStatusException(HttpStatus.FORBIDDEN, "not_plan_participant");
      }
    }

    return getRecordCard(record);
  }

  @Transactional
  public Map<String, Object> processOotdCallback(OotdCallbackRequest request) {
    RecordEntity record = recordRepository.findByPublicIdAndDeletedAtIsNull(request.recordId())
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "record_not_found"));

    boolean isFailed = "FAILED".equalsIgnoreCase(request.status());

    if (isFailed) {
      Map<String, Object> payloadMap = readObject(record.getPayload());
      payloadMap.put("aiStatus", "FAILED");
      payloadMap.put("aiErrorReason", request.errorMessage() != null ? request.errorMessage() : "Unknown AI error");
      record.setPayload(toJson(payloadMap));
      recordRepository.save(record);

      Map<String, Object> featureMap = new LinkedHashMap<>();
      featureMap.put("status", "FAILED");
      featureMap.put("errorReason", request.errorMessage() != null ? request.errorMessage() : "Unknown AI error");

      OotdFeatureEntity featureEntity = new OotdFeatureEntity(
        record,
        record.getAuthor(),
        "AI_FAILED",
        toJson(featureMap)
      );
      ootdFeatureRepository.save(featureEntity);

      return getRecordCard(record);
    }

    // Update record payload with SUCCESS status
    Map<String, Object> payloadMap = readObject(record.getPayload());
    payloadMap.put("aiStatus", "SUCCESS");
    record.setPayload(toJson(payloadMap));
    recordRepository.save(record);

    // Save features
    String featuresJson = toJson(request.features() != null ? request.features() : Collections.emptyMap());
    OotdFeatureEntity featureEntity = new OotdFeatureEntity(
      record,
      record.getAuthor(),
      "AI",
      featuresJson
    );
    ootdFeatureRepository.save(featureEntity);

    // Save tags
    if (request.tags() != null) {
      for (String tag : request.tags()) {
        recordTagRepository.save(new RecordTagEntity(record, "AI", tag));
      }
    }

    // Optional: Update first image with processed URL from AI
    if (request.imageUrl() != null && !request.imageUrl().isBlank()) {
      List<RecordMediaEntity> mediaList = recordMediaRepository.findByRecordOrderBySortOrderAsc(record);
      if (!mediaList.isEmpty()) {
        RecordMediaEntity firstMedia = mediaList.get(0);
        firstMedia.setPublicUrl(request.imageUrl());
        recordMediaRepository.save(firstMedia);
      }
    }

    return getRecordCard(record);
  }

  private Map<String, Object> getRecordCard(RecordEntity record) {
    List<RecordMediaEntity> mediaList = recordMediaRepository.findByRecordOrderBySortOrderAsc(record);
    List<RecordTagEntity> tagList = recordTagRepository.findByRecord(record);
    OotdFeatureEntity featureOpt = ootdFeatureRepository.findFirstByRecordOrderByCreatedAtDesc(record).orElse(null);

    Map<String, Object> value = new LinkedHashMap<>();
    value.put("id", record.getPublicId());
    value.put("title", record.getTitle());
    value.put("summary", record.getSummary());
    value.put("memo", record.getSummary()); // bff compatibility
    value.put("visibility", record.getVisibility());
    value.put("groupId", record.getGroup() != null ? record.getGroup().getPublicId() : null);
    value.put("planId", record.getPlan() != null ? record.getPlan().getPublicId() : null);
    value.put("authorId", record.getAuthor() != null ? record.getAuthor().getId().toString() : null);
    value.put("createdAt", record.getCreatedAt() != null ? record.getCreatedAt().toString() : Instant.now().toString());

    Map<String, Object> payloadMap = readObject(record.getPayload());
    String body = payloadMap.containsKey("body") && payloadMap.get("body") != null ? payloadMap.get("body").toString() : "";
    String recordType = payloadMap.containsKey("recordType") && payloadMap.get("recordType") != null ? payloadMap.get("recordType").toString() : "OOTD";
    String defaultRecordedAt = record.getCreatedAt() != null ? record.getCreatedAt().toString() : Instant.now().toString();
    String recordedAt = payloadMap.containsKey("recordedAt") && payloadMap.get("recordedAt") != null ? payloadMap.get("recordedAt").toString() : defaultRecordedAt;

    boolean hasConsent = userRepository.checkPrivacyConsent(record.getAuthor().getId());
    String defaultAiStatus = hasConsent ? "PENDING" : "SKIPPED";
    String aiStatus = payloadMap.containsKey("aiStatus") && payloadMap.get("aiStatus") != null 
        ? payloadMap.get("aiStatus").toString() 
        : defaultAiStatus;
    String aiErrorReason = payloadMap.containsKey("aiErrorReason") && payloadMap.get("aiErrorReason") != null 
        ? payloadMap.get("aiErrorReason").toString() 
        : null;

    value.put("body", body);
    value.put("recordType", recordType);
    value.put("recordedAt", recordedAt);
    value.put("aiStatus", aiStatus);
    value.put("aiErrorReason", aiErrorReason);

    // Tags
    List<String> tags = new ArrayList<>();
    // add user mood tags
    List<String> userMoodTags = readStringList(record.getMoodTags());
    tags.addAll(userMoodTags);
    // add DB tags
    for (RecordTagEntity t : tagList) {
      if (!tags.contains(t.getTagValue())) {
        tags.add(t.getTagValue());
      }
    }
    value.put("tags", tags);

    // Image URLs & Media objects
    List<String> imageUrls = new ArrayList<>();
    List<Map<String, Object>> mediaObjects = new ArrayList<>();
    for (RecordMediaEntity m : mediaList) {
      imageUrls.add(m.getPublicUrl());
      
      Map<String, Object> mObj = new LinkedHashMap<>();
      mObj.put("id", m.getId().toString());
      mObj.put("mediaType", m.getMediaType());
      mObj.put("storageKey", m.getStorageKey());
      mObj.put("publicUrl", m.getPublicUrl());
      mObj.put("width", m.getWidth());
      mObj.put("height", m.getHeight());
      mObj.put("durationSeconds", m.getDurationSeconds());
      mObj.put("sortOrder", m.getSortOrder());
      mediaObjects.add(mObj);
    }
    value.put("imageUrls", imageUrls);
    value.put("media", mediaObjects);

    // OOTD features
    if (featureOpt != null) {
      value.put("features", readObject(featureOpt.getFeatures()));
      value.put("featureSource", featureOpt.getFeatureSource());
    } else {
      value.put("features", Collections.emptyMap());
      value.put("featureSource", "none");
    }

    return value;
  }

  private UserEntity currentUser() {
    org.springframework.security.core.Authentication auth = org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication();
    if (auth == null || !auth.isAuthenticated() || "anonymousUser".equals(auth.getName())) {
      return userRepository.findFirstByOrderByCreatedAtAsc()
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "unauthorized"));
    }

    String name = auth.getName();
    try {
      UUID userId = UUID.fromString(name);
      return userRepository.findById(userId)
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "user_not_found"));
    } catch (IllegalArgumentException e) {
      return userRepository.findFirstByOrderByCreatedAtAsc()
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "dev_seed_data_missing"));
    }
  }

  private String toJson(Object obj) {
    try {
      return objectMapper.writeValueAsString(obj);
    } catch (JsonProcessingException exception) {
      throw new IllegalStateException("Serialization error", exception);
    }
  }

  private List<String> readStringList(String json) {
    try {
      return objectMapper.readValue(json, List.class);
    } catch (JsonProcessingException exception) {
      return Collections.emptyList();
    }
  }

  private Map<String, Object> readObject(String json) {
    try {
      return objectMapper.readValue(json, Map.class);
    } catch (JsonProcessingException exception) {
      return Collections.emptyMap();
    }
  }
}
