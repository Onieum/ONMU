package com.onmu.api.service;

import java.util.List;
import java.util.Map;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

public interface ChatRealtimePublisher {
  SseEmitter subscribe(String groupId, List<Map<String, Object>> replayMessages);

  void publishMessage(String groupId, Map<String, Object> message);
}
