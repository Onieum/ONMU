package com.onmu.api.web;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.onmu.api.security.AuthenticatedUser;
import com.onmu.api.service.OotdAvatarGenerationService;
import com.onmu.api.web.dto.OotdAvatarGenerationRequest;
import com.onmu.api.web.dto.OotdAvatarGenerationResponse;
import java.time.Instant;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

class OotdAvatarGenerationControllerContractTests {
  private static final AuthenticatedUser AUTHENTICATED_USER =
    new AuthenticatedUser(TestAuthenticatedUserArgumentResolver.USER_ID, "user-2");

  private OotdAvatarGenerationService service;
  private MockMvc mvc;

  @BeforeEach
  void setUp() {
    service = mock(OotdAvatarGenerationService.class);
    mvc = MockMvcBuilders
      .standaloneSetup(new OotdAvatarGenerationController(service))
      .setCustomArgumentResolvers(new TestAuthenticatedUserArgumentResolver())
      .build();
  }

  @Test
  void createPassesAuthenticatedUserToService() throws Exception {
    when(service.create(eq(AUTHENTICATED_USER), any(OotdAvatarGenerationRequest.class)))
      .thenReturn(response("pending"));

    mvc.perform(post("/api/v1/ootd/avatar-generations")
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
          {
            "recordId": "memory_123",
            "inputType": "PHOTO_REFERENCE",
            "outfitPhotoStorageKey": "records/media/photo.jpg"
          }
          """))
      .andExpect(status().isAccepted())
      .andExpect(jsonPath("$.jobId").value("ootd_job_123"))
      .andExpect(jsonPath("$.status").value("pending"));

    verify(service).create(eq(AUTHENTICATED_USER), any(OotdAvatarGenerationRequest.class));
  }

  @Test
  void getPassesAuthenticatedUserToService() throws Exception {
    when(service.get(AUTHENTICATED_USER, "ootd_job_123")).thenReturn(response("completed"));

    mvc.perform(get("/api/v1/ootd/avatar-generations/{jobId}", "ootd_job_123"))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.jobId").value("ootd_job_123"))
      .andExpect(jsonPath("$.status").value("completed"));

    verify(service).get(AUTHENTICATED_USER, "ootd_job_123");
  }

  private OotdAvatarGenerationResponse response(String status) {
    Instant now = Instant.parse("2026-06-21T00:00:00Z");
    return new OotdAvatarGenerationResponse(
      "ootd_job_123",
      status,
      "memory_123",
      null,
      null,
      false,
      now,
      now
    );
  }
}
