package com.onmu.api.web;

import com.onmu.api.service.GroupApiService;
import com.onmu.api.service.OnmuApiService;
import com.onmu.api.service.PlaceSearchService;
import com.onmu.api.web.dto.CreateGroupRequest;
import com.onmu.api.web.dto.CreatePlaceCandidateRequest;
import com.onmu.api.web.dto.CreatePlanRequest;
import com.onmu.api.web.dto.CreateSchedulePlaceRequest;
import com.onmu.api.web.dto.CreateVoteRequest;
import com.onmu.api.web.dto.PlaceSearchRequest;
import com.onmu.api.web.dto.SettlementPreviewRequest;
import com.onmu.api.web.dto.UpdateGroupRequest;
import com.onmu.api.web.dto.UpdatePlanRequest;
import com.onmu.api.web.dto.UpdateSettlementDraftRequest;
import com.onmu.api.web.dto.UpdateUserProfileRequest;
import com.onmu.api.web.dto.UpsertPlaceCandidateHeartRequest;
import com.onmu.api.web.dto.UpsertPlanParticipantRequest;
import jakarta.validation.Valid;
import java.util.List;
import java.util.Map;
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
import com.onmu.api.security.AuthenticatedUser;

@Validated
@RestController
@RequestMapping("/api/v1")
public class ApiController {
  private final GroupApiService groupApiService;
  private final OnmuApiService onmuApiService;
  private final PlaceSearchService placeSearchService;

  public ApiController(
    GroupApiService groupApiService,
    OnmuApiService onmuApiService,
    PlaceSearchService placeSearchService
  ) {
    this.groupApiService = groupApiService;
    this.onmuApiService = onmuApiService;
    this.placeSearchService = placeSearchService;
  }

  @GetMapping("/home/summary")
  public Map<String, Object> homeSummary(@AuthenticationPrincipal AuthenticatedUser user) {
    return onmuApiService.homeSummary(user.userId());
  }

  @GetMapping("/users/me")
  public Map<String, Object> userMe(@AuthenticationPrincipal AuthenticatedUser user) {
    return onmuApiService.userMe(user.userId());
  }

  @PatchMapping("/users/me")
  public Map<String, Object> updateUserProfile(
    @AuthenticationPrincipal AuthenticatedUser user,
    @Valid @RequestBody UpdateUserProfileRequest request
  ) {
    return onmuApiService.updateUserProfile(user.userId(), request);
  }

  @GetMapping("/groups")
  public List<Map<String, Object>> groups() {
    return onmuApiService.groups();
  }

  @PostMapping("/groups")
  public ResponseEntity<Map<String, Object>> createGroup(@Valid @RequestBody CreateGroupRequest request) {
    return ResponseEntity.status(HttpStatus.CREATED).body(groupApiService.createGroup(request.name()));
  }

  @GetMapping("/groups/{groupId}")
  public Map<String, Object> groupDetail(@PathVariable String groupId) {
    return groupApiService.groupDetail(groupId);
  }

  @PatchMapping("/groups/{groupId}")
  public Map<String, Object> updateGroup(
    @PathVariable String groupId,
    @RequestBody(required = false) UpdateGroupRequest request
  ) {
    return groupApiService.updateGroup(groupId, request);
  }

  @GetMapping("/groups/{groupId}/members")
  public List<Map<String, Object>> groupMembers(@PathVariable String groupId) {
    return groupApiService.members(groupId);
  }

