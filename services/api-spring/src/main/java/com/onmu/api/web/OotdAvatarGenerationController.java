package com.onmu.api.web;

import com.onmu.api.security.AuthenticatedUser;
import com.onmu.api.service.OotdAvatarGenerationService;
import com.onmu.api.web.dto.OotdAvatarGenerationRequest;
import com.onmu.api.web.dto.OotdAvatarGenerationResponse;
import jakarta.validation.Valid;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@Validated
@RestController
@RequestMapping("/api/v1/ootd/avatar-generations")
public class OotdAvatarGenerationController {
  private static final Logger log = LoggerFactory.getLogger(OotdAvatarGenerationController.class);

  private final OotdAvatarGenerationService service;

  public OotdAvatarGenerationController(OotdAvatarGenerationService service) {
    this.service = service;
  }

  @PostMapping
  public ResponseEntity<OotdAvatarGenerationResponse> create(
    @AuthenticationPrincipal AuthenticatedUser user,
    @Valid @RequestBody OotdAvatarGenerationRequest request
  ) {
    log.info(
      "ootd avatar generation create requested recordId={} inputType={} hasPhoto={} hasPhotoStorageKey={} hasText={}",
      request.recordId(),
      request.inputType(),
      request.outfitPhotoMediaId() != null,
      request.outfitPhotoStorageKey() != null && !request.outfitPhotoStorageKey().isBlank(),
      request.outfitDescription() != null && !request.outfitDescription().isBlank()
    );
    OotdAvatarGenerationResponse response = service.create(user, request);
    log.info(
      "ootd avatar generation create accepted jobId={} recordId={} status={}",
      response.jobId(),
      response.recordId(),
      response.status()
    );
    return ResponseEntity.status(HttpStatus.ACCEPTED).body(response);
  }

  @GetMapping("/{jobId}")
  public ResponseEntity<OotdAvatarGenerationResponse> get(
    @AuthenticationPrincipal AuthenticatedUser user,
    @PathVariable String jobId
  ) {
    OotdAvatarGenerationResponse response = service.get(user, jobId);
    log.info(
      "ootd avatar generation get jobId={} recordId={} status={} errorCode={}",
      response.jobId(),
      response.recordId(),
      response.status(),
      response.errorCode()
    );
    return ResponseEntity.ok(response);
  }
}
