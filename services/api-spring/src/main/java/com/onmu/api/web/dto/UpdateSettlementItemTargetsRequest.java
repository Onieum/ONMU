package com.onmu.api.web.dto;

import java.util.List;

public record UpdateSettlementItemTargetsRequest(
  List<String> targetUserIds,
  List<SettlementTargetShareRequest> targetShares
) {
  public UpdateSettlementItemTargetsRequest(List<String> targetUserIds) {
    this(targetUserIds, List.of());
  }
}
