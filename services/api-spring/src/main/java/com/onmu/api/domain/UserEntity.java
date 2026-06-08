package com.onmu.api.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "users")
public class UserEntity {
  @Id
  private UUID id;

  @Column(name = "display_name", nullable = false)
  private String displayName;

  @Column(name = "created_at", insertable = false, updatable = false)
  private Instant createdAt;

  protected UserEntity() {
  }

  public UUID getId() {
    return id;
  }

  public String getDisplayName() {
    return displayName;
  }

  public Instant getCreatedAt() {
    return createdAt;
  }
}
