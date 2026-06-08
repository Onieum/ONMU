package com.onmu.api.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

@Entity
@Table(name = "outbox_events")
public class OutboxEventEntity {
  @Id
  private UUID id;

  @Column(name = "event_type", nullable = false)
  private String eventType;

  @Column(name = "aggregate_type", nullable = false)
  private String aggregateType;

  @Column(name = "aggregate_id")
  private UUID aggregateId;

  @JdbcTypeCode(SqlTypes.JSON)
  @Column(columnDefinition = "jsonb", nullable = false)
  private String payload;

  @Column(nullable = false)
  private String status;

  @Column(name = "created_at", insertable = false, updatable = false)
  private Instant createdAt;

  protected OutboxEventEntity() {
  }

  public OutboxEventEntity(String eventType, String aggregateType, UUID aggregateId, String payload) {
    this.id = UUID.randomUUID();
    this.eventType = eventType;
    this.aggregateType = aggregateType;
    this.aggregateId = aggregateId;
    this.payload = payload;
    this.status = "no_consumer";
  }

  public UUID getId() {
    return id;
  }

  public String getStatus() {
    return status;
  }
}
