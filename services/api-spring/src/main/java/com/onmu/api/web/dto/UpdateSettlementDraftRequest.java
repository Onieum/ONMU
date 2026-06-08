package com.onmu.api.web.dto;

import java.util.List;

public record UpdateSettlementDraftRequest(
  List<SettlementDraftItemRequest> items,
  String memo
) {
}
