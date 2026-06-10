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
@Table(name = "record_tags")
public class RecordTagEntity {
  @Id
  private UUID id;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "record_id", nullable = false)
  private RecordEntity record;

  @Column(name = "tag_type", nullable = false)
  private String tagType;

  @Column(name = "tag_value", nullable = false)
  private String tagValue;

  @Column(name = "created_at", insertable = false, updatable = false)
  private Instant createdAt;

  protected RecordTagEntity() {
  }

  public RecordTagEntity(RecordEntity record, String tagType, String tagValue) {
    this.id = UUID.randomUUID();
    this.record = record;
    this.tagType = tagType != null ? tagType : "user";
    this.tagValue = tagValue;
  }

  public UUID getId() {
    return id;
  }

  public RecordEntity getRecord() {
    return record;
  }

  public String getTagType() {
    return tagType;
  }

  public void setTagType(String tagType) {
    this.tagType = tagType;
  }

  public String getTagValue() {
    return tagValue;
  }

  public void setTagValue(String tagValue) {
    this.tagValue = tagValue;
  }

  public Instant getCreatedAt() {
    return createdAt;
  }
}
