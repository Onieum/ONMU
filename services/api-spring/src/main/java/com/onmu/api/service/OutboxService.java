package com.onmu.api.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.onmu.api.domain.OutboxEventEntity;
import com.onmu.api.domain.OutboxEventRepository;
import org.springframework.beans.factory.annotation.Value;
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

@Service
public class OutboxService {
  private final OutboxEventRepository outboxEventRepository;
  private final ObjectMapper objectMapper;
  private final String workerUrl;
  private final RestTemplate restTemplate;

  public OutboxService(
      OutboxEventRepository outboxEventRepository, 
      ObjectMapper objectMapper,
      @Value("${ONMU_WORKER_URL:http://localhost:8090/tasks/ootd}") String workerUrl
  ) {
    this.outboxEventRepository = outboxEventRepository;
    this.objectMapper = objectMapper;
    this.workerUrl = workerUrl;
    
    SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
    factory.setConnectTimeout(3000);
    factory.setReadTimeout(3000);
    this.restTemplate = new RestTemplate(factory);
  }

  public void record(String eventType, String aggregateType, UUID aggregateId, Map<String, Object> payload) {
    outboxEventRepository.save(new OutboxEventEntity(
      eventType,
      aggregateType,
      aggregateId,
      toJson(payload)
    ));
  }

  @Transactional
  @Scheduled(fixedDelay = 5000)
  public void publishPendingEvents() {
    List<OutboxEventEntity> pendingEvents = outboxEventRepository.findByStatusOrderByCreatedAtAsc("pending");
    for (OutboxEventEntity event : pendingEvents) {
      String eventType = event.getEventType();
      boolean hasConsumer = "record.created".equals(eventType) 
          || "place_candidate.created".equals(eventType) 
          || "ai.summary.requested".equals(eventType);

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

        restTemplate.postForEntity(workerUrl, requestBody, String.class);

        event.setStatus("published");
        event.setPublishedAt(Instant.now());
        event.setLastError(null);
      } catch (Exception e) {
        int nextRetry = event.getRetryCount() + 1;
        event.setRetryCount(nextRetry);
        event.setLastError(e.getMessage());
        if (nextRetry >= 3) {
          event.setStatus("failed");
        } else {
          event.setStatus("pending");
        }
      }
      outboxEventRepository.save(event);
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
