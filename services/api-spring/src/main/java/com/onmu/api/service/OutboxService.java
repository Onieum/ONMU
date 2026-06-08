package com.onmu.api.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.onmu.api.domain.OutboxEventEntity;
import com.onmu.api.domain.OutboxEventRepository;
import java.util.Map;
import java.util.UUID;
import org.springframework.stereotype.Service;

@Service
public class OutboxService {
  private final OutboxEventRepository outboxEventRepository;
  private final ObjectMapper objectMapper;

  public OutboxService(OutboxEventRepository outboxEventRepository, ObjectMapper objectMapper) {
    this.outboxEventRepository = outboxEventRepository;
    this.objectMapper = objectMapper;
  }

  public void record(String eventType, String aggregateType, UUID aggregateId, Map<String, Object> payload) {
    outboxEventRepository.save(new OutboxEventEntity(
      eventType,
      aggregateType,
      aggregateId,
      toJson(payload)
    ));
  }

  private String toJson(Map<String, Object> payload) {
    try {
      return objectMapper.writeValueAsString(payload);
    } catch (JsonProcessingException exception) {
      throw new IllegalStateException("Could not serialize outbox payload", exception);
    }
  }
}
