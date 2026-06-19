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
@Table(name = "ootd_avatar_generation_jobs")
public class OotdAvatarGenerationJobEntity {
  @Id
  private UUID id;

  @Column(name = "public_id", nullable = false, unique = true)
  private String publicId;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "record_id", nullable = false)
  private RecordEntity record;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "user_id", nullable = false)
  private UserEntity user;

  @Column(name = "input_type", nullable = false)
  private String inputType;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "outfit_photo_media_id")
  private RecordMediaEntity outfitPhotoMedia;

  @Column(name = "outfit_description")
  private String outfitDescription;

  @Column(nullable = false)
  private String status;

  @Column(name = "result_storage_key")
  private String resultStorageKey;

  @Column(name = "result_public_url")
  private String resultPublicUrl;

  @Column(name = "error_code")
  private String errorCode;

  @Column(nullable = false)
  private Boolean retryable;

  @JdbcTypeCode(SqlTypes.JSON)
  @Column(columnDefinition = "jsonb", nullable = false)
  private String payload;

  @Column(name = "created_at", insertable = false, updatable = false)
  private Instant createdAt;

  @Column(name = "updated_at", nullable = false)
  private Instant updatedAt;

  protected OotdAvatarGenerationJobEntity() {
  }

  public OotdAvatarGenerationJobEntity(
    String publicId,
    RecordEntity record,
    UserEntity user,
    String inputType,
    RecordMediaEntity outfitPhotoMedia,
    String outfitDescription,
    String payload
  ) {
    this.id = UUID.randomUUID();
    this.publicId = publicId;
    this.record = record;
    this.user = user;
    this.inputType = inputType;
    this.outfitPhotoMedia = outfitPhotoMedia;
    this.outfitDescription = outfitDescription;
    this.status = "PENDING";
    this.retryable = false;
    this.payload = payload != null ? payload : "{}";
    this.updatedAt = Instant.now();
  }

  public UUID getId() {
    return id;
  }

  public String getPublicId() {
    return publicId;
  }

  public RecordEntity getRecord() {
    return record;
  }

  public UserEntity getUser() {
    return user;
  }

  public String getInputType() {
    return inputType;
  }

  public RecordMediaEntity getOutfitPhotoMedia() {
    return outfitPhotoMedia;
  }

  public String getOutfitDescription() {
    return outfitDescription;
  }

  public String getStatus() {
    return status;
  }

  public String getResultStorageKey() {
    return resultStorageKey;
  }

  public String getResultPublicUrl() {
    return resultPublicUrl;
  }

  public String getErrorCode() {
    return errorCode;
  }

  public Boolean getRetryable() {
    return retryable;
  }

  public String getPayload() {
    return payload;
  }

  public Instant getCreatedAt() {
    return createdAt;
  }

  public Instant getUpdatedAt() {
    return updatedAt;
  }

  public void markCompleted(String resultStorageKey, String resultPublicUrl) {
    this.status = "COMPLETED";
    this.resultStorageKey = resultStorageKey;
    this.resultPublicUrl = resultPublicUrl;
    this.errorCode = null;
    this.retryable = false;
    this.updatedAt = Instant.now();
  }

  public void markFailed(String errorCode, boolean retryable) {
    this.status = "FAILED";
    this.errorCode = errorCode;
    this.retryable = retryable;
    this.updatedAt = Instant.now();
  }
}
