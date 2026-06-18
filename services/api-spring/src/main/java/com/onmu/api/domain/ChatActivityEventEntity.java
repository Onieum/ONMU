package com.onmu.api.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

@Entity
@Table(name = "chat_activity_events")
public class ChatActivityEventEntity {
  @Id
  private UUID id;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "group_id")
  private GroupEntity group;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "plan_id")
  private PlanEntity plan;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "actor_user_id")
  private UserEntity actorUser;

  @Column(name = "event_type", nullable = false)
  private String eventType;

  @JdbcTypeCode(SqlTypes.JSON)
  @Column(columnDefinition = "jsonb", nullable = false)
  private String payload;

  @Column(name = "created_at", nullable = false)
  private Instant createdAt;

  protected ChatActivityEventEntity() {
  }

  public ChatActivityEventEntity(
    GroupEntity group,
    UserEntity actorUser,
    String eventType,
    String payload
  ) {
    this(group, actorUser, eventType, payload, Instant.now());
  }

  public ChatActivityEventEntity(
    GroupEntity group,
    UserEntity actorUser,
    String eventType,
    String payload,
    Instant createdAt
  ) {
    this(group, null, actorUser, eventType, payload, createdAt);
  }

  public ChatActivityEventEntity(
    GroupEntity group,
    PlanEntity plan,
    UserEntity actorUser,
    String eventType,
    String payload,
    Instant createdAt
  ) {
    this.id = UUID.randomUUID();
    this.group = group;
    this.plan = plan;
    this.actorUser = actorUser;
    this.eventType = eventType;
    this.payload = payload;
    this.createdAt = createdAt;
  }

  public UUID getId() {
    return id;
  }

  public GroupEntity getGroup() {
    return group;
  }

  public PlanEntity getPlan() {
    return plan;
  }

  public UserEntity getActorUser() {
    return actorUser;
  }

  public String getEventType() {
    return eventType;
  }

  public String getPayload() {
    return payload;
  }

  public Instant getCreatedAt() {
    return createdAt;
  }
}
