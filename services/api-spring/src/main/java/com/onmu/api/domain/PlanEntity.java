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
  public static final String DEFAULT_STATUS = "scheduled";

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

  @Column(name = "ends_at")
  private Instant endsAt;

  @Column
  private String description;

  @Column(name = "location_note")
  private String locationNote;

  @Column(nullable = false)
  private String status;

  @Column(name = "created_at", insertable = false, updatable = false)
  private Instant createdAt;

  protected PlanEntity() {
  }

  public PlanEntity(String publicId, GroupEntity group, String title, Instant startsAt, String status) {
    this(publicId, group, title, startsAt, null, status, null, null);
  }

  public PlanEntity(
    String publicId,
    GroupEntity group,
    String title,
    Instant startsAt,
    Instant endsAt,
    String status,
    String description,
    String locationNote
  ) {
    this.id = UUID.randomUUID();
    this.publicId = publicId;
    this.group = group;
    this.title = title;
    this.startsAt = startsAt;
    this.endsAt = endsAt;
    this.status = normalizeStatus(status);
    this.description = description;
    this.locationNote = locationNote;
  }

  public void update(String title, Instant startsAt, Instant endsAt, String status, String description, String locationNote) {
    this.title = title;
    this.startsAt = startsAt;
    this.endsAt = endsAt;
    this.status = normalizeStatus(status);
    this.description = description;
    this.locationNote = locationNote;
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

  public Instant getEndsAt() {
    return endsAt;
  }

  public String getDescription() {
    return description;
  }

  public String getLocationNote() {
    return locationNote;
  }

  public String getStatus() {
    return normalizeStoredStatus(status);
  }

  public Instant getCreatedAt() {
    return createdAt;
  }

  public static String normalizeStatus(String status) {
    if (status == null || status.isBlank()) {
      return DEFAULT_STATUS;
    }
    String normalized = status.trim().toLowerCase();
    return switch (normalized) {
      case "scheduled", "active", "completed", "cancelled" -> normalized;
      default -> throw new IllegalArgumentException("invalid_plan_status");
    };
  }

  public static String normalizeStoredStatus(String status) {
    if (status == null || status.isBlank()) {
      return DEFAULT_STATUS;
    }
    String normalized = status.trim().toLowerCase();
    return switch (normalized) {
      case "confirmed" -> DEFAULT_STATUS;
      default -> normalizeStatus(normalized);
    };
  }
}
