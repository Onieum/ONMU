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
@Table(name = "vote_responses")
public class VoteResponseEntity {
  @Id
  private UUID id;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "vote_id", nullable = false)
  private VoteEntity vote;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "vote_option_id")
  private VoteOptionEntity voteOption;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "user_id", nullable = false)
  private UserEntity user;

  @JdbcTypeCode(SqlTypes.JSON)
  @Column(name = "response_value", columnDefinition = "jsonb", nullable = false)
  private String responseValue;

  @Column(name = "created_at", insertable = false, updatable = false)
  private Instant createdAt;

  protected VoteResponseEntity() {
  }

  public VoteResponseEntity(
    VoteEntity vote,
    VoteOptionEntity voteOption,
    UserEntity user,
    String responseValue
  ) {
    this.id = UUID.randomUUID();
    this.vote = vote;
    this.voteOption = voteOption;
    this.user = user;
    this.responseValue = responseValue;
  }

  public UUID getId() {
    return id;
  }

  public VoteEntity getVote() {
    return vote;
  }

  public VoteOptionEntity getVoteOption() {
    return voteOption;
  }

  public UserEntity getUser() {
    return user;
  }

  public String getResponseValue() {
    return responseValue;
  }

  public Instant getCreatedAt() {
    return createdAt;
  }
}
