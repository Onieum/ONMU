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
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

@Entity
@Table(name = "place_candidates")
public class PlaceCandidateEntity {
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
  @JoinColumn(name = "external_place_id")
  private ExternalPlaceEntity externalPlace;

  @Column(nullable = false)
  private String name;

  @Column
  private String category;

  @Column
  private String address;

  @JdbcTypeCode(SqlTypes.JSON)
  @Column(columnDefinition = "jsonb", nullable = false)
  private String payload;

  @Column(name = "created_at", insertable = false, updatable = false)
  private Instant createdAt;

  protected PlaceCandidateEntity() {
  }

  public PlaceCandidateEntity(
    String publicId,
    GroupEntity group,
    PlanEntity plan,
    String name,
    String category,
    String address,
    String payload
  ) {
    this(publicId, group, plan, null, name, category, address, payload);
  }

  public PlaceCandidateEntity(
    String publicId,
    GroupEntity group,
    PlanEntity plan,
    ExternalPlaceEntity externalPlace,
    String name,
    String category,
    String address,
    String payload
  ) {
    this.id = UUID.randomUUID();
    this.publicId = publicId;
    this.group = group;
    this.plan = plan;
    this.externalPlace = externalPlace;
    this.name = name;
    this.category = category;
    this.address = address;
    this.payload = payload;
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

  public PlanEntity getPlan() {
    return plan;
  }

  public ExternalPlaceEntity getExternalPlace() {
    return externalPlace;
  }

  public String getName() {
    return name;
  }

  public String getCategory() {
    return category;
  }

  public String getAddress() {
    return address;
  }

  public String getPayload() {
    return payload;
  }

  public Instant getCreatedAt() {
    return createdAt;
  }
}
