package com.onmu.api.domain;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface SettlementTransferRepository extends JpaRepository<SettlementTransferEntity, UUID> {
  List<SettlementTransferEntity> findBySettlementOrderByCreatedAtAsc(SettlementEntity settlement);

  Optional<SettlementTransferEntity> findBySettlementAndPublicId(SettlementEntity settlement, String publicId);
}
