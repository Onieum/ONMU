package com.onmu.api.web.dto;

import java.util.List;

public record UpdateSettlementItemTargetsRequest(
  List<String> targetUserIds
) {
}
