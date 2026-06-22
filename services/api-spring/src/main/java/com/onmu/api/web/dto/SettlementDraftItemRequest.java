package com.onmu.api.web.dto;

import java.util.List;

public record SettlementDraftItemRequest(
  String id,
  String title,
  Integer amountWon,
  String splitType,
  List<String> targetUserIds
) {
}
