package com.onmu.api.web.dto;

import java.util.List;

public record SettlementPreviewRequest(
  List<SettlementDraftSectionRequest> sections
) {
}
