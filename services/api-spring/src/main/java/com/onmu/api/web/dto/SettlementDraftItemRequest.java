package com.onmu.api.web.dto;

import java.util.List;

public record SettlementDraftItemRequest(
  String id,
  String title,
  Integer amount,
  String payerName,
  String splitType,
  List<String> targetNames
) {
}
