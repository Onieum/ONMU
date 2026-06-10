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

@Entity
@Table(name = "plan_participants")
public class PlanParticipantEntity {
  @Id
  private UUID id;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "plan_id", nullable = false)
  private PlanEntity plan;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "user_id", nullable = false)
  private UserEntity user;

  @Column(nullable = false)
  private String status;

  @Column
  private String response;

  @Column(name = "joined_at")
  private Instant joinedAt;

  @Column(name = "created_at", insertable = false, updatable = false)
  private Instant createdAt;

  @Column(name = "updated_at", insertable = false, updatable = false)
  private Instant updatedAt;

  protected PlanParticipantEntity() {
  }

  public PlanParticipantEntity(PlanEntity plan, UserEntity user, String status, String response) {
    this.id = UUID.randomUUID();
    this.plan = plan;
    this.user = user;
    update(status, response);
  }

  public void update(String status, String response) {
    this.status = blankToDefault(status, "joined");
    this.response = blankToDefault(response, "accepted");
    this.joinedAt = "joined".equalsIgnoreCase(this.status) && this.joinedAt == null ? Instant.now() : this.joinedAt;
  }

  private String blankToDefault(String value, String fallback) {
    return value == null || value.isBlank() ? fallback : value.trim();
  }

  public UUID getId() {
    return id;
  }

  public PlanEntity getPlan() {
    return plan;
  }

  public UserEntity getUser() {
    return user;
  }

  public String getStatus() {
    return status;
  }

  public String getResponse() {
    return response;
  }

  public Instant getJoinedAt() {
    return joinedAt;
  }

  public Instant getCreatedAt() {
    return createdAt;
  }
}
