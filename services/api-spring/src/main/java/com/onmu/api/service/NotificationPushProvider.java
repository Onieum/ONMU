package com.onmu.api.service;

import com.onmu.api.domain.NotificationDeliveryResult;
import com.onmu.api.domain.NotificationEntity;
import java.util.Map;

public interface NotificationPushProvider {
  String provider();

  NotificationDeliveryResult deliver(NotificationEntity notification, Map<String, Object> requestPayload);
}
