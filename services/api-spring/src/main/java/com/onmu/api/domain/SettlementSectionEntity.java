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
@Table(name = "settlement_sections")
public class SettlementSectionEntity {
  @Id
  private UUID id;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "settlement_draft_id")
  private SettlementDraftEntity settlementDraft;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "settlement_id")
  private SettlementEntity settlement;

  @Column(name = "public_id", nullable = false)
  private String publicId;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "schedule_place_id")
  private SchedulePlaceEntity schedulePlace;

  @Column(nullable = false)
  private String title;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "payer_user_id")
  private UserEntity payerUser;

  @Column(name = "sort_order", nullable = false)
  private int sortOrder;

  @Column(name = "created_at", insertable = false, updatable = false)
  private Instant createdAt;

  protected SettlementSectionEntity() {
  }

  public SettlementSectionEntity(
    SettlementDraftEntity settlementDraft,
    SettlementEntity settlement,
    String publicId,
    SchedulePlaceEntity schedulePlace,
    String title,
    UserEntity payerUser,
    int sortOrder
  ) {
    this.id = UUID.randomUUID();
    this.settlementDraft = settlementDraft;
    this.settlement = settlement;
    this.publicId = publicId;
    this.schedulePlace = schedulePlace;
    this.title = title;
    this.payerUser = payerUser;
    this.sortOrder = sortOrder;
  }

  public UUID getId() {
    return id;
  }

  public SettlementDraftEntity getSettlementDraft() {
    return settlementDraft;
  }

  public SettlementEntity getSettlement() {
    return settlement;
  }

  public String getPublicId() {
    return publicId;
  }

  public SchedulePlaceEntity getSchedulePlace() {
    return schedulePlace;
  }

  public String getTitle() {
    return title;
  }

  public UserEntity getPayerUser() {
    return payerUser;
  }

  public int getSortOrder() {
    return sortOrder;
  }

  public Instant getCreatedAt() {
    return createdAt;
  }
}
