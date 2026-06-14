package com.onmu.api.service;

import com.onmu.api.domain.NotificationDeliveryResult;
import com.onmu.api.domain.NotificationEntity;
import java.util.Map;
import org.springframework.stereotype.Component;

@Component
public class DevNotificationPushProvider implements NotificationPushProvider {
  @Override
  public String provider() {
    return "dev";
  }

  @Override
  public NotificationDeliveryResult deliver(NotificationEntity notification, Map<String, Object> requestPayload) {
    return NotificationDeliveryResult.skippedDev("dev_push_delivery_disabled");
  }
}
