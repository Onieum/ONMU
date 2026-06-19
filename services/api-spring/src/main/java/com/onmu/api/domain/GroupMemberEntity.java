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
@Table(name = "group_members")
public class GroupMemberEntity {
  @Id
  private UUID id;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "group_id", nullable = false)
  private GroupEntity group;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "user_id", nullable = false)
  private UserEntity user;

  @Column(nullable = false)
  private String role;

  @Column(name = "name_override")
  private String nameOverride;

  @Column(nullable = false)
  private String status;

  @Column(name = "joined_at", insertable = false, updatable = false)
  private Instant joinedAt;

  @Column(name = "left_at")
  private Instant leftAt;

  @Column(name = "created_at", insertable = false, updatable = false)
  private Instant createdAt;

  @Column(name = "updated_at", insertable = false, updatable = false)
  private Instant updatedAt;

  protected GroupMemberEntity() {
  }

  public GroupMemberEntity(GroupEntity group, UserEntity user, String role, String status) {
    this.id = UUID.randomUUID();
    this.group = group;
    this.user = user;
    this.role = role;
    this.status = status;
  }

  public void markLeft() {
    if ("left".equals(status)) {
      return;
    }
    status = "left";
    leftAt = Instant.now();
  }

  public void markActive() {
    status = "active";
    leftAt = null;
  }

  public UUID getId() {
    return id;
  }

  public GroupEntity getGroup() {
    return group;
  }

  public UserEntity getUser() {
    return user;
  }

  public String getRole() {
    return role;
  }

  public String getNameOverride() {
    return nameOverride;
  }

  public String getStatus() {
    return status;
  }

  public Instant getJoinedAt() {
    return joinedAt;
  }

  public Instant getLeftAt() {
    return leftAt;
  }

  public Instant getCreatedAt() {
    return createdAt;
  }

  public Instant getUpdatedAt() {
    return updatedAt;
  }
}
