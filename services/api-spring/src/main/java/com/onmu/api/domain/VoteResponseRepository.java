package com.onmu.api.domain;

import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface VoteResponseRepository extends JpaRepository<VoteResponseEntity, UUID> {
  long countByVote(VoteEntity vote);

  long countByVoteOption(VoteOptionEntity voteOption);

  @Query("select count(distinct response.user) from VoteResponseEntity response where response.vote = :vote")
  long countDistinctUsersByVote(VoteEntity vote);
}
