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
@Table(name = "ootd_features")
public class OotdFeatureEntity {
  @Id
  private UUID id;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "record_id", nullable = false)
  private RecordEntity record;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "user_id")
  private UserEntity user;

  @Column(name = "feature_source", nullable = false)
  private String featureSource;

  @JdbcTypeCode(SqlTypes.JSON)
  @Column(columnDefinition = "jsonb", nullable = false)
  private String features;

  @Column(name = "created_at", insertable = false, updatable = false)
  private Instant createdAt;

  protected OotdFeatureEntity() {
  }

  public OotdFeatureEntity(RecordEntity record, UserEntity user, String featureSource, String features) {
    this.id = UUID.randomUUID();
    this.record = record;
    this.user = user;
    this.featureSource = featureSource != null ? featureSource : "user";
    this.features = features != null ? features : "{}";
  }

  public UUID getId() {
    return id;
  }

  public RecordEntity getRecord() {
    return record;
  }

  public UserEntity getUser() {
    return user;
  }

  public void setUser(UserEntity user) {
    this.user = user;
  }

  public String getFeatureSource() {
    return featureSource;
  }

  public void setFeatureSource(String featureSource) {
    this.featureSource = featureSource;
  }

  public String getFeatures() {
    return features;
  }

  public void setFeatures(String features) {
    this.features = features;
  }

  public Instant getCreatedAt() {
    return createdAt;
  }
}
