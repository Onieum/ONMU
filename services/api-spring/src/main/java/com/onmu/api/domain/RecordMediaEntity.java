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
@Table(name = "record_media")
public class RecordMediaEntity {
  @Id
  private UUID id;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "record_id", nullable = false)
  private RecordEntity record;

  @Column(name = "media_type", nullable = false)
  private String mediaType;

  @Column(name = "storage_key", nullable = false)
  private String storageKey;

  @Column(name = "public_url")
  private String publicUrl;

  @Column
  private Integer width;

  @Column
  private Integer height;

  @Column(name = "duration_seconds")
  private Double durationSeconds;

  @Column(name = "sort_order", nullable = false)
  private Integer sortOrder;

  @JdbcTypeCode(SqlTypes.JSON)
  @Column(columnDefinition = "jsonb", nullable = false)
  private String payload;

  @Column(name = "created_at", insertable = false, updatable = false)
  private Instant createdAt;

  protected RecordMediaEntity() {
  }

  public RecordMediaEntity(RecordEntity record, String mediaType, String storageKey, String publicUrl, Integer width, Integer height, Double durationSeconds, Integer sortOrder, String payload) {
    this.id = UUID.randomUUID();
    this.record = record;
    this.mediaType = mediaType;
    this.storageKey = storageKey;
    this.publicUrl = publicUrl;
    this.width = width;
    this.height = height;
    this.durationSeconds = durationSeconds;
    this.sortOrder = sortOrder != null ? sortOrder : 0;
    this.payload = payload != null ? payload : "{}";
  }

  public UUID getId() {
    return id;
  }

  public RecordEntity getRecord() {
    return record;
  }

  public String getMediaType() {
    return mediaType;
  }

  public void setMediaType(String mediaType) {
    this.mediaType = mediaType;
  }

  public String getStorageKey() {
    return storageKey;
  }

  public void setStorageKey(String storageKey) {
    this.storageKey = storageKey;
  }

  public String getPublicUrl() {
    return publicUrl;
  }

  public void setPublicUrl(String publicUrl) {
    this.publicUrl = publicUrl;
  }

  public Integer getWidth() {
    return width;
  }

  public void setWidth(Integer width) {
    this.width = width;
  }

  public Integer getHeight() {
    return height;
  }

  public void setHeight(Integer height) {
    this.height = height;
  }

  public Double getDurationSeconds() {
    return durationSeconds;
  }

  public void setDurationSeconds(Double durationSeconds) {
    this.durationSeconds = durationSeconds;
  }

  public Integer getSortOrder() {
    return sortOrder;
  }

  public void setSortOrder(Integer sortOrder) {
    this.sortOrder = sortOrder;
  }

  public String getPayload() {
    return payload;
  }

  public void setPayload(String payload) {
    this.payload = payload;
  }

  public Instant getCreatedAt() {
    return createdAt;
  }
}
