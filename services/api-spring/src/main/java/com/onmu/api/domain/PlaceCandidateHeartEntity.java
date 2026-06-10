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
@Table(name = "place_candidate_hearts")
public class PlaceCandidateHeartEntity {
  @Id
  private UUID id;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "place_candidate_id", nullable = false)
  private PlaceCandidateEntity candidate;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "user_id", nullable = false)
  private UserEntity user;

  @Column(name = "created_at", insertable = false, updatable = false)
  private Instant createdAt;

  protected PlaceCandidateHeartEntity() {
  }

  public PlaceCandidateHeartEntity(PlaceCandidateEntity candidate, UserEntity user) {
    this.id = UUID.randomUUID();
    this.candidate = candidate;
    this.user = user;
  }

  public UUID getId() {
    return id;
  }

  public PlaceCandidateEntity getCandidate() {
    return candidate;
  }

  public UserEntity getUser() {
    return user;
  }

  public Instant getCreatedAt() {
    return createdAt;
  }
}
