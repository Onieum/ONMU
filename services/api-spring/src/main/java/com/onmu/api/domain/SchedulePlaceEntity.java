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
@Table(name = "schedule_places")
public class SchedulePlaceEntity {
  @Id
  private UUID id;

  @Column(name = "public_id", nullable = false, unique = true)
  private String publicId;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "group_id", nullable = false)
  private GroupEntity group;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "plan_id", nullable = false)
  private PlanEntity plan;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "place_candidate_id")
  private PlaceCandidateEntity placeCandidate;

  @Column(nullable = false)
  private String name;

  @Column(name = "starts_at")
  private Instant startsAt;

  @Column(name = "ends_at")
  private Instant endsAt;

  @Column(name = "sort_order", nullable = false)
  private int sortOrder;

  @Column
  private String note;

  protected SchedulePlaceEntity() {
  }

  public SchedulePlaceEntity(
    String publicId,
    GroupEntity group,
    PlanEntity plan,
    PlaceCandidateEntity placeCandidate,
    String name,
    Instant startsAt,
    Instant endsAt,
    int sortOrder,
    String note
  ) {
    this.id = UUID.randomUUID();
    this.publicId = publicId;
    this.group = group;
    this.plan = plan;
    this.placeCandidate = placeCandidate;
    this.name = name;
    this.startsAt = startsAt;
    this.endsAt = endsAt;
    this.sortOrder = sortOrder;
    this.note = note;
  }

  public SchedulePlaceEntity(
    String publicId,
    GroupEntity group,
    PlanEntity plan,
    PlaceCandidateEntity placeCandidate,
    String name,
    Instant startsAt,
    int sortOrder
  ) {
    this(publicId, group, plan, placeCandidate, name, startsAt, null, sortOrder, null);
  }

  public UUID getId() {
    return id;
  }

  public String getPublicId() {
    return publicId;
  }

  public PlaceCandidateEntity getPlaceCandidate() {
    return placeCandidate;
  }

  public String getName() {
    return name;
  }

  public Instant getStartsAt() {
    return startsAt;
  }

  public Instant getEndsAt() {
    return endsAt;
  }

  public int getSortOrder() {
    return sortOrder;
  }

  public String getNote() {
    return note;
  }
}
