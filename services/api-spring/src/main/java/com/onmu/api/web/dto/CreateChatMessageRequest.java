package com.onmu.api.web.dto;

import java.util.List;

public record CreateChatMessageRequest(
  String message,
  List<ChatMessageAttachmentRequest> attachments
) {
  public CreateChatMessageRequest(String message) {
    this(message, List.of());
  }
}
