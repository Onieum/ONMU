package com.onmu.api.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

@Entity
@Table(name = "user_devices")
public class UserDeviceEntity {
  @Id
  private UUID id;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "user_id", nullable = false)
  private UserEntity user;

  @Column(name = "device_fingerprint_hash")
  private String deviceFingerprintHash;

  @Column(nullable = false)
  private String platform;

  @Column(name = "app_version")
  private String appVersion;

  @Column(name = "os_version")
  private String osVersion;

  @Column(name = "device_label")
  private String deviceLabel;

  @Column(nullable = false)
  private String status;

  @Column(name = "last_seen_at")
  private Instant lastSeenAt;

  @Column(name = "updated_at")
  private Instant updatedAt;

  @Column(name = "push_provider")
  private String pushProvider;

  @Column(name = "push_token")
  private String pushToken;

  @Column(name = "push_token_hash")
  private String pushTokenHash;

  @Column(name = "push_token_last4")
  private String pushTokenLast4;

  @Column(name = "push_token_updated_at")
  private Instant pushTokenUpdatedAt;

  @Column(name = "push_token_disabled_at")
  private Instant pushTokenDisabledAt;

  protected UserDeviceEntity() {
  }

  public UserDeviceEntity(UserEntity user, String platform, Instant now) {
    this.id = UUID.randomUUID();
    this.user = Objects.requireNonNull(user);
    this.platform = Objects.requireNonNull(platform);
    this.status = "active";
    this.lastSeenAt = now;
    this.updatedAt = now;
  }

  public UUID getId() {
    return id;
  }

  public UserEntity getUser() {
    return user;
  }

  public String getDeviceFingerprintHash() {
    return deviceFingerprintHash;
  }

  public String getPlatform() {
    return platform;
  }

  public String getAppVersion() {
    return appVersion;
  }

  public String getOsVersion() {
    return osVersion;
  }

  public String getDeviceLabel() {
    return deviceLabel;
  }

  public String getStatus() {
    return status;
  }

  public String getPushProvider() {
    return pushProvider;
  }

  public String getPushToken() {
    return pushToken;
  }

  public String getPushTokenHash() {
    return pushTokenHash;
  }

  public String getPushTokenLast4() {
    return pushTokenLast4;
  }

  public Instant getPushTokenUpdatedAt() {
    return pushTokenUpdatedAt;
  }

  public Instant getPushTokenDisabledAt() {
    return pushTokenDisabledAt;
  }

  public Instant getUpdatedAt() {
    return updatedAt;
  }

  public void registerPushToken(
    String provider,
    String token,
    String tokenHash,
    String tokenLast4,
    String platform,
    String appVersion,
    String osVersion,
    String deviceLabel,
    String deviceFingerprintHash,
    Instant now
  ) {
    this.pushProvider = provider;
    this.pushToken = token;
    this.pushTokenHash = tokenHash;
    this.pushTokenLast4 = tokenLast4;
    this.platform = platform;
    this.appVersion = appVersion;
    this.osVersion = osVersion;
    this.deviceLabel = deviceLabel;
    this.deviceFingerprintHash = deviceFingerprintHash;
    this.status = "active";
    this.lastSeenAt = now;
    this.updatedAt = now;
    this.pushTokenUpdatedAt = now;
    this.pushTokenDisabledAt = null;
  }

  public void deactivatePushToken(Instant now) {
    this.status = "inactive";
    this.updatedAt = now;
    this.pushTokenDisabledAt = now;
  }
}
