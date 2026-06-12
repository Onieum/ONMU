package com.onmu.api.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assertions.assertThrows;

import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

class MediaServiceTests {
  @Test
  void publicMediaAllowsUploadedRecordMediaKeys() {
    assertThat(MediaService.publicMediaUrl("records/media/photo.jpg"))
      .isEqualTo("/api/v1/media/public?key=records%2Fmedia%2Fphoto.jpg");
  }

  @Test
  void publicMediaRejectsKeysOutsideAllowedPrefixes() {
    ResponseStatusException exception = assertThrows(
      ResponseStatusException.class,
      () -> MediaService.validatePublicSeedMediaKey("private/media/not-public.jpg")
    );

    assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
  }

  @Test
  void publicMediaRejectsPathTraversalKeys() {
    ResponseStatusException exception = assertThrows(
      ResponseStatusException.class,
      () -> MediaService.validatePublicSeedMediaKey("records/media/../secret.jpg")
    );

    assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
  }
}
