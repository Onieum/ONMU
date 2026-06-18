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
import com.onmu.api.domain.CharacterProfileEntity;
import com.onmu.api.domain.CharacterProfileRepository;
import com.onmu.api.web.dto.CreateMemoryRequest;
import com.onmu.api.web.dto.MemoryResponse;
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
  private final CharacterProfileRepository characterProfileRepository;

  public RecordService(
    RecordRepository recordRepository,
    RecordMediaRepository recordMediaRepository,
    RecordTagRepository recordTagRepository,
    OotdFeatureRepository ootdFeatureRepository,
    GroupRepository groupRepository,
    PlanRepository planRepository,
    UserRepository userRepository,
    OutboxService outboxService,
    ObjectMapper objectMapper,
    CharacterProfileRepository characterProfileRepository
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
    this.characterProfileRepository = characterProfileRepository;
  }

  @Transactional
  public Map<String, Object> createRecord(UUID userId, String groupId, String planId, CreateRecordRequest request) {
    GroupEntity group = groupRepository.findByPublicId(groupId)
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "group_not_found"));
    PlanEntity plan = planRepository.findByGroupAndPublicId(group, planId)
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "plan_not_found"));
    UserEntity author = user(userId);

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
  public List<Map<String, Object>> getRecentRecords(UUID userId) {
    UserEntity author = user(userId);
    List<RecordEntity> records = recordRepository.findByAuthorAndDeletedAtIsNullOrderByCreatedAtDesc(author);
    return records.stream().map(this::getRecordCard).toList();
  }

  @Transactional(readOnly = true)
  public Map<String, Object> getRecordDetail(UUID userId, String recordId) {
    RecordEntity record = recordRepository.findByPublicIdAndDeletedAtIsNull(recordId)
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "record_not_found"));
    UserEntity viewer = user(userId);
    if (!groupRepository.isUserMember(record.getGroup().getPublicId(), viewer.getId())) {
      throw new ResponseStatusException(HttpStatus.FORBIDDEN, "not_group_member");
    }

    String visibility = record.getVisibility() != null ? record.getVisibility().toLowerCase() : "participants";
    if ("private".equals(visibility)) {
      if (!record.getAuthor().getId().equals(viewer.getId())) {
        throw new ResponseStatusException(HttpStatus.FORBIDDEN, "private_record_access_denied");
      }
    } else if ("participants".equals(visibility)) {
      if (!planRepository.isUserParticipant(record.getPlan().getPublicId(), viewer.getId())) {
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

  private UserEntity user(UUID userId) {
    return userRepository.findByIdAndDeletedAtIsNull(userId)
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "user_not_found"));
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

  @Transactional(readOnly = true)
  public List<MemoryResponse> getPersonalMemories(UUID userId) {
    UserEntity author = user(userId);
    List<RecordEntity> records = recordRepository.findByAuthorAndDeletedAtIsNullOrderByCreatedAtDesc(author);
    return records.stream().map(this::mapToMemoryResponse).toList();
  }

  @Transactional(readOnly = true)
  public List<MemoryResponse> getGroupMemories(UUID userId, String groupId) {
    UserEntity viewer = user(userId);
    GroupEntity group = groupRepository.findByPublicId(groupId)
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "group_not_found"));
    if (!groupRepository.isUserMember(groupId, viewer.getId())) {
      throw new ResponseStatusException(HttpStatus.FORBIDDEN, "not_group_member");
    }
    List<RecordEntity> records = recordRepository.findByGroupAndDeletedAtIsNullOrderByCreatedAtDesc(group);
    return records.stream().map(this::mapToMemoryResponse).toList();
  }

  @Transactional(readOnly = true)
  public MemoryResponse getMemoryDetail(UUID userId, String memoryId) {
    RecordEntity record = recordRepository.findByPublicIdAndDeletedAtIsNull(memoryId)
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "memory_not_found"));
    UserEntity viewer = user(userId);
    
    if (record.getGroup() != null) {
      if (!groupRepository.isUserMember(record.getGroup().getPublicId(), viewer.getId())) {
        throw new ResponseStatusException(HttpStatus.FORBIDDEN, "not_group_member");
      }
    }

    String visibility = record.getVisibility() != null ? record.getVisibility().toLowerCase() : "public";
    if ("private".equals(visibility)) {
      if (!record.getAuthor().getId().equals(viewer.getId())) {
        throw new ResponseStatusException(HttpStatus.FORBIDDEN, "private_record_access_denied");
      }
    } else if ("participants_only".equals(visibility) || "participants".equals(visibility)) {
      if (record.getPlan() != null && !planRepository.isUserParticipant(record.getPlan().getPublicId(), viewer.getId())) {
        throw new ResponseStatusException(HttpStatus.FORBIDDEN, "not_plan_participant");
      }
    } else if ("group_only".equals(visibility) || "group".equals(visibility)) {
      if (record.getGroup() != null && !groupRepository.isUserMember(record.getGroup().getPublicId(), viewer.getId())) {
        throw new ResponseStatusException(HttpStatus.FORBIDDEN, "not_group_member");
      }
    }

    return mapToMemoryResponse(record);
  }

  @Transactional(readOnly = true)
  public MemoryResponse getGroupMemoryDetail(UUID userId, String groupId, String memoryId) {
    MemoryResponse response = getMemoryDetail(userId, memoryId);
    GroupEntity group = groupRepository.findByPublicId(groupId)
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "group_not_found"));
    if (response.groupId() == null || !response.groupId().equals(group.getId())) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, "memory_not_found_in_group");
    }
    return response;
  }

  @Transactional
  public MemoryResponse createMemory(UUID userId, String groupId, CreateMemoryRequest request) {
    UserEntity author = user(userId);
    GroupEntity group = null;
    if (groupId != null) {
      group = groupRepository.findByPublicId(groupId)
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "group_not_found"));
      if (!groupRepository.isUserMember(groupId, author.getId())) {
        throw new ResponseStatusException(HttpStatus.FORBIDDEN, "not_group_member");
      }
    }

    String publicId = "rec_" + UUID.randomUUID().toString().replace("-", "");
    String moodTagsJson = toJson(request.tags() != null ? request.tags() : List.of());

    CharacterProfileEntity characterProfile = characterProfileRepository.findByUserId(author.getId())
        .orElseGet(() -> new CharacterProfileEntity(
            author.getId(),
            "female",
            "type_warm",
            "short_black",
            "black",
            "round",
            "brown",
            "casual_tshirt"
        ));

    Map<String, Object> snapshot = new LinkedHashMap<>();
    snapshot.put("skin_tone", characterProfile.getSkinTone());
    snapshot.put("hair_style", request.hairStyle() != null ? request.hairStyle() : characterProfile.getHairStyle());
    snapshot.put("hair_color", request.hairColor() != null ? request.hairColor() : characterProfile.getHairColor());
    snapshot.put("eye_style", characterProfile.getEyeStyle());
    snapshot.put("eye_color", request.eyeColor() != null ? request.eyeColor() : characterProfile.getEyeColor());
    snapshot.put("clothes", "none");

    Map<String, Object> recordPayload = new LinkedHashMap<>();
    recordPayload.put("body", request.memo() != null ? request.memo().trim() : "");
    recordPayload.put("recordType", request.type() != null ? request.type().trim() : "OOTD");
    recordPayload.put("recordedAt", request.date() != null ? request.date().trim() : Instant.now().toString());
    recordPayload.put("characterSnapshot", snapshot);
    if (request.payload() != null) {
      recordPayload.putAll(request.payload());
      recordPayload.put("characterSnapshot", snapshot);
      recordPayload.put("recordType", request.type() != null ? request.type().trim() : "OOTD");
      recordPayload.put("recordedAt", request.date() != null ? request.date().trim() : Instant.now().toString());
      recordPayload.put("body", request.memo() != null ? request.memo().trim() : "");
    }
    
    boolean hasConsent = userRepository.checkPrivacyConsent(author.getId());
    recordPayload.put("aiStatus", hasConsent ? "PENDING" : "SKIPPED");
    
    String payloadJson = toJson(recordPayload);

    RecordEntity record = new RecordEntity(
      publicId,
      group,
      null,
      author,
      request.title() != null ? request.title().trim() : "Untitled Memory",
      normalizeRecordVisibility(request.visibility()),
      payloadJson,
      moodTagsJson
    );
    RecordEntity savedRecord = recordRepository.save(record);

    List<Map<String, Object>> mediaPayloads = new ArrayList<>();
    if (request.imageUrls() != null) {
      int order = 0;
      for (String url : request.imageUrls()) {
        String key = "records/media/" + UUID.randomUUID().toString() + ".jpg";
        RecordMediaEntity mediaEntity = new RecordMediaEntity(
          savedRecord,
          "IMAGE",
          key,
          url,
          800,
          800,
          null,
          order++,
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

    if (request.tags() != null) {
      for (String tag : request.tags()) {
        recordTagRepository.save(new RecordTagEntity(savedRecord, "user", tag));
      }
    }

    if (hasConsent) {
      Map<String, Object> outboxPayload = new LinkedHashMap<>();
      outboxPayload.put("groupId", group != null ? group.getPublicId() : null);
      outboxPayload.put("planId", null);
      outboxPayload.put("recordId", savedRecord.getPublicId());
      outboxPayload.put("authorId", author.getId().toString());
      outboxPayload.put("title", savedRecord.getTitle());
      outboxPayload.put("media", mediaPayloads);
      outboxPayload.put("characterSnapshot", snapshot);
      outboxService.record("record.created", "record", savedRecord.getId(), outboxPayload);
    }

    return mapToMemoryResponse(savedRecord);
  }

  @Transactional
  public MemoryResponse updateMemory(UUID userId, String memoryId, CreateMemoryRequest request) {
    UserEntity author = user(userId);
    RecordEntity record = recordRepository.findByPublicIdAndDeletedAtIsNull(memoryId)
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "memory_not_found"));
    if (!record.getAuthor().getId().equals(author.getId())) {
      throw new ResponseStatusException(HttpStatus.FORBIDDEN, "memory_update_forbidden");
    }

    CharacterProfileEntity characterProfile = characterProfileRepository.findByUserId(author.getId())
        .orElseGet(() -> new CharacterProfileEntity(
            author.getId(),
            "female",
            "type_warm",
            "short_black",
            "black",
            "round",
            "brown",
            "casual_tshirt"
        ));

    Map<String, Object> snapshot = new LinkedHashMap<>();
    snapshot.put("skin_tone", characterProfile.getSkinTone());
    snapshot.put("hair_style", request.hairStyle() != null ? request.hairStyle() : characterProfile.getHairStyle());
    snapshot.put("hair_color", request.hairColor() != null ? request.hairColor() : characterProfile.getHairColor());
    snapshot.put("eye_style", characterProfile.getEyeStyle());
    snapshot.put("eye_color", request.eyeColor() != null ? request.eyeColor() : characterProfile.getEyeColor());
    snapshot.put("clothes", "none");

    Map<String, Object> previousPayload = readObject(record.getPayload());
    Map<String, Object> recordPayload = new LinkedHashMap<>();
    recordPayload.put("body", request.memo() != null ? request.memo().trim() : "");
    recordPayload.put("recordType", request.type() != null ? request.type().trim() : "OOTD");
    recordPayload.put("recordedAt", request.date() != null ? request.date().trim() : Instant.now().toString());
    recordPayload.put("characterSnapshot", snapshot);
    if (request.payload() != null) {
      recordPayload.putAll(request.payload());
      recordPayload.put("characterSnapshot", snapshot);
      recordPayload.put("recordType", request.type() != null ? request.type().trim() : "OOTD");
      recordPayload.put("recordedAt", request.date() != null ? request.date().trim() : Instant.now().toString());
      recordPayload.put("body", request.memo() != null ? request.memo().trim() : "");
    }
    recordPayload.put("aiStatus", previousPayload.getOrDefault("aiStatus", "SKIPPED"));

    record.setTitle(request.title() != null ? request.title().trim() : record.getTitle());
    record.setVisibility(normalizeRecordVisibility(request.visibility()));
    record.setPayload(toJson(recordPayload));
    record.setMoodTags(toJson(request.tags() != null ? request.tags() : List.of()));
    record.setUpdatedAt(Instant.now());

    recordTagRepository.deleteByRecord(record);
    recordMediaRepository.deleteByRecord(record);
    recordTagRepository.flush();
    recordMediaRepository.flush();

    if (request.imageUrls() != null) {
      int order = 0;
      for (String url : request.imageUrls()) {
        String key = "records/media/" + UUID.randomUUID().toString() + ".jpg";
        recordMediaRepository.save(new RecordMediaEntity(
          record,
          "IMAGE",
          key,
          url,
          800,
          800,
          null,
          order++,
          "{}"
        ));
      }
    }

    if (request.tags() != null) {
      for (String tag : request.tags().stream().filter(t -> t != null && !t.isBlank()).distinct().toList()) {
        recordTagRepository.save(new RecordTagEntity(record, "user", tag));
      }
    }

    RecordEntity saved = recordRepository.save(record);
    return mapToMemoryResponse(saved);
  }

  @Transactional
  public void deleteMemory(UUID userId, String memoryId) {
    UserEntity author = user(userId);
    RecordEntity record = recordRepository.findByPublicIdAndDeletedAtIsNull(memoryId)
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "memory_not_found"));
    if (!record.getAuthor().getId().equals(author.getId())) {
      throw new ResponseStatusException(HttpStatus.FORBIDDEN, "memory_delete_forbidden");
    }
    record.setDeletedAt(Instant.now());
    record.setUpdatedAt(Instant.now());
    recordRepository.save(record);
  }

  private MemoryResponse mapToMemoryResponse(RecordEntity record) {
    Map<String, Object> payloadMap = readObject(record.getPayload());
    String memo = (String) payloadMap.getOrDefault("body", "");
    String type = (String) payloadMap.getOrDefault("recordType", "OOTD");
    String date = (String) payloadMap.getOrDefault("recordedAt", "");
    String aiStatus = (String) payloadMap.getOrDefault("aiStatus", "SKIPPED");
    Map<String, Object> characterSnapshot = (Map<String, Object>) payloadMap.getOrDefault("characterSnapshot", Collections.emptyMap());

    List<RecordMediaEntity> mediaList = recordMediaRepository.findByRecordOrderBySortOrderAsc(record);
    List<String> imageUrls = mediaList.stream()
      .map(RecordMediaEntity::getPublicUrl)
      .filter(url -> url != null && !url.isBlank())
      .toList();

    List<RecordTagEntity> tagEntities = recordTagRepository.findByRecord(record);
    List<String> tags = tagEntities.stream().map(RecordTagEntity::getTagValue).toList();

    return new MemoryResponse(
        record.getId(),
        record.getPublicId(),
        type,
        record.getTitle(),
        memo,
        date,
        record.getAuthor().getId(),
        record.getAuthor().getDisplayName(),
        record.getGroup() != null ? record.getGroup().getId() : null,
        tags,
        imageUrls,
        record.getVisibility(),
        characterSnapshot,
        payloadMap,
        aiStatus,
        record.getCreatedAt()
    );
  }

  private String normalizeRecordVisibility(String visibility) {
    if (visibility == null || visibility.isBlank()) {
      return "private";
    }
    return switch (visibility.trim().toUpperCase()) {
      case "PRIVATE" -> "private";
      case "PARTICIPANT_ONLY", "PARTICIPANTS" -> "participants";
      case "GROUP_ONLY", "GROUP" -> "group";
      case "PUBLIC" -> "private";
      default -> visibility.trim().toLowerCase();
    };
  }
}
