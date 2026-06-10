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
@Table(name = "plans")
public class PlanEntity {
  @Id
  private UUID id;

  @Column(name = "public_id", nullable = false, unique = true)
  private String publicId;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "group_id", nullable = false)
  private GroupEntity group;

  @Column(nullable = false)
  private String title;

  @Column(name = "starts_at")
  private Instant startsAt;

  @Column(nullable = false)
  private String status;

  @Column(name = "created_at", insertable = false, updatable = false)
  private Instant createdAt;

  protected PlanEntity() {
  }

  public PlanEntity(String publicId, GroupEntity group, String title, Instant startsAt, String status) {
    this.id = UUID.randomUUID();
    this.publicId = publicId;
    this.group = group;
    this.title = title;
    this.startsAt = startsAt;
    this.status = status;
  }

  public void update(String title, Instant startsAt, String status) {
    this.title = title;
    this.startsAt = startsAt;
    this.status = status;
  }

  public UUID getId() {
    return id;
  }

  public String getPublicId() {
    return publicId;
  }

  public GroupEntity getGroup() {
    return group;
  }

  public String getTitle() {
    return title;
  }

  public Instant getStartsAt() {
    return startsAt;
  }

  public String getStatus() {
    return status;
  }

  public Instant getCreatedAt() {
    return createdAt;
  }
}
