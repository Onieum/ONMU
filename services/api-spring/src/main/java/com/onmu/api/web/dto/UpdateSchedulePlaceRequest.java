package com.onmu.api.web.dto;

public record UpdateSchedulePlaceRequest(
  String startsAt,
  String endsAt,
  String note
) {
}
