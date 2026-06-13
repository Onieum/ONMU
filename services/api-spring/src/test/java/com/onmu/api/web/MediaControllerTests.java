package com.onmu.api.web;

import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.onmu.api.config.SecurityConfig;
import com.onmu.api.domain.UserRepository;
import com.onmu.api.security.AccessTokenVerifier;
import com.onmu.api.security.BearerTokenAuthenticationFilter;
import com.onmu.api.service.MediaService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.HttpStatus;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.web.server.ResponseStatusException;

@WebMvcTest(controllers = MediaController.class)
@Import({SecurityConfig.class, BearerTokenAuthenticationFilter.class})
@TestPropertySource(properties = {
  "onmu.auth.access-token-secret=test-signing-key-with-enough-length",
  "onmu.access-log.path=target/test-media-controller-api-access.log"
})
class MediaControllerTests {
  @Autowired
  private MockMvc mvc;

  @MockitoBean
  private MediaService mediaService;

  @MockitoBean
  private AccessTokenVerifier accessTokenVerifier;

  @MockitoBean
  private UserRepository userRepository;

  @Test
  void publicSeedMediaReadDoesNotRequireBearerToken() throws Exception {
    when(mediaService.readPublicSeedMedia("dev/media/records/memory-1001/image-1.jpg"))
      .thenReturn(new MediaService.PublicMediaObject(new byte[] {1, 2, 3}, "image/jpeg"));

    mvc.perform(get("/api/v1/media/public")
        .queryParam("key", "dev/media/records/memory-1001/image-1.jpg"))
      .andExpect(status().isOk())
      .andExpect(content().contentType("image/jpeg"))
      .andExpect(content().bytes(new byte[] {1, 2, 3}));
  }

  @Test
  void publicAvatarMediaReadDoesNotRequireBearerToken() throws Exception {
    when(mediaService.readPublicSeedMedia("dev/avatars/user-me.png"))
      .thenReturn(new MediaService.PublicMediaObject(new byte[] {4, 5, 6}, "image/png"));

    mvc.perform(get("/api/v1/media/public")
        .queryParam("key", "dev/avatars/user-me.png"))
      .andExpect(status().isOk())
      .andExpect(content().contentType("image/png"))
      .andExpect(content().bytes(new byte[] {4, 5, 6}));
  }

  @Test
  void missingPublicSeedMediaReturnsNotFound() throws Exception {
    when(mediaService.readPublicSeedMedia("dev/media/records/memory-404/image-1.jpg"))
      .thenThrow(new ResponseStatusException(HttpStatus.NOT_FOUND, "media_not_found"));

    mvc.perform(get("/api/v1/media/public")
        .queryParam("key", "dev/media/records/memory-404/image-1.jpg"))
      .andExpect(status().isNotFound());
  }

  @Test
  void disallowedPublicSeedMediaPrefixReturnsBadRequest() throws Exception {
    when(mediaService.readPublicSeedMedia("private/media/not-public.jpg"))
      .thenThrow(new ResponseStatusException(HttpStatus.BAD_REQUEST, "invalid_media_key_prefix"));

    mvc.perform(get("/api/v1/media/public")
        .queryParam("key", "private/media/not-public.jpg"))
      .andExpect(status().isBadRequest());
  }
}
