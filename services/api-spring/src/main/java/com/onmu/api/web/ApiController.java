package com.onmu.api.web;

import com.onmu.api.service.OnmuApiService;
import com.onmu.api.service.PlaceSearchService;
import com.onmu.api.web.dto.CreateGroupRequest;
import com.onmu.api.web.dto.CreatePlanRequest;
import com.onmu.api.web.dto.CreateVoteRequest;
import com.onmu.api.web.dto.PlaceSearchRequest;
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
public class ApiController {
  private final OnmuApiService onmuApiService;
  private final PlaceSearchService placeSearchService;

  public ApiController(OnmuApiService onmuApiService, PlaceSearchService placeSearchService) {
    this.onmuApiService = onmuApiService;
    this.placeSearchService = placeSearchService;
  }

  @GetMapping("/home/summary")
  public Map<String, Object> homeSummary() {
    return onmuApiService.homeSummary();
  }

  @GetMapping("/users/me")
  public Map<String, Object> userMe() {
    return onmuApiService.userMe();
  }

  @GetMapping("/groups")
  public List<Map<String, Object>> groups() {
    return onmuApiService.groups();
  }

  @PostMapping("/groups")
  public ResponseEntity<Map<String, Object>> createGroup(@Valid @RequestBody CreateGroupRequest request) {
    return ResponseEntity.status(HttpStatus.CREATED).body(onmuApiService.createGroup(request));
  }

  @GetMapping("/groups/{groupId}/summary")
  public Map<String, Object> groupSummary(@PathVariable String groupId) {
    return onmuApiService.groupSummary(groupId);
  }

  @GetMapping("/groups/{groupId}/plans")
  public List<Map<String, Object>> plans(@PathVariable String groupId) {
    return onmuApiService.plans(groupId);
  }

  @PostMapping("/groups/{groupId}/plans")
  public ResponseEntity<Map<String, Object>> createPlan(
    @PathVariable String groupId,
    @Valid @RequestBody CreatePlanRequest request
  ) {
    return ResponseEntity.status(HttpStatus.CREATED).body(onmuApiService.createPlan(groupId, request));
  }

  @GetMapping("/groups/{groupId}/plans/{planId}")
  public Map<String, Object> plan(@PathVariable String groupId, @PathVariable String planId) {
    return onmuApiService.plan(groupId, planId);
  }

  @PostMapping("/place-search")
  public Map<String, Object> placeSearch(@Valid @RequestBody PlaceSearchRequest request) {
    return Map.of(
      "query", request.query(),
      "canonical", true,
      "results", placeSearchService.search(request.query(), request.groupId(), request.planId())
    );
  }

  @GetMapping("/groups/{groupId}/votes")
  public List<Map<String, Object>> votes(@PathVariable String groupId) {
    return onmuApiService.votes(groupId);
  }

  @PostMapping("/groups/{groupId}/votes")
  public ResponseEntity<Map<String, Object>> createVote(
    @PathVariable String groupId,
    @Valid @RequestBody CreateVoteRequest request
  ) {
    return ResponseEntity.status(HttpStatus.CREATED).body(onmuApiService.createVote(groupId, request));
  }

  @GetMapping("/groups/{groupId}/votes/{voteId}")
  public Map<String, Object> vote(@PathVariable String groupId, @PathVariable String voteId) {
    return onmuApiService.vote(groupId, voteId);
  }
}
