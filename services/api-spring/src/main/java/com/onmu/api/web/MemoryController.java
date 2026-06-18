package com.onmu.api.web;

import com.onmu.api.security.AuthenticatedUser;
import com.onmu.api.service.RecordService;
import com.onmu.api.web.dto.CreateMemoryRequest;
import com.onmu.api.web.dto.MemoryResponse;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
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
  public ResponseEntity<List<MemoryResponse>> getMemories(
      @AuthenticationPrincipal AuthenticatedUser user
  ) {
    List<MemoryResponse> response = recordService.getPersonalMemories(user.userId());
    return ResponseEntity.ok(response);
  }

  @PostMapping("/memories")
  public ResponseEntity<MemoryResponse> createMemory(
      @AuthenticationPrincipal AuthenticatedUser user,
      @Valid @RequestBody CreateMemoryRequest request
  ) {
    MemoryResponse response = recordService.createMemory(user.userId(), null, request);
    return ResponseEntity.status(HttpStatus.CREATED).body(response);
  }

  @GetMapping("/memories/{memoryId}")
  public ResponseEntity<MemoryResponse> getMemoryDetail(
      @PathVariable String memoryId,
      @AuthenticationPrincipal AuthenticatedUser user
  ) {
    MemoryResponse response = recordService.getMemoryDetail(user.userId(), memoryId);
    return ResponseEntity.ok(response);
  }

  @PutMapping("/memories/{memoryId}")
  public ResponseEntity<MemoryResponse> updateMemory(
      @PathVariable String memoryId,
      @AuthenticationPrincipal AuthenticatedUser user,
      @Valid @RequestBody CreateMemoryRequest request
  ) {
    MemoryResponse response = recordService.updateMemory(user.userId(), memoryId, request);
    return ResponseEntity.ok(response);
  }

  @PatchMapping("/memories/{memoryId}")
  public ResponseEntity<MemoryResponse> patchMemory(
      @PathVariable String memoryId,
      @AuthenticationPrincipal AuthenticatedUser user,
      @Valid @RequestBody CreateMemoryRequest request
  ) {
    MemoryResponse response = recordService.updateMemory(user.userId(), memoryId, request);
    return ResponseEntity.ok(response);
  }

  @DeleteMapping("/memories/{memoryId}")
  public ResponseEntity<Void> deleteMemory(
      @PathVariable String memoryId,
      @AuthenticationPrincipal AuthenticatedUser user
  ) {
    recordService.deleteMemory(user.userId(), memoryId);
    return ResponseEntity.noContent().build();
  }

  @GetMapping("/groups/{groupId}/memories")
  public ResponseEntity<List<MemoryResponse>> getGroupMemories(
      @PathVariable String groupId,
      @AuthenticationPrincipal AuthenticatedUser user
  ) {
    List<MemoryResponse> response = recordService.getGroupMemories(user.userId(), groupId);
    return ResponseEntity.ok(response);
  }

  @PostMapping("/groups/{groupId}/memories")
  public ResponseEntity<MemoryResponse> createGroupMemory(
      @PathVariable String groupId,
      @AuthenticationPrincipal AuthenticatedUser user,
      @Valid @RequestBody CreateMemoryRequest request
  ) {
    MemoryResponse response = recordService.createMemory(user.userId(), groupId, request);
    return ResponseEntity.status(HttpStatus.CREATED).body(response);
  }

  @GetMapping("/groups/{groupId}/memories/{memoryId}")
  public ResponseEntity<MemoryResponse> getGroupMemoryDetail(
      @PathVariable String groupId,
      @PathVariable String memoryId,
      @AuthenticationPrincipal AuthenticatedUser user
  ) {
    MemoryResponse response = recordService.getGroupMemoryDetail(user.userId(), groupId, memoryId);
    return ResponseEntity.ok(response);
  }
}
