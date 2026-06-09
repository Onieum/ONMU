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
@Table(name = "refresh_tokens")
public class RefreshTokenEntity {
  @Id
  private UUID id;

  @Column(name = "public_id", nullable = false)
  private String publicId;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "user_id", nullable = false)
  private UserEntity user;

  @Column(name = "token_family_id", nullable = false)
  private UUID tokenFamilyId;

  @Column(name = "token_hash", nullable = false)
  private String tokenHash;

  @Column(name = "previous_token_hash")
  private String previousTokenHash;

  @Column(name = "issued_at", nullable = false)
  private Instant issuedAt;

  @Column(name = "expires_at", nullable = false)
  private Instant expiresAt;

  @Column(name = "rotated_at")
  private Instant rotatedAt;

  @Column(name = "revoked_at")
  private Instant revokedAt;

  @Column(name = "revoked_reason")
  private String revokedReason;

  @Column(name = "created_by_ip")
  private String createdByIp;

  @Column(name = "created_by_user_agent")
  private String createdByUserAgent;

  protected RefreshTokenEntity() {
  }

  public RefreshTokenEntity(
    String publicId,
    UserEntity user,
    UUID tokenFamilyId,
    String tokenHash,
    String previousTokenHash,
    Instant issuedAt,
    Instant expiresAt,
    String createdByIp,
    String createdByUserAgent
  ) {
    this.id = UUID.randomUUID();
    this.publicId = Objects.requireNonNull(publicId);
    this.user = Objects.requireNonNull(user);
    this.tokenFamilyId = Objects.requireNonNull(tokenFamilyId);
    this.tokenHash = Objects.requireNonNull(tokenHash);
    this.previousTokenHash = previousTokenHash;
    this.issuedAt = Objects.requireNonNull(issuedAt);
    this.expiresAt = Objects.requireNonNull(expiresAt);
    this.createdByIp = createdByIp;
    this.createdByUserAgent = createdByUserAgent;
  }

  public UserEntity getUser() {
    return user;
  }

  public UUID getTokenFamilyId() {
    return tokenFamilyId;
  }

  public String getTokenHash() {
    return tokenHash;
  }

  public Instant getExpiresAt() {
    return expiresAt;
  }

  public Instant getRevokedAt() {
    return revokedAt;
  }

  public boolean isActive(Instant now) {
    return revokedAt == null && expiresAt.isAfter(now);
  }

  public void revoke(String reason) {
    this.revokedAt = Instant.now();
    this.revokedReason = reason;
  }

  public void markRotated() {
    this.rotatedAt = Instant.now();
    revoke("rotated");
  }
}
