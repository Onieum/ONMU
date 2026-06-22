package com.onmu.api.domain;

import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface SettlementConfirmationRepository extends JpaRepository<SettlementConfirmationEntity, UUID> {
  Optional<SettlementConfirmationEntity> findBySettlementTransferAndUserAndConfirmationType(
    SettlementTransferEntity transfer,
    UserEntity user,
    String confirmationType
  );

  boolean existsBySettlementTransferAndConfirmationType(SettlementTransferEntity transfer, String confirmationType);
}
