package com.onmu.api.web.dto;

public record CreateSchedulePlaceRequest(
  String candidateId,
  String name,
  String startsAt,
  String endsAt,
  String note
) {
}
