package com.onmu.api.web.dto;

import java.util.List;

public record SettlementDraftSectionRequest(
  String id,
  String schedulePlaceId,
  String title,
  String payerUserId,
  List<SettlementDraftItemRequest> items
) {
}
