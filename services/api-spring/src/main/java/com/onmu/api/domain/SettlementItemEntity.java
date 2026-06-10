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
@Table(name = "settlement_items")
public class SettlementItemEntity {
  @Id
  private UUID id;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "settlement_draft_id")
  private SettlementDraftEntity settlementDraft;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "settlement_id")
  private SettlementEntity settlement;

  @Column(name = "public_id", nullable = false, unique = true)
  private String publicId;

  @Column(nullable = false)
  private String title;

  @Column(name = "amount_cents", nullable = false)
  private long amountCents;

  @Column(nullable = false)
  private String currency;

  @Column(name = "split_type", nullable = false)
  private String splitType;

  private String memo;

  @Column(name = "created_at", insertable = false, updatable = false)
  private Instant createdAt;

  @Column(name = "updated_at", insertable = false, updatable = false)
  private Instant updatedAt;

  protected SettlementItemEntity() {
  }

  public SettlementItemEntity(
    SettlementDraftEntity settlementDraft,
    SettlementEntity settlement,
    String publicId,
    String title,
    long amountCents,
    String splitType,
    String memo
  ) {
    this.id = UUID.randomUUID();
    this.settlementDraft = settlementDraft;
    this.settlement = settlement;
    this.publicId = publicId;
    this.title = title;
    this.amountCents = amountCents;
    this.currency = "KRW";
    this.splitType = splitType;
    this.memo = memo;
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

  public String getTitle() {
    return title;
  }

  public long getAmountCents() {
    return amountCents;
  }

  public String getCurrency() {
    return currency;
  }

  public String getSplitType() {
    return splitType;
  }

  public String getMemo() {
    return memo;
  }

  public Instant getCreatedAt() {
    return createdAt;
  }

  public void setTitle(String title) {
    this.title = title;
  }

  public void setAmountCents(long amountCents) {
    this.amountCents = amountCents;
  }

  public void setSplitType(String splitType) {
    this.splitType = splitType;
  }

  public void setMemo(String memo) {
    this.memo = memo;
  }
}
