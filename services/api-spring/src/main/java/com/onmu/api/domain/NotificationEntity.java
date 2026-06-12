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
@Table(name = "notifications")
public class NotificationEntity {
  @Id
  private UUID id;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "user_id", nullable = false)
  private UserEntity user;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "group_id")
  private GroupEntity group;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "plan_id")
  private PlanEntity plan;

  @Column(name = "notification_type", nullable = false)
  private String notificationType;

  @Column(nullable = false)
  private String title;

  @Column
  private String body;

  @JdbcTypeCode(SqlTypes.JSON)
  @Column(columnDefinition = "jsonb", nullable = false)
  private String payload;

  @Column(nullable = false)
  private String status;

  @Column(name = "read_at")
  private Instant readAt;

  @Column(name = "created_at", nullable = false)
  private Instant createdAt;

  protected NotificationEntity() {
  }

  public NotificationEntity(
    UserEntity user,
    GroupEntity group,
    PlanEntity plan,
    String notificationType,
    String title,
    String body,
    String payload,
    String status,
    Instant readAt,
    Instant createdAt
  ) {
    this.id = UUID.randomUUID();
    this.user = user;
    this.group = group;
    this.plan = plan;
    this.notificationType = notificationType;
    this.title = title;
    this.body = body;
    this.payload = payload;
    this.status = status;
    this.readAt = readAt;
    this.createdAt = createdAt;
  }

  public UUID getId() {
    return id;
  }

  public UserEntity getUser() {
    return user;
  }

  public GroupEntity getGroup() {
    return group;
  }

  public PlanEntity getPlan() {
    return plan;
  }

  public String getNotificationType() {
    return notificationType;
  }

  public String getTitle() {
    return title;
  }

  public String getBody() {
    return body;
  }

  public String getPayload() {
    return payload;
  }

  public String getStatus() {
    return status;
  }

  public Instant getReadAt() {
    return readAt;
  }

  public Instant getCreatedAt() {
    return createdAt;
  }
}
