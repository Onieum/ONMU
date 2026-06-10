package com.onmu.api.domain;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface SettlementItemTargetRepository extends JpaRepository<SettlementItemTargetEntity, UUID> {
  List<SettlementItemTargetEntity> findBySettlementItemInOrderByCreatedAtAsc(
    List<SettlementItemEntity> settlementItems
  );

  List<SettlementItemTargetEntity> findBySettlementItemOrderByCreatedAtAsc(SettlementItemEntity settlementItem);

  void deleteBySettlementItemIn(List<SettlementItemEntity> settlementItems);

  void deleteBySettlementItem(SettlementItemEntity settlementItem);
}
