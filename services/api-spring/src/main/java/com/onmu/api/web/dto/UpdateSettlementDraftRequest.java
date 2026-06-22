package com.onmu.api.web.dto;

import java.util.List;

public record UpdateSettlementDraftRequest(
  List<SettlementDraftSectionRequest> sections,
  String memo
) {
}
