package com.onmu.api.web;

import com.onmu.api.service.RecordService;
import com.onmu.api.web.dto.OotdCallbackRequest;
import jakarta.validation.Valid;
import java.util.Map;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@Validated
@RestController
@RequestMapping("/api/v1/internal/callbacks")
public class InternalCallbackController {
  private final RecordService recordService;

  public InternalCallbackController(RecordService recordService) {
    this.recordService = recordService;
  }

  @PostMapping("/ootd")
  public ResponseEntity<Map<String, Object>> ootdCallback(
    @Valid @RequestBody OotdCallbackRequest request
  ) {
    Map<String, Object> result = recordService.processOotdCallback(request);
    return ResponseEntity.ok(result);
  }
}
