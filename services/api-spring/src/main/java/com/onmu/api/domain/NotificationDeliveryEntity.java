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
@Table(name = "notification_deliveries")
public class NotificationDeliveryEntity {
  @Id
  private UUID id;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "notification_id", nullable = false)
  private NotificationEntity notification;

  @Column(nullable = false)
  private String channel;

  @Column
  private String provider;

  @Column(nullable = false)
  private String status;

  @Column(name = "provider_message_id")
  private String providerMessageId;

  @Column(name = "error_message")
  private String errorMessage;

  @Column(name = "attempted_at", nullable = false)
  private Instant attemptedAt;

  @Column(name = "delivered_at")
  private Instant deliveredAt;

  protected NotificationDeliveryEntity() {
  }

  public NotificationDeliveryEntity(
    NotificationEntity notification,
    String channel,
    String provider,
    Instant attemptedAt
  ) {
    this.id = UUID.randomUUID();
    this.notification = notification;
    this.channel = channel;
    this.provider = provider;
    this.status = "pending";
    this.attemptedAt = attemptedAt;
  }

  public NotificationEntity getNotification() {
    return notification;
  }

  public String getChannel() {
    return channel;
  }

  public String getProvider() {
    return provider;
  }

  public String getStatus() {
    return status;
  }

  public String getProviderMessageId() {
    return providerMessageId;
  }

  public String getErrorMessage() {
    return errorMessage;
  }

  public Instant getAttemptedAt() {
    return attemptedAt;
  }

  public Instant getDeliveredAt() {
    return deliveredAt;
  }

  public void apply(NotificationDeliveryResult result, Instant attemptedAt) {
    this.provider = result.provider();
    this.status = result.status();
    this.providerMessageId = result.providerMessageId();
    this.errorMessage = result.errorMessage();
    this.deliveredAt = result.deliveredAt();
    this.attemptedAt = attemptedAt;
  }
}
