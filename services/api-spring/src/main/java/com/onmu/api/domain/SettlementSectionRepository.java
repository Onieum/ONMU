package com.onmu.api.domain;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface SettlementSectionRepository extends JpaRepository<SettlementSectionEntity, UUID> {
  List<SettlementSectionEntity> findBySettlementDraftOrderBySortOrderAsc(SettlementDraftEntity draft);

  List<SettlementSectionEntity> findBySettlementOrderBySortOrderAsc(SettlementEntity settlement);

  Optional<SettlementSectionEntity> findBySettlementDraftAndPublicId(SettlementDraftEntity draft, String publicId);

  void deleteBySettlementDraft(SettlementDraftEntity draft);
}
