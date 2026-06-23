package com.onmu.api.web;

import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.onmu.api.config.SecurityConfig;
import com.onmu.api.domain.UserRepository;
import com.onmu.api.security.AccessTokenVerifier;
import com.onmu.api.security.BearerTokenAuthenticationFilter;
import com.onmu.api.service.PlaceImageService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.HttpStatus;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.web.server.ResponseStatusException;

@WebMvcTest(controllers = PlaceImageController.class)
@Import({SecurityConfig.class, BearerTokenAuthenticationFilter.class})
@TestPropertySource(properties = {
  "onmu.auth.access-token-secret=test-signing-key-with-enough-length",
  "onmu.access-log.path=target/test-place-image-controller-api-access.log"
})
class PlaceImageControllerTests {
  @Autowired
  private MockMvc mvc;

  @MockitoBean
  private PlaceImageService placeImageService;

  @MockitoBean
  private AccessTokenVerifier accessTokenVerifier;

  @MockitoBean
  private UserRepository userRepository;

  @Test
  void publicCatalogImageReadDoesNotRequireBearerToken() throws Exception {
    when(placeImageService.readPublicPlaceImage("onmu_catalog", "tour-1"))
      .thenReturn(new PlaceImageService.PublicPlaceImage(new byte[] {1, 2, 3}, "image/jpeg"));

    mvc.perform(get("/api/v1/place-images/public")
        .queryParam("provider", "onmu_catalog")
        .queryParam("providerPlaceId", "tour-1"))
      .andExpect(status().isOk())
      .andExpect(content().contentType("image/jpeg"))
      .andExpect(content().bytes(new byte[] {1, 2, 3}))
      .andExpect(header().string("Cache-Control", org.hamcrest.Matchers.containsString("max-age=86400")));
  }

  @Test
  void missingCatalogImageReturnsNotFound() throws Exception {
    when(placeImageService.readPublicPlaceImage("onmu_catalog", "tour-404"))
      .thenThrow(new ResponseStatusException(HttpStatus.NOT_FOUND, "place_image_not_found"));

    mvc.perform(get("/api/v1/place-images/public")
        .queryParam("provider", "onmu_catalog")
        .queryParam("providerPlaceId", "tour-404"))
      .andExpect(status().isNotFound());
  }
}
