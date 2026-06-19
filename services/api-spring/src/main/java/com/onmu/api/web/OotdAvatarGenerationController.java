package com.onmu.api.web;

import com.onmu.api.service.OotdAvatarGenerationService;
import com.onmu.api.web.dto.OotdAvatarGenerationRequest;
import com.onmu.api.web.dto.OotdAvatarGenerationResponse;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
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
  private final OotdAvatarGenerationService service;

  public OotdAvatarGenerationController(OotdAvatarGenerationService service) {
    this.service = service;
  }

  @PostMapping
  public ResponseEntity<OotdAvatarGenerationResponse> create(
    @Valid @RequestBody OotdAvatarGenerationRequest request
  ) {
    return ResponseEntity.status(HttpStatus.ACCEPTED).body(service.create(request));
  }

  @GetMapping("/{jobId}")
  public ResponseEntity<OotdAvatarGenerationResponse> get(@PathVariable String jobId) {
    return ResponseEntity.ok(service.get(jobId));
  }
}
