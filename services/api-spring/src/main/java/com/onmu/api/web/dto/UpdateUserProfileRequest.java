package com.onmu.api.web.dto;

import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import java.util.Map;

public record UpdateUserProfileRequest(
  @Size(max = 80) String displayName,
  @Size(max = 2048) String profileImageUrl,
  @Size(max = 50) Map<String, Object> preferenceProfile,
  @Size(max = 50) Map<String, Object> pixelCharacter,
  @Pattern(regexp = "PENDING|PREFERENCE_READY|CHARACTER_READY|COMPLETED") String onboardingStatus
) {
}
