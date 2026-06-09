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
@Table(name = "records")
public class RecordEntity {
  @Id
  private UUID id;

  @Column(name = "public_id", nullable = false, unique = true)
  private String publicId;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "group_id")
  private GroupEntity group;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "plan_id")
  private PlanEntity plan;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "author_user_id")
  private UserEntity author;

  @Column(nullable = false)
  private String title;

  @Column(nullable = false)
  private String visibility;

  @JdbcTypeCode(SqlTypes.JSON)
  @Column(columnDefinition = "jsonb", nullable = false)
  private String payload;

  @Column(name = "created_at", insertable = false, updatable = false)
  private Instant createdAt;

  @Column(name = "updated_at", nullable = false)
  private Instant updatedAt;

  @Column(name = "deleted_at")
  private Instant deletedAt;

  @Column
  private String summary;

  @JdbcTypeCode(SqlTypes.JSON)
  @Column(name = "mood_tags", columnDefinition = "jsonb", nullable = false)
  private String moodTags;

  protected RecordEntity() {
  }

  public RecordEntity(String publicId, GroupEntity group, PlanEntity plan, UserEntity author, String title, String visibility, String payload, String moodTags) {
    this.id = UUID.randomUUID();
    this.publicId = publicId;
    this.group = group;
    this.plan = plan;
    this.author = author;
    this.title = title;
    this.visibility = visibility;
    this.payload = payload != null ? payload : "{}";
    this.updatedAt = Instant.now();
    this.moodTags = moodTags != null ? moodTags : "[]";
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

  public UserEntity getAuthor() {
    return author;
  }

  public String getTitle() {
    return title;
  }

  public void setTitle(String title) {
    this.title = title;
  }

  public String getVisibility() {
    return visibility;
  }

  public void setVisibility(String visibility) {
    this.visibility = visibility;
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

  public Instant getUpdatedAt() {
    return updatedAt;
  }

  public void setUpdatedAt(Instant updatedAt) {
    this.updatedAt = updatedAt;
  }

  public Instant getDeletedAt() {
    return deletedAt;
  }

  public void setDeletedAt(Instant deletedAt) {
    this.deletedAt = deletedAt;
  }

  public String getSummary() {
    return summary;
  }

  public void setSummary(String summary) {
    this.summary = summary;
  }

  public String getMoodTags() {
    return moodTags;
  }

  public void setMoodTags(String moodTags) {
    this.moodTags = moodTags;
  }
}
