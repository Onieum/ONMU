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
@Table(name = "settlement_item_targets")
public class SettlementItemTargetEntity {
  @Id
  private UUID id;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "settlement_item_id", nullable = false)
  private SettlementItemEntity settlementItem;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "user_id", nullable = false)
  private UserEntity user;

  @Column(name = "amount_cents")
  private Long amountCents;

  @Column(nullable = false)
  private String status;

  @Column(name = "created_at", insertable = false, updatable = false)
  private Instant createdAt;

  protected SettlementItemTargetEntity() {
  }

  public SettlementItemTargetEntity(SettlementItemEntity settlementItem, UserEntity user, long amountCents) {
    this.id = UUID.randomUUID();
    this.settlementItem = settlementItem;
    this.user = user;
    this.amountCents = amountCents;
    this.status = "pending";
  }

  public UUID getId() {
    return id;
  }

  public SettlementItemEntity getSettlementItem() {
    return settlementItem;
  }

  public UserEntity getUser() {
    return user;
  }

  public Long getAmountCents() {
    return amountCents;
  }

  public String getStatus() {
    return status;
  }

  public Instant getCreatedAt() {
    return createdAt;
  }
}
