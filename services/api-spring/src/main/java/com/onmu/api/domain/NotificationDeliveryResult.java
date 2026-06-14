package com.onmu.api.domain;

import java.time.Instant;

public record NotificationDeliveryResult(
  String provider,
  String status,
  String providerMessageId,
  String errorMessage,
  Instant deliveredAt
) {
  public static NotificationDeliveryResult sent(String provider, String providerMessageId, Instant deliveredAt) {
    return new NotificationDeliveryResult(provider, "sent", providerMessageId, null, deliveredAt);
  }

  public static NotificationDeliveryResult failed(String provider, String errorMessage) {
    return new NotificationDeliveryResult(provider, "failed", null, errorMessage, null);
  }

  public static NotificationDeliveryResult skippedDev(String errorMessage) {
    return new NotificationDeliveryResult("dev", "skipped_dev", null, errorMessage, null);
  }
}
