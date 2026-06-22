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
@Table(name = "settlements")
public class SettlementEntity {
  @Id
  private UUID id;

  @Column(name = "public_id", nullable = false, unique = true)
  private String publicId;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "group_id", nullable = false)
  private GroupEntity group;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "plan_id", nullable = false)
  private PlanEntity plan;

  @JdbcTypeCode(SqlTypes.JSON)
  @Column(columnDefinition = "jsonb", nullable = false)
  private String payload;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "created_by_user_id")
  private UserEntity createdByUser;

  @Column(nullable = false)
  private String status;

  @Column(name = "completed_at")
  private Instant completedAt;

  @Column(name = "created_at", insertable = false, updatable = false)
  private Instant createdAt;

  protected SettlementEntity() {
  }

  public SettlementEntity(String publicId, GroupEntity group, PlanEntity plan, String payload) {
    this.id = UUID.randomUUID();
    this.publicId = publicId;
    this.group = group;
    this.plan = plan;
    this.payload = payload;
    this.status = "finalized";
  }

  public UUID getId() {
    return id;
  }

  public String getPublicId() {
    return publicId;
  }

  public GroupEntity getGroup() {
    return group;
  }

  public PlanEntity getPlan() {
    return plan;
  }

  public String getPayload() {
    return payload;
  }

  public UserEntity getCreatedByUser() {
    return createdByUser;
  }

  public String getStatus() {
    return status == null || status.isBlank() ? "finalized" : status;
  }

  public Instant getCompletedAt() {
    return completedAt;
  }

  public void markCreatedBy(UserEntity user) {
    this.createdByUser = user;
  }

  public void markCompleted() {
    this.status = "completed";
    this.completedAt = Instant.now();
  }
}
