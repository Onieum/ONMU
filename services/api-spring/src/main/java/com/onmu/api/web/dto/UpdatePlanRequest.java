package com.onmu.api.web.dto;

public record UpdatePlanRequest(
  String title,
  String startsAt,
  String status
) {
}
