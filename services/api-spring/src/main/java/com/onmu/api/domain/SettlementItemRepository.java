package com.onmu.api.domain;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface SettlementItemRepository extends JpaRepository<SettlementItemEntity, UUID> {
  List<SettlementItemEntity> findBySettlementDraftOrderByCreatedAtAsc(SettlementDraftEntity settlementDraft);

  List<SettlementItemEntity> findBySettlementOrderByCreatedAtAsc(SettlementEntity settlement);

  List<SettlementItemEntity> findBySettlementDraft(SettlementDraftEntity settlementDraft);

  List<SettlementItemEntity> findBySectionOrderByCreatedAtAsc(SettlementSectionEntity section);

  Optional<SettlementItemEntity> findBySettlementDraftAndPublicId(
    SettlementDraftEntity settlementDraft,
    String publicId
  );

  void deleteBySettlementDraft(SettlementDraftEntity settlementDraft);

  void deleteBySectionIn(List<SettlementSectionEntity> sections);
}
