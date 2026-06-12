package com.onmu.api.service;

import java.io.IOException;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

@Component
public class InProcessSseChatRealtimePublisher implements ChatRealtimePublisher {
  private static final long EMITTER_TIMEOUT_MILLIS = 30L * 60L * 1000L;

  private final Map<String, Set<Subscriber>> subscribersByGroupId = new ConcurrentHashMap<>();

  @Override
  public SseEmitter subscribe(String groupId, String viewerUserPublicId, List<Map<String, Object>> replayMessages) {
    SseEmitter emitter = new SseEmitter(EMITTER_TIMEOUT_MILLIS);
    Subscriber subscriber = new Subscriber(emitter, viewerUserPublicId);
    subscribersByGroupId.computeIfAbsent(groupId, ignored -> ConcurrentHashMap.newKeySet()).add(subscriber);

    emitter.onCompletion(() -> remove(groupId, subscriber));
    emitter.onTimeout(() -> remove(groupId, subscriber));
    emitter.onError(ignored -> remove(groupId, subscriber));

    try {
      emitter.send(SseEmitter.event().comment("connected"));
      for (Map<String, Object> message : replayMessages) {
        sendMessage(emitter, message);
      }
    } catch (IOException exception) {
      remove(groupId, subscriber);
      emitter.completeWithError(exception);
    }
    return emitter;
  }

  @Override
  public void publishMessage(String groupId, Map<String, Object> message) {
    Set<Subscriber> subscribers = subscribersByGroupId.get(groupId);
    if (subscribers == null || subscribers.isEmpty()) {
      return;
    }
    for (Subscriber subscriber : subscribers) {
      try {
        sendMessage(subscriber.emitter(), messageForViewer(message, subscriber.viewerUserPublicId()));
      } catch (IOException exception) {
        remove(groupId, subscriber);
        subscriber.emitter().completeWithError(exception);
      }
    }
  }

  Map<String, Object> messageForViewer(Map<String, Object> message, String viewerUserPublicId) {
    Map<String, Object> viewerMessage = new LinkedHashMap<>(message);
    Object senderUserId = viewerMessage.get("senderUserId");
    viewerMessage.put(
      "isMine",
      senderUserId != null && senderUserId.toString().equals(viewerUserPublicId)
    );
    return viewerMessage;
  }

  private void sendMessage(SseEmitter emitter, Map<String, Object> message) throws IOException {
    emitter.send(SseEmitter.event()
      .name("chat.message")
      .id(String.valueOf(message.getOrDefault("id", "")))
      .data(message));
  }

  private void remove(String groupId, Subscriber subscriber) {
    Set<Subscriber> subscribers = subscribersByGroupId.get(groupId);
    if (subscribers == null) {
      return;
    }
    subscribers.remove(subscriber);
    if (subscribers.isEmpty()) {
      subscribersByGroupId.remove(groupId, subscribers);
    }
  }

  private record Subscriber(SseEmitter emitter, String viewerUserPublicId) {
  }
}
