package com.onmu.api.domain;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface VoteOptionRepository extends JpaRepository<VoteOptionEntity, UUID> {
  List<VoteOptionEntity> findByVoteOrderBySortOrderAsc(VoteEntity vote);
}
