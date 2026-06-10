package com.onmu.api.web;

import com.onmu.api.service.RecordService;
import com.onmu.api.web.dto.CreateMemoryRequest;
import com.onmu.api.web.dto.MemoryResponse;
import jakarta.validation.Valid;
import java.util.List;
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
public class MemoryController {
  private final RecordService recordService;

  public MemoryController(RecordService recordService) {
    this.recordService = recordService;
  }

  @GetMapping("/memories")
  public ResponseEntity<List<MemoryResponse>> getMemories() {
    List<MemoryResponse> response = recordService.getPersonalMemories();
    return ResponseEntity.ok(response);
  }

  @PostMapping("/memories")
  public ResponseEntity<MemoryResponse> createMemory(
      @Valid @RequestBody CreateMemoryRequest request
  ) {
    MemoryResponse response = recordService.createMemory(null, request);
    return ResponseEntity.status(HttpStatus.CREATED).body(response);
  }

  @GetMapping("/memories/{memoryId}")
  public ResponseEntity<MemoryResponse> getMemoryDetail(@PathVariable String memoryId) {
    MemoryResponse response = recordService.getMemoryDetail(memoryId);
    return ResponseEntity.ok(response);
  }

  @GetMapping("/groups/{groupId}/memories")
  public ResponseEntity<List<MemoryResponse>> getGroupMemories(@PathVariable String groupId) {
    List<MemoryResponse> response = recordService.getGroupMemories(groupId);
    return ResponseEntity.ok(response);
  }

  @PostMapping("/groups/{groupId}/memories")
  public ResponseEntity<MemoryResponse> createGroupMemory(
      @PathVariable String groupId,
      @Valid @RequestBody CreateMemoryRequest request
  ) {
    MemoryResponse response = recordService.createMemory(groupId, request);
    return ResponseEntity.status(HttpStatus.CREATED).body(response);
  }

  @GetMapping("/groups/{groupId}/memories/{memoryId}")
  public ResponseEntity<MemoryResponse> getGroupMemoryDetail(
      @PathVariable String groupId,
      @PathVariable String memoryId
  ) {
    MemoryResponse response = recordService.getGroupMemoryDetail(groupId, memoryId);
    return ResponseEntity.ok(response);
  }
}
