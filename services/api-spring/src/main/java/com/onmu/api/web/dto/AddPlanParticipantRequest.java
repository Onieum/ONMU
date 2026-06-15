package com.onmu.api.web.dto;

import jakarta.validation.constraints.NotBlank;

public record AddPlanParticipantRequest(@NotBlank String userId) {
}
