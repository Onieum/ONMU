package com.onmu.api.domain;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface VoteResponseRepository extends JpaRepository<VoteResponseEntity, UUID> {
  List<VoteResponseEntity> findByVoteAndUser(VoteEntity vote, UserEntity user);

  Optional<VoteResponseEntity> findFirstByVoteAndUserOrderByCreatedAtDesc(VoteEntity vote, UserEntity user);

  boolean existsByVoteOptionAndUser(VoteOptionEntity voteOption, UserEntity user);

  long countByVote(VoteEntity vote);

  long countByVoteOption(VoteOptionEntity voteOption);

  @Query("select response from VoteResponseEntity response join fetch response.user where response.voteOption = :voteOption order by response.createdAt asc")
  List<VoteResponseEntity> findByVoteOptionWithUserOrderByCreatedAtAsc(@Param("voteOption") VoteOptionEntity voteOption);

  @Query("select count(distinct response.user) from VoteResponseEntity response where response.vote = :vote")
  long countDistinctUsersByVote(VoteEntity vote);
}
