package com.onmu.api.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

@Entity
@Table(name = "external_places")
public class ExternalPlaceEntity {
  @Id
  private UUID id;

  @Column(name = "public_id", nullable = false, unique = true)
  private String publicId;

  @Column(nullable = false)
  private String provider;

  @Column(name = "provider_place_id", nullable = false)
  private String providerPlaceId;

  @Column(nullable = false)
  private String name;

  @Column
  private String category;

  @Column
  private String address;

  @Column(name = "road_address")
  private String roadAddress;

  @Column
  private Double latitude;

  @Column
  private Double longitude;

  @Column(name = "homepage_url")
  private String homepageUrl;

  @JdbcTypeCode(SqlTypes.JSON)
  @Column(name = "provider_payload", columnDefinition = "jsonb", nullable = false)
  private String providerPayload;

  @Column(name = "created_at", insertable = false, updatable = false)
  private Instant createdAt;

  protected ExternalPlaceEntity() {
  }

  public ExternalPlaceEntity(
    String provider,
    String providerPlaceId,
    String name,
    String category,
    String address,
    String roadAddress,
    Double latitude,
    Double longitude,
    String homepageUrl,
    String providerPayload
  ) {
    this.id = UUID.randomUUID();
    this.publicId = "place_" + this.id.toString().replace("-", "");
    this.provider = provider;
    this.providerPlaceId = providerPlaceId;
    this.name = name;
    this.category = category;
    this.address = address;
    this.roadAddress = roadAddress;
    this.latitude = latitude;
    this.longitude = longitude;
    this.homepageUrl = homepageUrl;
    this.providerPayload = providerPayload == null || providerPayload.isBlank() ? "{}" : providerPayload;
  }

  public UUID getId() {
    return id;
  }

  public String getPublicId() {
    return publicId;
  }

  public String getProvider() {
    return provider;
  }

  public String getProviderPlaceId() {
    return providerPlaceId;
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

  public String getRoadAddress() {
    return roadAddress;
  }

  public Double getLatitude() {
    return latitude;
  }

  public Double getLongitude() {
    return longitude;
  }

  public String getHomepageUrl() {
    return homepageUrl;
  }

  public String getProviderPayload() {
    return providerPayload;
  }
}
