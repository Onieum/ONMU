package com.onmu.api.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.onmu.api.domain.OutboxEventEntity;
import com.onmu.api.domain.OutboxEventRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestTemplate;
import java.time.Instant;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Service
public class OutboxService {
  private static final Logger log = LoggerFactory.getLogger(OutboxService.class);

  private final OutboxEventRepository outboxEventRepository;
  private final NotificationDeliveryService notificationDeliveryService;
  private final OotdAvatarGenerationCompletionService ootdAvatarGenerationCompletionService;
  private final ObjectMapper objectMapper;
  private final String workerUrl;
  private final RestTemplate restTemplate;

  public OutboxService(
    OutboxEventRepository outboxEventRepository,
    NotificationDeliveryService notificationDeliveryService,
    OotdAvatarGenerationCompletionService ootdAvatarGenerationCompletionService,
    ObjectMapper objectMapper,
    @Value("${ONMU_WORKER_URL:http://localhost:8090/tasks/ootd}") String workerUrl,
    @Value("${ONMU_WORKER_CONNECT_TIMEOUT_MS:5000}") int workerConnectTimeoutMs,
    @Value("${ONMU_WORKER_READ_TIMEOUT_MS:180000}") int workerReadTimeoutMs
  ) {
    this.outboxEventRepository = outboxEventRepository;
    this.notificationDeliveryService = notificationDeliveryService;
    this.ootdAvatarGenerationCompletionService = ootdAvatarGenerationCompletionService;
    this.objectMapper = objectMapper;
    this.workerUrl = workerUrl;
    
    SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
    factory.setConnectTimeout(workerConnectTimeoutMs);
    factory.setReadTimeout(workerReadTimeoutMs);
    this.restTemplate = new RestTemplate(factory);
  }

  public void record(String eventType, String aggregateType, UUID aggregateId, Map<String, Object> payload) {
    outboxEventRepository.save(new OutboxEventEntity(
      eventType,
      aggregateType,
      aggregateId,
      toJson(payload)
    ));
    if ("ootd.avatar_generation.requested".equals(eventType)) {
      log.info(
        "ootd outbox event recorded eventType={} aggregateType={} aggregateId={}",
        eventType,
        aggregateType,
        aggregateId
      );
    }
  }

  @Transactional
  @Scheduled(fixedDelay = 5000)
  public void publishPendingEvents() {
    List<OutboxEventEntity> pendingEvents = outboxEventRepository.findByStatusOrderByCreatedAtAsc("pending");
    for (OutboxEventEntity event : pendingEvents) {
      String eventType = event.getEventType();
      if ("notification.requested".equals(eventType)) {
        NotificationDeliveryOutcome outcome = notificationDeliveryService.processRequested(event, readMap(event.getPayload()));
        event.setStatus(outcome.outboxStatus());
        event.setPublishedAt(Instant.now());
        event.setLastError(outcome.lastError());
        outboxEventRepository.save(event);
        continue;
      }

      boolean hasConsumer = "record.created".equals(eventType) 
          || "place_candidate.created".equals(eventType) 
          || "ai.summary.requested".equals(eventType)
          || "ootd.avatar_generation.requested".equals(eventType);

      if (!hasConsumer) {
        event.setStatus("no_consumer");
        outboxEventRepository.save(event);
        continue;
      }

      event.setLockedAt(Instant.now());
      outboxEventRepository.saveAndFlush(event);

      try {
        Map<String, Object> requestBody = new LinkedHashMap<>();
        requestBody.put("eventId", event.getId().toString());
        requestBody.put("eventType", event.getEventType());
        requestBody.put("payload", readMap(event.getPayload()));

        if ("ootd.avatar_generation.requested".equals(event.getEventType())) {
          log.info(
            "ootd outbox dispatching eventId={} aggregateId={} retryCount={} workerUrl={}",
            event.getId(),
            event.getAggregateId(),
            event.getRetryCount() + 1,
            workerUrl
          );
        }
        ResponseEntity<String> response = restTemplate.postForEntity(workerUrl, requestBody, String.class);
        if ("ootd.avatar_generation.requested".equals(event.getEventType())) {
          ootdAvatarGenerationCompletionService.completeFromWorkerResponse(event.getAggregateId(), response.getBody());
          log.info(
            "ootd outbox dispatched eventId={} aggregateId={} statusCode={} responseBytes={}",
            event.getId(),
            event.getAggregateId(),
            response.getStatusCode().value(),
            response.getBody() == null ? 0 : response.getBody().length()
          );
        }

        event.setStatus("published");
        event.setPublishedAt(Instant.now());
        event.setLastError(null);
      } catch (Exception e) {
        int nextRetry = event.getRetryCount() + 1;
        event.setRetryCount(nextRetry);
        event.setLastError(e.getMessage());
        if ("ootd.avatar_generation.requested".equals(event.getEventType())) {
          log.warn(
            "ootd outbox dispatch failed eventId={} aggregateId={} retryCount={} errorType={} message={}",
            event.getId(),
            event.getAggregateId(),
            nextRetry,
            e.getClass().getSimpleName(),
            e.getMessage()
          );
        }
        if (nextRetry >= 3) {
          event.setStatus("failed");
        } else {
          event.setStatus("pending");
        }
      }
      outboxEventRepository.save(event);
    }
  }

  @Transactional
  @Scheduled(fixedDelay = 60000)
  public void recoverFailedEvents() {
    List<OutboxEventEntity> failedEvents = outboxEventRepository.findByStatusOrderByCreatedAtAsc("failed");
    Instant oneMinuteAgo = Instant.now().minusSeconds(60);
    for (OutboxEventEntity event : failedEvents) {
      if (event.getLockedAt() != null && event.getLockedAt().isBefore(oneMinuteAgo)) {
        event.setStatus("pending");
        event.setRetryCount(0);
        event.setLockedAt(null);
        event.setLastError(null);
        outboxEventRepository.save(event);
      }
    }
  }

  private String toJson(Map<String, Object> payload) {
    try {
      return objectMapper.writeValueAsString(payload);
    } catch (JsonProcessingException exception) {
      throw new IllegalStateException("Could not serialize outbox payload", exception);
    }
  }

  private Map<String, Object> readMap(String json) {
    try {
      return objectMapper.readValue(json, Map.class);
    } catch (Exception e) {
      return Collections.emptyMap();
    }
  }
}
