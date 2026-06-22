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
@Table(name = "settlement_transfers")
public class SettlementTransferEntity {
  @Id
  private UUID id;

  @Column(name = "public_id", nullable = false, unique = true)
  private String publicId;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "settlement_id", nullable = false)
  private SettlementEntity settlement;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "from_user_id", nullable = false)
  private UserEntity fromUser;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "to_user_id", nullable = false)
  private UserEntity toUser;

  @Column(name = "amount_won", nullable = false)
  private long amountWon;

  @Column(nullable = false)
  private String currency;

  @Column(nullable = false)
  private String status;

  private String memo;

  @Column(name = "created_at", insertable = false, updatable = false)
  private Instant createdAt;

  protected SettlementTransferEntity() {
  }

  public SettlementTransferEntity(
    SettlementEntity settlement,
    UserEntity fromUser,
    UserEntity toUser,
    long amountWon,
    String memo
  ) {
    this.id = UUID.randomUUID();
    this.publicId = "stlt_" + this.id.toString().replace("-", "");
    this.settlement = settlement;
    this.fromUser = fromUser;
    this.toUser = toUser;
    this.amountWon = amountWon;
    this.currency = "KRW";
    this.status = "pending";
    this.memo = memo;
  }

  public UUID getId() {
    return id;
  }

  public String getPublicId() {
    return publicId;
  }

  public SettlementEntity getSettlement() {
    return settlement;
  }

  public UserEntity getFromUser() {
    return fromUser;
  }

  public UserEntity getToUser() {
    return toUser;
  }

  public long getAmountWon() {
    return amountWon;
  }

  public String getStatus() {
    return status;
  }

  public String getMemo() {
    return memo;
  }

  public Instant getCreatedAt() {
    return createdAt;
  }

  public void markSent() {
    if (!"received".equals(status)) {
      status = "sent";
    }
  }

  public void markReceived() {
    status = "received";
  }
}
