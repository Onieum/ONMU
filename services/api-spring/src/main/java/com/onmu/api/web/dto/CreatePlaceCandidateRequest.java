package com.onmu.api.web.dto;

import jakarta.validation.constraints.NotBlank;
import java.util.List;

public record CreatePlaceCandidateRequest(
  @NotBlank String name,
  String category,
  String address,
  String summary,
  List<String> tags,
  String provider,
  String providerPlaceId,
  String roadAddress,
  Double lat,
  Double lng,
  Double latitude,
  Double longitude,
  String sourceUrl,
  String fetchedAt
) {
  public CreatePlaceCandidateRequest(
    String name,
    String category,
    String address,
    String summary,
    List<String> tags
  ) {
    this(name, category, address, summary, tags, null, null, null, null, null, null, null, null, null);
  }
}
