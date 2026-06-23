package com.onmu.api.web.dto;

public record SettlementTargetShareRequest(
  String userId,
  Long amountWon
) {
}
