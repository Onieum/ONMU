package com.onmu.api.web;

import com.onmu.api.service.RecordService;
import com.onmu.api.web.dto.CreateRecordRequest;
import jakarta.validation.Valid;
import java.util.List;
import java.util.Map;
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
@RequestMapping("/api/v1")
public class RecordController {
  private final RecordService recordService;

  public RecordController(RecordService recordService) {
    this.recordService = recordService;
  }

  @PostMapping("/groups/{groupId}/plans/{planId}/records")
  public ResponseEntity<Map<String, Object>> createRecord(
    @PathVariable String groupId,
    @PathVariable String planId,
    @Valid @RequestBody CreateRecordRequest request
  ) {
    Map<String, Object> result = recordService.createRecord(groupId, planId, request);
    return ResponseEntity.status(HttpStatus.CREATED).body(result);
  }

  @GetMapping("/users/me/records/recent")
  public ResponseEntity<List<Map<String, Object>>> getRecentRecords() {
    List<Map<String, Object>> result = recordService.getRecentRecords();
    return ResponseEntity.ok(result);
  }

  @GetMapping("/records/{recordId}")
  public ResponseEntity<Map<String, Object>> getRecordDetail(@PathVariable String recordId) {
    Map<String, Object> result = recordService.getRecordDetail(recordId);
    return ResponseEntity.ok(result);
  }
}
