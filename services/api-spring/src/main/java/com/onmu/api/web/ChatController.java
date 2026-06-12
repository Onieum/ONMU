package com.onmu.api.web;

import com.onmu.api.security.AuthenticatedUser;
import com.onmu.api.service.ChatActivityService;
import com.onmu.api.web.dto.CreateChatMessageRequest;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/groups/{groupId}/chat/messages")
public class ChatController {
  private final ChatActivityService chatActivityService;

  public ChatController(ChatActivityService chatActivityService) {
    this.chatActivityService = chatActivityService;
  }

  @GetMapping
  public Map<String, Object> messages(
    @PathVariable String groupId,
    @AuthenticationPrincipal AuthenticatedUser user
  ) {
    return chatActivityService.messages(groupId, user.userId());
  }

  @PostMapping
  public ResponseEntity<Map<String, Object>> createMessage(
    @PathVariable String groupId,
    @AuthenticationPrincipal AuthenticatedUser user,
    @RequestBody CreateChatMessageRequest request
  ) {
    return ResponseEntity.status(HttpStatus.CREATED)
      .body(chatActivityService.createMessage(groupId, user.userId(), request));
  }
}
