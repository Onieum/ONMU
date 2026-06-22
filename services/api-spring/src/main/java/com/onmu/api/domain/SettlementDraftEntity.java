package com.onmu.api.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.Version;
import java.time.Instant;
import java.util.UUID;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

@Entity
@Table(name = "settlement_drafts")
public class SettlementDraftEntity {
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

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "finalized_settlement_id")
  private SettlementEntity finalizedSettlement;

  @JdbcTypeCode(SqlTypes.JSON)
  @Column(columnDefinition = "jsonb", nullable = false)
  private String payload;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "created_by_user_id")
  private UserEntity createdByUser;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "updated_by_user_id")
  private UserEntity updatedByUser;

  @Column(nullable = false)
  private String status;

  @Version
  @Column(nullable = false)
  private long version;

  @Column(name = "updated_at", insertable = false)
  private Instant updatedAt;

  protected SettlementDraftEntity() {
  }

  public SettlementDraftEntity(String publicId, GroupEntity group, PlanEntity plan, String payload) {
    this.id = UUID.randomUUID();
    this.publicId = publicId;
    this.group = group;
    this.plan = plan;
    this.payload = payload;
    this.status = "draft";
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

  public void setPayload(String payload) {
    this.payload = payload;
  }

  public SettlementEntity getFinalizedSettlement() {
    return finalizedSettlement;
  }

  public UserEntity getCreatedByUser() {
    return createdByUser;
  }

  public UserEntity getUpdatedByUser() {
    return updatedByUser;
  }

  public String getStatus() {
    return status == null || status.isBlank() ? "draft" : status;
  }

  public long getVersion() {
    return version;
  }

  public Instant getUpdatedAt() {
    return updatedAt;
  }

  public void markCreatedBy(UserEntity user) {
    this.createdByUser = user;
    this.updatedByUser = user;
  }

  public void markUpdatedBy(UserEntity user) {
    this.updatedByUser = user;
  }

  public void markFinalized(SettlementEntity settlement) {
    this.status = "finalized";
    this.finalizedSettlement = settlement;
  }
}
