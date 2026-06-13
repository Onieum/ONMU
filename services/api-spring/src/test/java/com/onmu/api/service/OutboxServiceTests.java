package com.onmu.api.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.onmu.api.domain.OutboxEventEntity;
import com.onmu.api.domain.OutboxEventRepository;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class OutboxServiceTests {
  @Mock
  private OutboxEventRepository outboxEventRepository;

  private OutboxService service;

  @BeforeEach
  void setUp() {
    service = new OutboxService(
      outboxEventRepository,
      new ObjectMapper(),
      "http://localhost:8090/tasks/ootd"
    );
  }

  @Test
  void recoverFailedEventsResetsOldFailedEvents() {
    OutboxEventEntity oldFailedEvent = new OutboxEventEntity(
      "record.created",
      "record",
      UUID.randomUUID(),
      "{}"
    );
    oldFailedEvent.setStatus("failed");
    oldFailedEvent.setRetryCount(3);
    oldFailedEvent.setLockedAt(Instant.now().minusSeconds(70)); // > 1 minute ago
    oldFailedEvent.setLastError("Connection timeout");

    OutboxEventEntity recentFailedEvent = new OutboxEventEntity(
      "record.created",
      "record",
      UUID.randomUUID(),
      "{}"
    );
    recentFailedEvent.setStatus("failed");
    recentFailedEvent.setRetryCount(3);
    recentFailedEvent.setLockedAt(Instant.now().minusSeconds(10)); // < 1 minute ago
    recentFailedEvent.setLastError("Connection timeout");

    when(outboxEventRepository.findByStatusOrderByCreatedAtAsc("failed"))
      .thenReturn(List.of(oldFailedEvent, recentFailedEvent));

    service.recoverFailedEvents();

    // Old failed event should be recovered
    assertThat(oldFailedEvent.getStatus()).isEqualTo("pending");
    assertThat(oldFailedEvent.getRetryCount()).isEqualTo(0);
    assertThat(oldFailedEvent.getLockedAt()).isNull();
    assertThat(oldFailedEvent.getLastError()).isNull();
    verify(outboxEventRepository).save(oldFailedEvent);

    // Recent failed event should remain failed
    assertThat(recentFailedEvent.getStatus()).isEqualTo("failed");
    assertThat(recentFailedEvent.getRetryCount()).isEqualTo(3);
    assertThat(recentFailedEvent.getLockedAt()).isNotNull();
    assertThat(recentFailedEvent.getLastError()).isEqualTo("Connection timeout");
  }

  @Test
  void chatMessageOutboxHasNoExternalConsumerInThisSlice() {
    OutboxEventEntity chatMessageEvent = new OutboxEventEntity(
      "chat.message",
      "chat_activity_event",
      UUID.randomUUID(),
      "{}"
    );
    when(outboxEventRepository.findByStatusOrderByCreatedAtAsc("pending"))
      .thenReturn(List.of(chatMessageEvent));

    service.publishPendingEvents();

    assertThat(chatMessageEvent.getStatus()).isEqualTo("no_consumer");
    verify(outboxEventRepository).save(chatMessageEvent);
  }
}
