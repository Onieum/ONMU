package com.onmu.api.domain;

import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface VoteResponseRepository extends JpaRepository<VoteResponseEntity, UUID> {
  long countByVote(VoteEntity vote);

  long countByVoteOption(VoteOptionEntity voteOption);
}
