package com.onmu.api.web.dto;

import java.util.Map;

public record CrewOotdAppearanceResponse(
    String userId,
    String nickname,
    String source,
    String ootdRecordId,
    String ootdImageUrl,
    Map<String, Object> character
) {
}
