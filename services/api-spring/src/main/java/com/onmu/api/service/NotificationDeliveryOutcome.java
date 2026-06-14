package com.onmu.api.service;

import com.onmu.api.domain.NotificationDeliveryResult;

public record NotificationDeliveryOutcome(
  String outboxStatus,
  String lastError
) {
  public static NotificationDeliveryOutcome published() {
    return new NotificationDeliveryOutcome("published", null);
  }

  public static NotificationDeliveryOutcome failed(String lastError) {
    return new NotificationDeliveryOutcome("failed", lastError);
  }

  public static NotificationDeliveryOutcome skippedDev(String lastError) {
    return new NotificationDeliveryOutcome("skipped_dev", lastError);
  }

  public static NotificationDeliveryOutcome fromDeliveryResult(NotificationDeliveryResult result) {
    return switch (result.status()) {
      case "sent" -> published();
      case "failed" -> failed(result.errorMessage());
      case "skipped_dev" -> skippedDev(null);
      default -> published();
    };
  }
}
