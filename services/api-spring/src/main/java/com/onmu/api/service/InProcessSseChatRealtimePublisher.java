package com.onmu.api.service;

import java.io.IOException;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

@Component
public class InProcessSseChatRealtimePublisher implements ChatRealtimePublisher {
  private static final long EMITTER_TIMEOUT_MILLIS = 30L * 60L * 1000L;

  private final Map<String, Set<SseEmitter>> emittersByGroupId = new ConcurrentHashMap<>();

  @Override
  public SseEmitter subscribe(String groupId, List<Map<String, Object>> replayMessages) {
    SseEmitter emitter = new SseEmitter(EMITTER_TIMEOUT_MILLIS);
    emittersByGroupId.computeIfAbsent(groupId, ignored -> ConcurrentHashMap.newKeySet()).add(emitter);

    emitter.onCompletion(() -> remove(groupId, emitter));
    emitter.onTimeout(() -> remove(groupId, emitter));
    emitter.onError(ignored -> remove(groupId, emitter));

    try {
      emitter.send(SseEmitter.event().comment("connected"));
      for (Map<String, Object> message : replayMessages) {
        sendMessage(emitter, message);
      }
    } catch (IOException exception) {
      remove(groupId, emitter);
      emitter.completeWithError(exception);
    }
    return emitter;
  }

  @Override
  public void publishMessage(String groupId, Map<String, Object> message) {
    Set<SseEmitter> emitters = emittersByGroupId.get(groupId);
    if (emitters == null || emitters.isEmpty()) {
      return;
    }
    for (SseEmitter emitter : emitters) {
      try {
        sendMessage(emitter, message);
      } catch (IOException exception) {
        remove(groupId, emitter);
        emitter.completeWithError(exception);
      }
    }
  }

  private void sendMessage(SseEmitter emitter, Map<String, Object> message) throws IOException {
    emitter.send(SseEmitter.event()
      .name("chat.message")
      .id(String.valueOf(message.getOrDefault("id", "")))
      .data(message));
  }

  private void remove(String groupId, SseEmitter emitter) {
    Set<SseEmitter> emitters = emittersByGroupId.get(groupId);
    if (emitters == null) {
      return;
    }
    emitters.remove(emitter);
    if (emitters.isEmpty()) {
      emittersByGroupId.remove(groupId, emitters);
    }
  }
}
