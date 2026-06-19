package com.onmu.api.web;

import com.onmu.api.service.GroupApiService;
import com.onmu.api.service.OnmuApiService;
import com.onmu.api.service.PlaceSearchService;
import com.onmu.api.service.RouteRecommendationService;
import com.onmu.api.service.SettlementApiService;
import com.onmu.api.web.dto.AddGroupMemberRequest;
import com.onmu.api.web.dto.AddPlanParticipantRequest;
import com.onmu.api.web.dto.CreateGroupRequest;
import com.onmu.api.web.dto.CreatePlaceCandidateRequest;
import com.onmu.api.web.dto.CreatePlanRequest;
import com.onmu.api.web.dto.CreateSchedulePlaceRequest;
import com.onmu.api.web.dto.CreateVoteRequest;
import com.onmu.api.web.dto.PlaceSearchRequest;
import com.onmu.api.web.dto.RouteRecommendationRequest;
import com.onmu.api.web.dto.SettlementPreviewRequest;
import com.onmu.api.web.dto.SubmitVoteResponseRequest;
import com.onmu.api.web.dto.UpdateGroupRequest;
import com.onmu.api.web.dto.UpdatePlanRequest;
import com.onmu.api.web.dto.UpdateSchedulePlaceRequest;
import com.onmu.api.web.dto.UpdateSettlementDraftRequest;
import com.onmu.api.web.dto.UpdateUserProfileRequest;
import com.onmu.api.web.dto.UpdateSettlementItemTargetsRequest;
import com.onmu.api.web.dto.UpsertPlaceCandidateHeartRequest;
import com.onmu.api.web.dto.UpsertPlanParticipantRequest;
import jakarta.validation.Valid;
import java.util.LinkedHashMap;
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
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import com.onmu.api.security.AuthenticatedUser;

@Validated
@RestController
@RequestMapping("/api/v1")
public class ApiController {
  private final GroupApiService groupApiService;
  private final OnmuApiService onmuApiService;
  private final PlaceSearchService placeSearchService;
  private final RouteRecommendationService routeRecommendationService;
  private final SettlementApiService settlementApiService;

