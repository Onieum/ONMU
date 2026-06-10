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
@Table(name = "auth_identities")
public class AuthIdentityEntity {
  @Id
  private UUID id;

  @Column(name = "public_id", nullable = false)
  private String publicId;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "user_id", nullable = false)
  private UserEntity user;

  @Column(nullable = false)
  private String provider;

  @Column(name = "provider_subject", nullable = false)
  private String providerSubject;

  @Column(name = "provider_email")
  private String providerEmail;

  @Column(name = "created_at", insertable = false, updatable = false)
  private Instant createdAt;

  @Column(name = "last_verified_at")
  private Instant lastVerifiedAt;

  @Column(name = "deleted_at")
  private Instant deletedAt;

  protected AuthIdentityEntity() {
  }

  public AuthIdentityEntity(
    String publicId,
    UserEntity user,
    String provider,
    String providerSubject,
    String providerEmail
  ) {
    this.id = UUID.randomUUID();
    this.publicId = Objects.requireNonNull(publicId);
    this.user = Objects.requireNonNull(user);
    this.provider = Objects.requireNonNull(provider);
    this.providerSubject = Objects.requireNonNull(providerSubject);
    this.providerEmail = providerEmail;
    this.lastVerifiedAt = Instant.now();
  }

  public UUID getId() {
    return id;
  }

  public String getPublicId() {
    return publicId;
  }

  public UserEntity getUser() {
    return user;
  }

  public String getProvider() {
    return provider;
  }

  public String getProviderSubject() {
    return providerSubject;
  }

  public String getProviderEmail() {
    return providerEmail;
  }

  public Instant getCreatedAt() {
    return createdAt;
  }

  public Instant getLastVerifiedAt() {
    return lastVerifiedAt;
  }

  public Instant getDeletedAt() {
    return deletedAt;
  }

  public void recordLogin(String providerEmail) {
    this.providerEmail = providerEmail;
    this.lastVerifiedAt = Instant.now();
  }
}
