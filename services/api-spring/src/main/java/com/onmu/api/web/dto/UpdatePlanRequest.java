package com.onmu.api.web.dto;

public record UpdatePlanRequest(
  String title,
  String startsAt,
  String endsAt,
  String status,
  String placeName,
  String memo
) {
}