  @DeleteMapping("/groups/{groupId}/members/me")
  public ResponseEntity<Void> leaveGroup(@PathVariable String groupId) {
    groupApiService.leaveGroup(groupId);
    return ResponseEntity.noContent().build();
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

  @PatchMapping("/groups/{groupId}/plans/{planId}")
  public Map<String, Object> updatePlan(
    @PathVariable String groupId,
    @PathVariable String planId,
    @RequestBody(required = false) UpdatePlanRequest request
  ) {
    return onmuApiService.updatePlan(groupId, planId, request);
  }

  @GetMapping("/groups/{groupId}/plans/{planId}/participants")
  public List<Map<String, Object>> planParticipants(
    @PathVariable String groupId,
    @PathVariable String planId
  ) {
    return onmuApiService.planParticipants(groupId, planId);
  }

  @PutMapping("/groups/{groupId}/plans/{planId}/participants/me")
  public Map<String, Object> putMyPlanParticipant(
    @PathVariable String groupId,
    @PathVariable String planId,
    @RequestBody(required = false) UpsertPlanParticipantRequest request
  ) {
    return onmuApiService.upsertMyPlanParticipant(groupId, planId, request);
  }

  @PatchMapping("/groups/{groupId}/plans/{planId}/participants/me")
  public Map<String, Object> patchMyPlanParticipant(
    @PathVariable String groupId,
    @PathVariable String planId,
    @RequestBody(required = false) UpsertPlanParticipantRequest request
  ) {
    return onmuApiService.upsertMyPlanParticipant(groupId, planId, request);
  }

  @PostMapping("/place-search")
  public Map<String, Object> placeSearch(@Valid @RequestBody PlaceSearchRequest request) {
    return Map.of(
      "query", request.query(),
      "canonical", true,
      "results", placeSearchService.search(
        request.query(),
        request.groupId(),
        request.planId(),
        request.lat(),
        request.lng(),
        request.radius(),
        request.category()
      )
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

  @GetMapping("/groups/{groupId}/plans/{planId}/place-candidates")
  public List<Map<String, Object>> placeCandidates(@PathVariable String groupId, @PathVariable String planId) {
    return onmuApiService.placeCandidates(groupId, planId);
  }

  @PostMapping("/groups/{groupId}/plans/{planId}/place-candidates")
  public ResponseEntity<Map<String, Object>> createPlaceCandidate(
    @PathVariable String groupId,
    @PathVariable String planId,
    @Valid @RequestBody CreatePlaceCandidateRequest request
  ) {
    return ResponseEntity.status(HttpStatus.CREATED)
      .body(onmuApiService.createPlaceCandidate(groupId, planId, request));
  }

  @GetMapping("/groups/{groupId}/plans/{planId}/place-candidates/{candidateId}")
  public Map<String, Object> placeCandidate(
    @PathVariable String groupId,
    @PathVariable String planId,
    @PathVariable String candidateId
  ) {
    return onmuApiService.placeCandidate(groupId, planId, candidateId);
  }

  @PutMapping("/groups/{groupId}/plans/{planId}/place-candidates/{candidateId}/heart")
  public Map<String, Object> putMyPlaceCandidateHeart(
    @PathVariable String groupId,
    @PathVariable String planId,
    @PathVariable String candidateId,
    @RequestBody(required = false) UpsertPlaceCandidateHeartRequest request
  ) {
    return onmuApiService.upsertMyPlaceCandidateHeart(groupId, planId, candidateId, request);
  }

  @PostMapping("/groups/{groupId}/plans/{planId}/schedule-places")
  public ResponseEntity<Map<String, Object>> createSchedulePlace(
    @PathVariable String groupId,
    @PathVariable String planId,
    @Valid @RequestBody CreateSchedulePlaceRequest request
  ) {
    return ResponseEntity.status(HttpStatus.CREATED)
      .body(onmuApiService.createSchedulePlace(groupId, planId, request));
  }

  @GetMapping("/groups/{groupId}/plans/{planId}/schedule-places")
  public List<Map<String, Object>> schedulePlaces(@PathVariable String groupId, @PathVariable String planId) {
    return onmuApiService.schedulePlaces(groupId, planId);
  }

  @GetMapping("/groups/{groupId}/plans/{planId}/settlement-draft")
  public Map<String, Object> settlementDraft(@PathVariable String groupId, @PathVariable String planId) {
    return onmuApiService.settlementDraft(groupId, planId);
  }

  @PatchMapping("/groups/{groupId}/plans/{planId}/settlement-draft")
  public Map<String, Object> updateSettlementDraft(
    @PathVariable String groupId,
    @PathVariable String planId,
    @RequestBody(required = false) UpdateSettlementDraftRequest request
  ) {
    return onmuApiService.updateSettlementDraft(
      groupId,
      planId,
      request == null ? new UpdateSettlementDraftRequest(List.of(), null) : request
    );
  }

  @PostMapping("/groups/{groupId}/plans/{planId}/settlements/preview")
  public Map<String, Object> previewSettlement(
    @PathVariable String groupId,
    @PathVariable String planId,
    @RequestBody(required = false) SettlementPreviewRequest request
  ) {
    return onmuApiService.previewSettlement(
      groupId,
      planId,
      request == null ? new SettlementPreviewRequest(List.of()) : request
    );
  }

  @PostMapping("/groups/{groupId}/plans/{planId}/settlements")
  public ResponseEntity<Map<String, Object>> createSettlement(
    @PathVariable String groupId,
    @PathVariable String planId,
    @RequestBody(required = false) SettlementPreviewRequest request
  ) {
    return ResponseEntity.status(HttpStatus.CREATED).body(onmuApiService.createSettlement(
      groupId,
      planId,
      request == null ? new SettlementPreviewRequest(List.of()) : request
    ));
  }

  @GetMapping("/groups/{groupId}/plans/{planId}/settlements")
  public Map<String, Object> settlement(@PathVariable String groupId, @PathVariable String planId) {
    return onmuApiService.settlement(groupId, planId);
  }
}
