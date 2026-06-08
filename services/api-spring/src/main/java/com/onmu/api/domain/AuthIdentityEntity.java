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
@Table(name = "auth_identities")
public class AuthIdentityEntity {
  @Id
  private UUID id;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "user_id", nullable = false)
  private UserEntity user;

  @Column(nullable = false)
  private String provider;

  @Column(name = "provider_subject", nullable = false)
  private String providerSubject;

  @Column(name = "created_at", insertable = false, updatable = false)
  private Instant createdAt;

  protected AuthIdentityEntity() {
  }

  public UUID getId() {
    return id;
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

  public Instant getCreatedAt() {
    return createdAt;
  }
}