  public ApiController(
    OnmuApiService onmuApiService,
    PlaceSearchService placeSearchService,
    RouteRecommendationService routeRecommendationService,
    SettlementApiService settlementApiService,
    GroupApiService groupApiService
  ) {
    this.groupApiService = groupApiService;
    this.onmuApiService = onmuApiService;
    this.placeSearchService = placeSearchService;
    this.routeRecommendationService = routeRecommendationService;
    this.settlementApiService = settlementApiService;
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

  @DeleteMapping("/users/me")
  public Map<String, Object> deleteUser(@AuthenticationPrincipal AuthenticatedUser user) {
    return onmuApiService.deleteUser(user.userId());
  }

  @GetMapping("/groups")
  public List<Map<String, Object>> groups(@AuthenticationPrincipal AuthenticatedUser user) {
    return groupApiService.groups(user.userId());
  }

  @PostMapping("/groups")
  public ResponseEntity<Map<String, Object>> createGroup(
    @AuthenticationPrincipal AuthenticatedUser user,
    @Valid @RequestBody CreateGroupRequest request
  ) {
    return ResponseEntity.status(HttpStatus.CREATED)
      .body(groupApiService.createGroup(user.userId(), request.name(), request.description()));
  }

  @GetMapping("/groups/{groupId}")
  public Map<String, Object> groupDetail(
    @PathVariable String groupId,
    @AuthenticationPrincipal AuthenticatedUser user
  ) {
    return groupApiService.groupDetail(groupId, user.userId());
  }

  @PatchMapping("/groups/{groupId}")
  public Map<String, Object> updateGroup(
    @PathVariable String groupId,
    @AuthenticationPrincipal AuthenticatedUser user,
    @RequestBody(required = false) UpdateGroupRequest request
  ) {
    return groupApiService.updateGroup(groupId, user.userId(), request);
  }

  @GetMapping("/groups/{groupId}/members")
  public List<Map<String, Object>> groupMembers(
    @PathVariable String groupId,
    @AuthenticationPrincipal AuthenticatedUser user
  ) {
    return groupApiService.members(groupId, user.userId());
  }

  @PostMapping("/groups/{groupId}/members")
  public ResponseEntity<Map<String, Object>> addGroupMember(
    @PathVariable String groupId,
    @AuthenticationPrincipal AuthenticatedUser user,
    @RequestBody(required = false) AddGroupMemberRequest request
  ) {
    return ResponseEntity.status(HttpStatus.CREATED)
      .body(groupApiService.addMember(groupId, user.userId(), request));
  }

  @DeleteMapping("/groups/{groupId}/members/me")
  public ResponseEntity<Void> leaveGroup(
    @PathVariable String groupId,
    @AuthenticationPrincipal AuthenticatedUser user
  ) {
    groupApiService.leaveGroup(groupId, user.userId());
    return ResponseEntity.noContent().build();
  }

  @GetMapping("/groups/{groupId}/summary")
  public Map<String, Object> groupSummary(
    @PathVariable String groupId,
    @AuthenticationPrincipal AuthenticatedUser user
  ) {
    return onmuApiService.groupSummary(groupId, user.userId());
  }

  @GetMapping("/groups/{groupId}/plans")
  public List<Map<String, Object>> plans(
    @PathVariable String groupId,
    @AuthenticationPrincipal AuthenticatedUser user
  ) {
    return onmuApiService.plans(groupId, user.userId());
  }

  @PostMapping("/groups/{groupId}/plans")
  public ResponseEntity<Map<String, Object>> createPlan(
    @PathVariable String groupId,
    @AuthenticationPrincipal AuthenticatedUser user,
    @Valid @RequestBody CreatePlanRequest request
  ) {
    return ResponseEntity.status(HttpStatus.CREATED).body(onmuApiService.createPlan(groupId, user.userId(), request));
  }

  @GetMapping("/groups/{groupId}/plans/{planId}")
  public Map<String, Object> plan(
    @PathVariable String groupId,
    @PathVariable String planId,
    @AuthenticationPrincipal AuthenticatedUser user
  ) {
    return onmuApiService.plan(groupId, planId, user.userId());
  }

  @PatchMapping("/groups/{groupId}/plans/{planId}")
  public Map<String, Object> updatePlan(
    @PathVariable String groupId,
    @PathVariable String planId,
    @AuthenticationPrincipal AuthenticatedUser user,
    @RequestBody(required = false) UpdatePlanRequest request
  ) {
    return onmuApiService.updatePlan(groupId, planId, user.userId(), request);
  }

  @GetMapping("/groups/{groupId}/plans/{planId}/participants")
  public List<Map<String, Object>> planParticipants(
    @PathVariable String groupId,
    @PathVariable String planId,
    @AuthenticationPrincipal AuthenticatedUser user
  ) {
    return onmuApiService.planParticipants(groupId, planId, user.userId());
  }

  @PostMapping("/groups/{groupId}/plans/{planId}/participants")
  public ResponseEntity<Map<String, Object>> addPlanParticipant(
    @PathVariable String groupId,
    @PathVariable String planId,
    @AuthenticationPrincipal AuthenticatedUser user,
    @Valid @RequestBody AddPlanParticipantRequest request
  ) {
    return ResponseEntity.status(HttpStatus.CREATED)
      .body(onmuApiService.addPlanParticipant(groupId, planId, user.userId(), request));
  }

  @PutMapping("/groups/{groupId}/plans/{planId}/participants/me")
  public Map<String, Object> putMyPlanParticipant(
    @PathVariable String groupId,
    @PathVariable String planId,
    @AuthenticationPrincipal AuthenticatedUser user,
    @RequestBody(required = false) UpsertPlanParticipantRequest request
  ) {
    return onmuApiService.upsertMyPlanParticipant(groupId, planId, user.userId(), request);
  }

  @PatchMapping("/groups/{groupId}/plans/{planId}/participants/me")
  public Map<String, Object> patchMyPlanParticipant(
    @PathVariable String groupId,
    @PathVariable String planId,
    @AuthenticationPrincipal AuthenticatedUser user,
    @RequestBody(required = false) UpsertPlanParticipantRequest request
  ) {
    return onmuApiService.upsertMyPlanParticipant(groupId, planId, user.userId(), request);
  }

  @PostMapping("/place-search")
  public Map<String, Object> placeSearch(
    @AuthenticationPrincipal AuthenticatedUser user,
    @Valid @RequestBody PlaceSearchRequest request
  ) {
    onmuApiService.plan(request.groupId(), request.planId(), user.userId());
    List<Map<String, Object>> results = placeSearchService.search(
      request.query(),
      request.groupId(),
      request.planId(),
      request.lat(),
      request.lng(),
      request.radius(),
      request.category(),
      request.providers(),
      Boolean.TRUE.equals(request.compare())
    );
    Map<String, Object> response = new LinkedHashMap<>();
    response.put("query", request.query());
    response.put("canonical", true);
    response.put("results", results);
    response.put("provider_counts", countBy(results, "provider"));
    response.put("source_counts", countBy(results, "source"));
    response.put("coordinate_count", coordinateCount(results));
    return response;
  }

  private Map<String, Integer> countBy(List<Map<String, Object>> results, String key) {
    Map<String, Integer> counts = new LinkedHashMap<>();
    for (Map<String, Object> result : results) {
      Object value = result.get(key);
      if (value instanceof String name && !name.isBlank()) {
        counts.merge(name, 1, Integer::sum);
      }
    }
    return counts;
  }

  private long coordinateCount(List<Map<String, Object>> results) {
    return results.stream()
      .filter(result -> result.get("lat") instanceof Number && result.get("lng") instanceof Number)
      .count();
  }

  @PostMapping("/routes/recommend")
  public Map<String, Object> routeRecommend(
    @AuthenticationPrincipal AuthenticatedUser user,
    @Valid @RequestBody RouteRecommendationRequest request
  ) {
    return routeRecommendationService.recommend(request.groupId(), request.planId(), request.travelMode(), user.userId());
  }

  @GetMapping("/groups/{groupId}/votes")
  public List<Map<String, Object>> votes(
    @PathVariable String groupId,
    @AuthenticationPrincipal AuthenticatedUser user,
    @RequestParam(required = false) String targetType,
    @RequestParam(required = false) String targetId
  ) {
    return onmuApiService.votes(groupId, user.userId(), targetType, targetId);
  }

  @PostMapping("/groups/{groupId}/votes")
  public ResponseEntity<Map<String, Object>> createVote(
    @PathVariable String groupId,
    @AuthenticationPrincipal AuthenticatedUser user,
    @Valid @RequestBody CreateVoteRequest request
  ) {
    return ResponseEntity.status(HttpStatus.CREATED).body(onmuApiService.createVote(groupId, user.userId(), request));
  }

  @GetMapping("/groups/{groupId}/votes/{voteId}")
  public Map<String, Object> vote(
    @PathVariable String groupId,
    @PathVariable String voteId,
    @AuthenticationPrincipal AuthenticatedUser user
  ) {
    return onmuApiService.vote(groupId, voteId, user.userId());
  }

  @PostMapping("/groups/{groupId}/votes/{voteId}/responses/me")
  public Map<String, Object> submitMyVoteResponse(
    @PathVariable String groupId,
    @PathVariable String voteId,
    @AuthenticationPrincipal AuthenticatedUser user,
    @Valid @RequestBody SubmitVoteResponseRequest request
  ) {
    return onmuApiService.submitVoteResponse(groupId, voteId, user.userId(), request);
  }

  @GetMapping("/groups/{groupId}/plans/{planId}/place-candidates")
  public List<Map<String, Object>> placeCandidates(
    @PathVariable String groupId,
    @PathVariable String planId,
    @AuthenticationPrincipal AuthenticatedUser user
  ) {
    return onmuApiService.placeCandidates(groupId, planId, user.userId());
  }

  @PostMapping("/groups/{groupId}/plans/{planId}/place-candidates")
  public ResponseEntity<Map<String, Object>> createPlaceCandidate(
    @PathVariable String groupId,
    @PathVariable String planId,
    @AuthenticationPrincipal AuthenticatedUser user,
    @Valid @RequestBody CreatePlaceCandidateRequest request
  ) {
    return ResponseEntity.status(HttpStatus.CREATED)
      .body(onmuApiService.createPlaceCandidate(groupId, planId, user.userId(), request));
  }

  @GetMapping("/groups/{groupId}/plans/{planId}/place-candidates/{candidateId}")
  public Map<String, Object> placeCandidate(
    @PathVariable String groupId,
    @PathVariable String planId,
    @PathVariable String candidateId,
    @AuthenticationPrincipal AuthenticatedUser user
  ) {
    return onmuApiService.placeCandidate(groupId, planId, candidateId, user.userId());
  }

  @PutMapping("/groups/{groupId}/plans/{planId}/place-candidates/{candidateId}/heart")
  public Map<String, Object> putMyPlaceCandidateHeart(
    @PathVariable String groupId,
    @PathVariable String planId,
    @PathVariable String candidateId,
    @AuthenticationPrincipal AuthenticatedUser user,
    @RequestBody(required = false) UpsertPlaceCandidateHeartRequest request
  ) {
    return onmuApiService.upsertMyPlaceCandidateHeart(groupId, planId, candidateId, user.userId(), request);
  }

  @PostMapping("/groups/{groupId}/plans/{planId}/schedule-places")
  public ResponseEntity<Map<String, Object>> createSchedulePlace(
    @PathVariable String groupId,
    @PathVariable String planId,
    @AuthenticationPrincipal AuthenticatedUser user,
    @Valid @RequestBody CreateSchedulePlaceRequest request
  ) {
    return ResponseEntity.status(HttpStatus.CREATED)
      .body(onmuApiService.createSchedulePlace(groupId, planId, user.userId(), request));
  }

  @GetMapping("/groups/{groupId}/plans/{planId}/schedule-places")
  public List<Map<String, Object>> schedulePlaces(
    @PathVariable String groupId,
    @PathVariable String planId,
    @AuthenticationPrincipal AuthenticatedUser user
  ) {
    return onmuApiService.schedulePlaces(groupId, planId, user.userId());
  }

  @PatchMapping("/groups/{groupId}/plans/{planId}/schedule-places/{schedulePlaceId}")
  public Map<String, Object> updateSchedulePlace(
    @PathVariable String groupId,
    @PathVariable String planId,
    @PathVariable String schedulePlaceId,
    @AuthenticationPrincipal AuthenticatedUser user,
    @RequestBody(required = false) UpdateSchedulePlaceRequest request
  ) {
    return onmuApiService.updateSchedulePlace(groupId, planId, schedulePlaceId, user.userId(), request);
  }

  @DeleteMapping("/groups/{groupId}/plans/{planId}/schedule-places/{schedulePlaceId}")
  public ResponseEntity<Void> deleteSchedulePlace(
    @PathVariable String groupId,
    @PathVariable String planId,
    @PathVariable String schedulePlaceId,
    @AuthenticationPrincipal AuthenticatedUser user
  ) {
    onmuApiService.deleteSchedulePlace(groupId, planId, schedulePlaceId, user.userId());
    return ResponseEntity.noContent().build();
  }

  @GetMapping("/groups/{groupId}/plans/{planId}/settlement-draft")
  public Map<String, Object> settlementDraft(
    @PathVariable String groupId,
    @PathVariable String planId,
    @AuthenticationPrincipal AuthenticatedUser user
  ) {
    return settlementApiService.settlementDraft(groupId, planId, user.userId());
  }

  @PatchMapping("/groups/{groupId}/plans/{planId}/settlement-draft")
  public Map<String, Object> updateSettlementDraft(
    @PathVariable String groupId,
    @PathVariable String planId,
    @AuthenticationPrincipal AuthenticatedUser user,
    @RequestBody(required = false) UpdateSettlementDraftRequest request
  ) {
    return settlementApiService.updateSettlementDraft(
      groupId,
      planId,
      user.userId(),
      request == null ? new UpdateSettlementDraftRequest(List.of(), null) : request
    );
  }

  @PatchMapping("/groups/{groupId}/plans/{planId}/settlement-draft/items/{itemId}/targets")
  public Map<String, Object> updateSettlementDraftItemTargets(
    @PathVariable String groupId,
    @PathVariable String planId,
    @PathVariable String itemId,
    @AuthenticationPrincipal AuthenticatedUser user,
    @RequestBody(required = false) UpdateSettlementItemTargetsRequest request
  ) {
    return settlementApiService.updateSettlementDraftItemTargets(
      groupId,
      planId,
      itemId,
      user.userId(),
      request == null ? new UpdateSettlementItemTargetsRequest(List.of(), List.of()) : request
    );
  }

  @PostMapping("/groups/{groupId}/plans/{planId}/settlements/preview")
  public Map<String, Object> previewSettlement(
    @PathVariable String groupId,
    @PathVariable String planId,
    @AuthenticationPrincipal AuthenticatedUser user,
    @RequestBody(required = false) SettlementPreviewRequest request
  ) {
    return settlementApiService.previewSettlement(
      groupId,
      planId,
      user.userId(),
      request == null ? new SettlementPreviewRequest(List.of()) : request
    );
  }

  @PostMapping("/groups/{groupId}/plans/{planId}/settlements")
  public ResponseEntity<Map<String, Object>> createSettlement(
    @PathVariable String groupId,
    @PathVariable String planId,
    @AuthenticationPrincipal AuthenticatedUser user,
    @RequestBody(required = false) SettlementPreviewRequest request
  ) {
    return ResponseEntity.status(HttpStatus.CREATED).body(settlementApiService.createSettlement(
      groupId,
      planId,
      user.userId(),
      request == null ? new SettlementPreviewRequest(List.of()) : request
    ));
  }

  @GetMapping("/groups/{groupId}/plans/{planId}/settlements")
  public Map<String, Object> settlement(
    @PathVariable String groupId,
    @PathVariable String planId,
    @AuthenticationPrincipal AuthenticatedUser user
  ) {
    return settlementApiService.settlement(groupId, planId, user.userId());
  }

  @GetMapping("/groups/{groupId}/plans/{planId}/settlements/{settlementId}")
  public Map<String, Object> settlementById(
    @PathVariable String groupId,
    @PathVariable String planId,
    @PathVariable String settlementId,
    @AuthenticationPrincipal AuthenticatedUser user
  ) {
    return settlementApiService.settlementById(groupId, planId, settlementId, user.userId());
  }
}
