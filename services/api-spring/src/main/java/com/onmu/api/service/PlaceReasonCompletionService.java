package com.onmu.api.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.onmu.api.domain.PlaceCandidateEntity;
import com.onmu.api.domain.PlaceCandidateRepository;
import com.onmu.api.web.dto.PlaceReasonCallbackRequest;
import java.time.Instant;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
public class PlaceReasonCompletionService {
  private static final int MAX_REASON_COUNT = 3;
  private static final int MAX_REASON_LENGTH = 120;
  private static final int MAX_SUMMARY_LENGTH = 180;

  private final PlaceCandidateRepository placeCandidateRepository;
  private final ObjectMapper objectMapper;

  public PlaceReasonCompletionService(
    PlaceCandidateRepository placeCandidateRepository,
    ObjectMapper objectMapper
  ) {
    this.placeCandidateRepository = placeCandidateRepository;
    this.objectMapper = objectMapper;
  }

  @Transactional
  public Map<String, Object> completeFromWorker(PlaceReasonCallbackRequest request) {
    PlaceCandidateEntity candidate = placeCandidateRepository.findByPublicId(request.candidateId())
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "place_candidate_not_found"));
    requireSamePlanScope(candidate, request);

    Map<String, Object> payload = readPayload(candidate.getPayload());
    String status = normalizeStatus(request.status());
    List<String> reasons = sanitizeReasons(request.reasons());
    String summary = sanitizeText(request.summary(), MAX_SUMMARY_LENGTH);

    if ("completed".equals(status)) {
      if (summary != null) {
        payload.put("summary", summary);
      }
      if (!reasons.isEmpty()) {
        payload.put("reasons", reasons);
      }
    }
    payload.put("recommendation", recommendationPayload(payload, request, status, reasons));
    candidate.setPayload(writePayload(payload));

    return Map.of(
      "ok", true,
      "candidateId", candidate.getPublicId(),
      "aiStatus", status,
      "reasonCount", reasons.isEmpty() ? existingReasonCount(payload) : reasons.size()
    );
  }

  private void requireSamePlanScope(PlaceCandidateEntity candidate, PlaceReasonCallbackRequest request) {
    String groupId = sanitizeText(request.groupId(), 80);
    String planId = sanitizeText(request.planId(), 80);
    if (groupId != null && !groupId.equals(candidate.getGroup().getPublicId())) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, "place_candidate_not_found");
    }
    if (planId != null && !planId.equals(candidate.getPlan().getPublicId())) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, "place_candidate_not_found");
    }
  }

  private Map<String, Object> recommendationPayload(
    Map<String, Object> existingPayload,
    PlaceReasonCallbackRequest request,
    String status,
    List<String> reasons
  ) {
    Map<String, Object> value = new LinkedHashMap<>();
    Object previous = existingPayload.get("recommendation");
    if (previous instanceof Map<?, ?> previousMap) {
      previousMap.forEach((key, rawValue) -> {
        if (key instanceof String name && isSafeRecommendationKey(name)) {
          value.put(name, rawValue);
        }
      });
    }
    if (request.recommendation() != null) {
      request.recommendation().forEach((key, rawValue) -> {
        if (isSafeRecommendationKey(key) && rawValue != null) {
          value.put(key, rawValue);
        }
      });
    }
    value.put("version", "ai-place-v1");
    value.put("aiStatus", status);
    value.put("reasonSource", stringOrDefault(asString(value.get("reasonSource")), "worker"));
    value.put("reasonCount", reasons.isEmpty() ? existingReasonCount(existingPayload) : reasons.size());
    putIfNotBlank(value, "jobRunId", request.jobRunId());
    putIfNotBlank(value, "promptRunId", request.promptRunId());
    putIfNotBlank(value, "errorCode", request.errorCode());
    value.put("updatedAt", Instant.now().toString());
    return value;
  }

  private boolean isSafeRecommendationKey(String key) {
    return switch (key) {
      case "version", "aiStatus", "reasonSource", "reasonCount", "jobRunId", "promptRunId", "errorCode",
        "modelConfigured", "promptKind" -> true;
      default -> false;
    };
  }

  private Map<String, Object> readPayload(String json) {
    try {
      Map<String, Object> value = objectMapper.readValue(json, new TypeReference<>() {});
      return value == null ? new LinkedHashMap<>() : new LinkedHashMap<>(value);
    } catch (Exception exception) {
      return new LinkedHashMap<>();
    }
  }

  private String writePayload(Map<String, Object> payload) {
    try {
      return objectMapper.writeValueAsString(payload);
    } catch (JsonProcessingException exception) {
      throw new IllegalStateException("failed_to_update_place_candidate_payload", exception);
    }
  }

  private String normalizeStatus(String value) {
    String status = sanitizeText(value, 40);
    if (status == null) {
      return "failed";
    }
    return switch (status.toLowerCase(Locale.ROOT)) {
      case "completed", "success", "succeeded" -> "completed";
      case "accepted", "queued", "running" -> "accepted";
      default -> "failed";
    };
  }

  private List<String> sanitizeReasons(List<String> values) {
    if (values == null || values.isEmpty()) {
      return List.of();
    }
    List<String> result = new ArrayList<>();
    for (String value : values) {
      String reason = sanitizeText(value, MAX_REASON_LENGTH);
      if (reason != null && !containsInternalDiagnostic(reason) && !result.contains(reason)) {
        result.add(reason);
      }
      if (result.size() >= MAX_REASON_COUNT) {
        break;
      }
    }
    return result;
  }

  private boolean containsInternalDiagnostic(String value) {
    String lower = value.toLowerCase(Locale.ROOT);
    return lower.contains("provider")
      || lower.contains("source=")
      || lower.contains("token")
      || lower.contains("secret")
      || lower.contains("raw body")
      || lower.contains("naver")
      || lower.contains("kakao")
      || lower.contains("google");
  }

  private int existingReasonCount(Map<String, Object> payload) {
    Object reasons = payload.get("reasons");
    return reasons instanceof List<?> list ? Math.min(list.size(), MAX_REASON_COUNT) : 0;
  }

  private String sanitizeText(String value, int maxLength) {
    if (value == null) {
      return null;
    }
    String text = value.trim().replaceAll("\\s+", " ");
    if (text.isBlank()) {
      return null;
    }
    return text.length() <= maxLength ? text : text.substring(0, maxLength);
  }

  private String asString(Object value) {
    return value instanceof String text ? text : null;
  }

  private String stringOrDefault(String value, String fallback) {
    return value == null || value.isBlank() ? fallback : value;
  }

  private void putIfNotBlank(Map<String, Object> value, String key, String rawValue) {
    String text = sanitizeText(rawValue, 80);
    if (text != null) {
      value.put(key, text);
    }
  }
}
