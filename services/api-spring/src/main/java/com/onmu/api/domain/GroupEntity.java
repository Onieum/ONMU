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
@Table(name = "groups")
public class GroupEntity {
  @Id
  private UUID id;

  @Column(name = "public_id", nullable = false, unique = true)
  private String publicId;

  @Column(nullable = false)
  private String name;

  @Column(name = "description")
  private String description;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "owner_user_id")
  private UserEntity ownerUser;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "updated_by_user_id")
  private UserEntity updatedByUser;

  @Column(name = "created_at", insertable = false, updatable = false)
  private Instant createdAt;

  protected GroupEntity() {
  }

  public GroupEntity(String publicId, String name, UserEntity ownerUser) {
    this.id = UUID.randomUUID();
    this.publicId = publicId;
    this.name = name;
    this.ownerUser = ownerUser;
  }

  public void update(String name, String description, UserEntity updatedByUser) {
    this.name = name.trim();
    this.description = blankToNull(description);
    this.updatedByUser = updatedByUser;
  }

  private String blankToNull(String value) {
    if (value == null || value.isBlank()) {
      return null;
    }
    return value.trim();
  }

  public UUID getId() {
    return id;
  }

  public String getPublicId() {
    return publicId;
  }

  public String getName() {
    return name;
  }

  public String getDescription() {
    return description;
  }

  public UserEntity getOwnerUser() {
    return ownerUser;
  }

  public Instant getCreatedAt() {
    return createdAt;
  }
}
