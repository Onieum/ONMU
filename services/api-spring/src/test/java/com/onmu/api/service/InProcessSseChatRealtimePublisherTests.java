package com.onmu.api.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;

import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

class InProcessSseChatRealtimePublisherTests {
  @Test
  void fanOutMessageRecomputesIsMineForEachViewer() {
    InProcessSseChatRealtimePublisher publisher = new InProcessSseChatRealtimePublisher();
    Map<String, Object> senderRelativeMessage = new LinkedHashMap<>();
    senderRelativeMessage.put("id", "message-1");
    senderRelativeMessage.put("senderUserId", "sender-public-id");
    senderRelativeMessage.put("message", "발신자 기준 응답");
    senderRelativeMessage.put("isMine", true);

    Map<String, Object> senderView = publisher.messageForViewer(senderRelativeMessage, "sender-public-id");
    Map<String, Object> otherMemberView = publisher.messageForViewer(senderRelativeMessage, "other-public-id");

    assertThat(senderView)
      .containsEntry("senderUserId", "sender-public-id")
      .containsEntry("isMine", true);
    assertThat(otherMemberView)
      .containsEntry("senderUserId", "sender-public-id")
      .containsEntry("isMine", false);
    assertThat(senderRelativeMessage).containsEntry("isMine", true);
  }

  @Test
  void systemFanOutMessageIsNotMineForViewer() {
    InProcessSseChatRealtimePublisher publisher = new InProcessSseChatRealtimePublisher();
    Map<String, Object> systemMessage = new LinkedHashMap<>();
    systemMessage.put("id", "system-message-1");
    systemMessage.put("message", "새 활동이 있어요.");
    systemMessage.put("isMine", true);

    Map<String, Object> viewerMessage = publisher.messageForViewer(systemMessage, "viewer-public-id");

    assertThat(viewerMessage).containsEntry("isMine", false);
  }

  @Test
  void heartbeatUsesSseCommentEvent() throws Exception {
    InProcessSseChatRealtimePublisher publisher = new InProcessSseChatRealtimePublisher();
    SseEmitter emitter = mock(SseEmitter.class);

    publisher.sendHeartbeat(emitter);

    verify(emitter).send(any(SseEmitter.SseEventBuilder.class));
  }
}
