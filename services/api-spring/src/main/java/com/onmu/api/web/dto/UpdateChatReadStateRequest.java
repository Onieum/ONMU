package com.onmu.api.web.dto;

public record UpdateChatReadStateRequest(
  String lastReadMessageId
) {
}
