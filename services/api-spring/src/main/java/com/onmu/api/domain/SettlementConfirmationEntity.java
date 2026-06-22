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
@Table(name = "settlement_confirmations")
public class SettlementConfirmationEntity {
  @Id
  private UUID id;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "settlement_transfer_id", nullable = false)
  private SettlementTransferEntity settlementTransfer;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "user_id", nullable = false)
  private UserEntity user;

  @Column(name = "confirmation_type", nullable = false)
  private String confirmationType;

  @Column(nullable = false)
  private String status;

  @Column(name = "confirmed_at", nullable = false)
  private Instant confirmedAt;

  private String memo;

  protected SettlementConfirmationEntity() {
  }

  public SettlementConfirmationEntity(
    SettlementTransferEntity settlementTransfer,
    UserEntity user,
    String confirmationType,
    String memo
  ) {
    this.id = UUID.randomUUID();
    this.settlementTransfer = settlementTransfer;
    this.user = user;
    this.confirmationType = confirmationType;
    this.status = "confirmed";
    this.confirmedAt = Instant.now();
    this.memo = memo;
  }

  public UUID getId() {
    return id;
  }

  public SettlementTransferEntity getSettlementTransfer() {
    return settlementTransfer;
  }

  public UserEntity getUser() {
    return user;
  }

  public String getConfirmationType() {
    return confirmationType;
  }

  public String getStatus() {
    return status;
  }

  public Instant getConfirmedAt() {
    return confirmedAt;
  }

  public String getMemo() {
    return memo;
  }
}
