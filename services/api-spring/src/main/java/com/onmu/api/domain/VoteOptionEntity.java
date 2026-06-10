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
@Table(name = "vote_options")
public class VoteOptionEntity {
  @Id
  private UUID id;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "vote_id", nullable = false)
  private VoteEntity vote;

  @Column(name = "public_id", nullable = false, unique = true)
  private String publicId;

  @Column(nullable = false)
  private String label;

  @Column(name = "target_type")
  private String targetType;

  @Column(name = "target_id")
  private String targetId;

  @Column(name = "sort_order", nullable = false)
  private int sortOrder;

  @JdbcTypeCode(SqlTypes.JSON)
  @Column(columnDefinition = "jsonb", nullable = false)
  private String payload;

  @Column(name = "created_at", insertable = false, updatable = false)
  private Instant createdAt;

  protected VoteOptionEntity() {
  }

  public VoteOptionEntity(
    VoteEntity vote,
    String publicId,
    String label,
    String targetType,
    String targetId,
    int sortOrder,
    String payload
  ) {
    this.id = UUID.randomUUID();
    this.vote = vote;
    this.publicId = publicId;
    this.label = label;
    this.targetType = targetType;
    this.targetId = targetId;
    this.sortOrder = sortOrder;
    this.payload = payload;
  }

  public UUID getId() {
    return id;
  }

  public VoteEntity getVote() {
    return vote;
  }

  public String getPublicId() {
    return publicId;
  }

  public String getLabel() {
    return label;
  }

  public String getTargetType() {
    return targetType;
  }

  public String getTargetId() {
    return targetId;
  }

  public int getSortOrder() {
    return sortOrder;
  }

  public String getPayload() {
    return payload;
  }

  public Instant getCreatedAt() {
    return createdAt;
  }
}
