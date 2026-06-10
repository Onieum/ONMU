package com.onmu.api.web.dto;

import java.util.List;

public record SettlementDraftItemRequest(
  String id,
  String title,
  Integer amount,
  Integer amountWon,
  String payerUserId,
  String payerName,
  String splitType,
  List<String> targetUserIds,
  List<String> targetNames
) {
}
