package com.onmu.api.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assertions.assertThrows;

import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

class MediaServiceTests {
  @Test
  void publicSeedMediaRejectsKeysOutsideDevRecordPrefix() {
    ResponseStatusException exception = assertThrows(
      ResponseStatusException.class,
      () -> MediaService.validatePublicSeedMediaKey("records/media/not-public.jpg")
    );

    assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
  }
}
