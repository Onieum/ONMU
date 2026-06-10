package com.onmu.api.web;

import com.onmu.api.service.RecordService;
import com.onmu.api.web.dto.OotdCallbackRequest;
import jakarta.validation.Valid;
import java.util.Map;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

@Validated
@RestController
@RequestMapping("/api/v1/internal/callbacks")
public class InternalCallbackController {
  private final RecordService recordService;
  private final String internalSecret;

  public InternalCallbackController(
      RecordService recordService,
      @Value("${ONMU_INTERNAL_SECRET:onmu-internal-secret-key}") String internalSecret
  ) {
    this.recordService = recordService;
    this.internalSecret = internalSecret;
  }

  @PostMapping("/ootd")
  public ResponseEntity<Map<String, Object>> ootdCallback(
    @RequestHeader(value = "X-Internal-Secret", required = false) String secret,
    @Valid @RequestBody OotdCallbackRequest request
  ) {
    if (secret == null || !secret.equals(internalSecret)) {
      throw new ResponseStatusException(HttpStatus.FORBIDDEN, "forbidden_internal_only");
    }
    Map<String, Object> result = recordService.processOotdCallback(request);
    return ResponseEntity.ok(result);
  }
}
