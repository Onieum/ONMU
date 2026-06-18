package com.onmu.api.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.onmu.api.domain.AuthIdentityEntity;
import com.onmu.api.domain.AuthIdentityRepository;
import com.onmu.api.domain.ExternalPlaceEntity;
import com.onmu.api.domain.ExternalPlaceRepository;
import com.onmu.api.domain.GroupEntity;
import com.onmu.api.domain.GroupRepository;
import com.onmu.api.domain.PlaceCandidateEntity;
import com.onmu.api.domain.PlaceCandidateHeartEntity;
import com.onmu.api.domain.PlaceCandidateHeartRepository;
import com.onmu.api.domain.PlaceCandidateRepository;
import com.onmu.api.domain.PlanParticipantEntity;
import com.onmu.api.domain.PlanParticipantRepository;
import com.onmu.api.domain.PlanEntity;
import com.onmu.api.domain.PlanRepository;
import com.onmu.api.domain.SchedulePlaceEntity;
import com.onmu.api.domain.SchedulePlaceRepository;
import com.onmu.api.domain.SettlementDraftEntity;
import com.onmu.api.domain.SettlementDraftRepository;
import com.onmu.api.domain.SettlementEntity;
import com.onmu.api.domain.SettlementRepository;
import com.onmu.api.domain.UserEntity;
import com.onmu.api.domain.UserRepository;
import com.onmu.api.domain.VoteEntity;
import com.onmu.api.domain.VoteOptionEntity;
import com.onmu.api.domain.VoteOptionRepository;
import com.onmu.api.domain.VoteResponseEntity;
import com.onmu.api.domain.VoteResponseRepository;
import com.onmu.api.domain.VoteRepository;
import com.onmu.api.web.dto.AddPlanParticipantRequest;
import com.onmu.api.web.dto.CreatePlaceCandidateRequest;
import com.onmu.api.web.dto.CreatePlanRequest;
import com.onmu.api.web.dto.CreateSchedulePlaceRequest;
import com.onmu.api.web.dto.CreateVoteRequest;
import com.onmu.api.web.dto.SettlementDraftItemRequest;
import com.onmu.api.web.dto.SettlementPreviewRequest;
import com.onmu.api.web.dto.SubmitVoteResponseRequest;
import com.onmu.api.web.dto.UpdatePlanRequest;
import com.onmu.api.web.dto.UpdateSettlementDraftRequest;
import com.onmu.api.web.dto.UpdateUserProfileRequest;
import com.onmu.api.web.dto.UpsertPlaceCandidateHeartRequest;
import com.onmu.api.web.dto.UpsertPlanParticipantRequest;
import java.time.Instant;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
public class OnmuApiService {
  private static final DateTimeFormatter DATE_LABEL = DateTimeFormatter.ofPattern("M월 d일").withZone(ZoneOffset.UTC);

  private final UserRepository userRepository;
  private final AuthIdentityRepository authIdentityRepository;
  private final GroupRepository groupRepository;
  private final PlanRepository planRepository;
  private final VoteRepository voteRepository;
  private final ExternalPlaceRepository externalPlaceRepository;
  private final PlaceCandidateRepository placeCandidateRepository;
  private final PlaceCandidateHeartRepository placeCandidateHeartRepository;
  private final SchedulePlaceRepository schedulePlaceRepository;
  private final PlanParticipantRepository planParticipantRepository;
  private final SettlementDraftRepository settlementDraftRepository;
  private final SettlementRepository settlementRepository;
  private final VoteOptionRepository voteOptionRepository;
  private final VoteResponseRepository voteResponseRepository;
  private final OutboxService outboxService;
  private final UserCodeService userCodeService;
  private final ObjectMapper objectMapper;

  public OnmuApiService(
    UserRepository userRepository,
    AuthIdentityRepository authIdentityRepository,
    GroupRepository groupRepository,
    PlanRepository planRepository,
    VoteRepository voteRepository,
    ExternalPlaceRepository externalPlaceRepository,
    PlaceCandidateRepository placeCandidateRepository,
    PlaceCandidateHeartRepository placeCandidateHeartRepository,
    SchedulePlaceRepository schedulePlaceRepository,
    PlanParticipantRepository planParticipantRepository,
    SettlementDraftRepository settlementDraftRepository,
    SettlementRepository settlementRepository,
    VoteOptionRepository voteOptionRepository,
    VoteResponseRepository voteResponseRepository,
    OutboxService outboxService,
    UserCodeService userCodeService,
    ObjectMapper objectMapper
  ) {
    this.userRepository = userRepository;
    this.authIdentityRepository = authIdentityRepository;
    this.groupRepository = groupRepository;
    this.planRepository = planRepository;
    this.voteRepository = voteRepository;
    this.externalPlaceRepository = externalPlaceRepository;
    this.placeCandidateRepository = placeCandidateRepository;
    this.placeCandidateHeartRepository = placeCandidateHeartRepository;
    this.schedulePlaceRepository = schedulePlaceRepository;
    this.planParticipantRepository = planParticipantRepository;
    this.settlementDraftRepository = settlementDraftRepository;
    this.settlementRepository = settlementRepository;
    this.voteOptionRepository = voteOptionRepository;
    this.voteResponseRepository = voteResponseRepository;
    this.outboxService = outboxService;
    this.userCodeService = userCodeService;
    this.objectMapper = objectMapper;
  }

  @Transactional(readOnly = true)
  public Map<String, Object> userMe(java.util.UUID userId) {
    return userMe(userOrThrow(userId));
  }

  @Transactional(readOnly = true)
  public Map<String, Object> userProfile(java.util.UUID userId) {
    UserEntity user = userRepository.findByIdAndDeletedAtIsNull(userId)
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "user_not_found"));

    Map<String, Object> value = new LinkedHashMap<>();
    value.put("id", user.getPublicId());
    value.put("databaseId", user.getId().toString());
    value.put("nickname", nickname(user));
    value.put("profileImageUrl", user.getProfileImageUrl());
    value.put("preferenceProfile", readPreferenceProfile(user.getPreferenceProfile()));
    value.put("pixelCharacter", readJsonObject(user.getPixelCharacter()));
    value.put("onboardingStatus", user.getOnboardingStatus());
    return value;
  }

  private Map<String, Object> userMe(UserEntity user) {
    AuthIdentityEntity identity = authIdentityRepository.findFirstByUserOrderByCreatedAtAsc(user).orElse(null);

    Map<String, Object> value = new LinkedHashMap<>();
    value.put("id", user.getPublicId());
    value.put("databaseId", user.getId().toString());
    value.put("nickname", nickname(user));
    value.put("userCode", userCodeService.findActiveCode(user.getId()).orElse(null));
    value.put("email", user.getEmail());
    value.put("profileImageUrl", user.getProfileImageUrl());
    value.put("preferenceProfile", readPreferenceProfile(user.getPreferenceProfile()));
    value.put("pixelCharacter", readJsonObject(user.getPixelCharacter()));
    value.put("onboardingStatus", user.getOnboardingStatus());
    value.put("authProvider", identity == null ? "NAVER" : identity.getProvider());
    value.put("authStatus", "authenticated");
    value.put("tokenContract", Map.of(
      "accessToken", "issued-by-spring-main-api",
      "refreshToken", "issued-by-spring-main-api",
      "clientStorage", "flutter-secure-storage"
    ));
    return value;
  }

  @Transactional
  public Map<String, Object> updateUserProfile(java.util.UUID userId, UpdateUserProfileRequest request) {
    UserEntity user = userOrThrow(userId);
    user.updateProfile(
      request.nickname(),
      request.profileImageUrl(),
      request.preferenceProfile() == null ? null : toJson(sanitizeProfilePayload(request.preferenceProfile())),
      request.pixelCharacter() == null ? null : toJson(request.pixelCharacter()),
      request.onboardingStatus()
    );
    return userMe(user);
  }

  @Transactional(readOnly = true)
  public Map<String, Object> homeSummary(java.util.UUID userId) {
    UserEntity viewer = userOrThrow(userId);
    List<GroupEntity> groups = groupRepository.findVisibleForUserOrderByCreatedAtAsc(viewer.getId());
    GroupEntity firstGroup = groups.stream().findFirst().orElse(null);
    List<PlanEntity> plans = firstGroup == null ? List.of() : participatingPlans(firstGroup, viewer);
    List<VoteEntity> votes = firstGroup == null ? List.of() : voteRepository.findByGroupOrderByCreatedAtAsc(firstGroup);

    Map<String, Object> value = new LinkedHashMap<>();
    value.put("service", "onmu-api-spring");
    value.put("env", "local");
    value.put("viewer", userMe(viewer));
    value.put("groups", groups.stream().map(this::groupCard).toList());
    value.put("upcomingPlans", plans.stream().map(this::planCard).toList());
    value.put("activeVotes", votes.stream().map(this::voteCard).toList());
    value.put("nextPlan", plans.stream().findFirst().map(this::planCard).orElse(null));
    return value;
  }

  @Transactional(readOnly = true)
  public Map<String, Object> groupSummary(String groupId) {
    GroupEntity group = groupOrThrow(groupId);
    Map<String, Object> value = new LinkedHashMap<>();
    value.put("group", groupCard(group));
    value.put("plans", plans(group.getPublicId()));
    value.put("votes", votes(group.getPublicId()));
    return value;
  }

  @Transactional(readOnly = true)
  public Map<String, Object> groupSummary(String groupId, java.util.UUID userId) {
    GroupAccess access = memberGroup(groupId, userId);
    Map<String, Object> value = new LinkedHashMap<>();
    value.put("group", groupCard(access.group()));
    value.put("plans", plans(access.group().getPublicId(), userId));
    value.put("votes", votes(access.group().getPublicId(), userId, null, null));
    return value;
  }

  @Transactional(readOnly = true)
  public List<Map<String, Object>> plans(String groupId) {
    GroupEntity group = groupOrThrow(groupId);
    return planRepository.findByGroupOrderByStartsAtAsc(group).stream().map(this::planCard).toList();
  }

  @Transactional(readOnly = true)
  public List<Map<String, Object>> plans(String groupId, java.util.UUID userId) {
    GroupAccess access = memberGroup(groupId, userId);
    return participatingPlans(access.group(), access.user()).stream().map(this::planCard).toList();
  }

  private List<PlanEntity> participatingPlans(GroupEntity group, UserEntity user) {
    return planRepository.findParticipatingByGroupAndUser(group, user).stream()
      .filter(plan -> hasActiveParticipant(plan, user))
      .toList();
  }

  private boolean hasActiveParticipant(PlanEntity plan, UserEntity user) {
    return planParticipantRepository.findByPlanAndUser(plan, user)
      .filter(this::isActivePlanParticipant)
      .isPresent();
  }

  @Transactional
  public Map<String, Object> createPlan(String groupId, java.util.UUID userId, CreatePlanRequest request) {
    GroupAccess access = memberGroup(groupId, userId);
    return createPlan(access.group(), access.user(), request);
  }

  private Map<String, Object> createPlan(GroupEntity group, UserEntity creator, CreatePlanRequest request) {
    String publicId = nextPublicId(planRepository.findAll().stream()
      .map(PlanEntity::getPublicId)
      .toList(), 101);
    Instant startsAt = parseInstantOrDefault(request.startsAt());
    Instant endsAt = parseNullableInstant(request.endsAt());
    PlanEntity plan = planRepository.save(new PlanEntity(
      publicId,
      group,
      request.title().trim(),
      startsAt,
      endsAt,
      "draft",
      blankToNull(request.memo()),
      blankToNull(request.placeName())
    ));
    PlanParticipantEntity participant = planParticipantRepository.findByPlanAndUser(plan, creator)
      .orElseGet(() -> new PlanParticipantEntity(plan, creator, "joined", "accepted"));
    participant.update("joined", "accepted");
    planParticipantRepository.save(participant);
    addInitialPlanParticipants(group, plan, creator, request.participantUserIds());
    outboxService.record("plan.created", "plan", plan.getId(), Map.of(
      "groupId", group.getPublicId(),
      "planId", plan.getPublicId(),
      "title", plan.getTitle()
    ));
    return planCard(plan);
  }

  private void addInitialPlanParticipants(
    GroupEntity group,
    PlanEntity plan,
    UserEntity creator,
    List<String> participantUserIds
  ) {
    if (participantUserIds == null || participantUserIds.isEmpty()) {
      return;
    }
    for (String participantUserId : participantUserIds) {
      UserEntity targetUser = userOrThrow(participantUserId);
      if (targetUser.getId().equals(creator.getId())) {
        continue;
      }
      upsertPlanParticipant(group, plan, targetUser, "joined", "accepted");
    }
  }

  @Transactional(readOnly = true)
  public Map<String, Object> plan(String groupId, String planId) {
    return planCard(planOrThrow(groupOrThrow(groupId), planId));
  }

  @Transactional(readOnly = true)
  public Map<String, Object> plan(String groupId, String planId, java.util.UUID userId) {
    GroupEntity group = memberGroup(groupId, userId).group();
    return planCard(planOrThrow(group, planId));
  }

  @Transactional
  public Map<String, Object> updatePlan(String groupId, String planId, UpdatePlanRequest request) {
    GroupEntity group = groupOrThrow(groupId);
    return updatePlan(group, planId, request);
  }

  @Transactional
  public Map<String, Object> updatePlan(
    String groupId,
    String planId,
    java.util.UUID userId,
    UpdatePlanRequest request
  ) {
    GroupEntity group = memberGroup(groupId, userId).group();
    return updatePlan(group, planId, request);
  }

  private Map<String, Object> updatePlan(GroupEntity group, String planId, UpdatePlanRequest request) {
    PlanEntity plan = planOrThrow(group, planId);
    UpdatePlanRequest safeRequest = request == null
      ? new UpdatePlanRequest(null, null, null, null, null, null)
      : request;
    if (safeRequest.title() != null && safeRequest.title().isBlank()) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "blank_plan_title");
    }
    String title = safeRequest.title() == null ? plan.getTitle() : safeRequest.title().trim();
    Instant startsAt = safeRequest.startsAt() == null ? plan.getStartsAt() : parseNullableInstant(safeRequest.startsAt());
    Instant endsAt = safeRequest.endsAt() == null ? plan.getEndsAt() : parseNullableInstant(safeRequest.endsAt());
    String status = safeRequest.status() == null || safeRequest.status().isBlank()
      ? plan.getStatus()
      : safeRequest.status().trim();
    String description = safeRequest.memo() == null ? plan.getDescription() : blankToNull(safeRequest.memo());
    String locationNote = safeRequest.placeName() == null ? plan.getLocationNote() : blankToNull(safeRequest.placeName());
    plan.update(title, startsAt, endsAt, status, description, locationNote);
    outboxService.record("plan.updated", "plan", plan.getId(), Map.of(
      "groupId", group.getPublicId(),
      "planId", plan.getPublicId(),
      "title", plan.getTitle(),
      "status", plan.getStatus()
    ));
    return planCard(plan);
  }

  @Transactional(readOnly = true)
  public List<Map<String, Object>> planParticipants(String groupId, String planId) {
    PlanEntity plan = planOrThrow(groupOrThrow(groupId), planId);
    return planParticipants(plan);
  }

  @Transactional(readOnly = true)
  public List<Map<String, Object>> planParticipants(String groupId, String planId, java.util.UUID userId) {
    GroupEntity group = memberGroup(groupId, userId).group();
    PlanEntity plan = planOrThrow(group, planId);
    return planParticipants(plan);
  }

  private List<Map<String, Object>> planParticipants(PlanEntity plan) {
    List<PlanParticipantEntity> participants = planParticipantRepository.findByPlanOrderByCreatedAtAsc(plan);
    return participants.stream()
      .filter(this::isActivePlanParticipant)
      .map(this::participantCard)
      .toList();
  }

  @Transactional
  public Map<String, Object> upsertMyPlanParticipant(
    String groupId,
    String planId,
    java.util.UUID userId,
    UpsertPlanParticipantRequest request
  ) {
    return upsertMyPlanParticipant(groupId, planId, userOrThrow(userId), request);
  }

  private Map<String, Object> upsertMyPlanParticipant(
    String groupId,
    String planId,
    UserEntity user,
    UpsertPlanParticipantRequest request
  ) {
    GroupEntity group = groupOrThrow(groupId);
    PlanEntity plan = planOrThrow(group, planId);
    if (user.getId() == null || !groupRepository.isUserMember(group.getPublicId(), user.getId())) {
      throw new ResponseStatusException(HttpStatus.FORBIDDEN, "not_group_member");
    }
    UpsertPlanParticipantRequest safeRequest = request == null
      ? new UpsertPlanParticipantRequest(null, null)
      : request;
    PlanParticipantEntity participant = planParticipantRepository.findByPlanAndUser(plan, user)
      .orElseGet(() -> new PlanParticipantEntity(plan, user, "joined", "accepted"));
    participant.update(safeRequest.status(), safeRequest.response());
    PlanParticipantEntity saved = planParticipantRepository.save(participant);
    outboxService.record("plan.participant_updated", "plan_participant", saved.getId(), Map.of(
      "groupId", group.getPublicId(),
      "planId", plan.getPublicId(),
      "userId", user.getId().toString(),
      "status", saved.getStatus(),
      "response", saved.getResponse()
    ));
    return participantCard(saved);
  }

  @Transactional
  public Map<String, Object> addPlanParticipant(
    String groupId,
    String planId,
    java.util.UUID actorUserId,
    AddPlanParticipantRequest request
  ) {
    GroupEntity group = groupOrThrow(groupId);
    PlanEntity plan = planOrThrow(group, planId);
    UserEntity actor = userOrThrow(actorUserId);
    if (actor.getId() == null || !groupRepository.isUserMember(group.getPublicId(), actor.getId())) {
      throw new ResponseStatusException(HttpStatus.FORBIDDEN, "not_group_member");
    }
    UserEntity targetUser = userOrThrow(request.userId());
    PlanParticipantEntity saved = upsertPlanParticipant(group, plan, targetUser, "joined", "accepted");
    return participantCard(saved);
  }

  private PlanParticipantEntity upsertPlanParticipant(
    GroupEntity group,
    PlanEntity plan,
    UserEntity targetUser,
    String status,
    String response
  ) {
    if (targetUser.getId() == null || !groupRepository.isUserMember(group.getPublicId(), targetUser.getId())) {
      throw new ResponseStatusException(HttpStatus.FORBIDDEN, "not_group_member");
    }
    PlanParticipantEntity participant = planParticipantRepository.findByPlanAndUser(plan, targetUser)
      .orElseGet(() -> new PlanParticipantEntity(plan, targetUser, status, response));
    participant.update(status, response);
    PlanParticipantEntity saved = planParticipantRepository.save(participant);
    outboxService.record("plan.participant_added", "plan_participant", saved.getId(), Map.of(
      "groupId", group.getPublicId(),
      "planId", plan.getPublicId(),
      "userId", targetUser.getId().toString(),
      "status", saved.getStatus(),
      "response", saved.getResponse()
    ));
    return saved;
  }

  @Transactional(readOnly = true)
  public List<Map<String, Object>> votes(String groupId) {
    return votes(groupId, null, null);
  }

  @Transactional(readOnly = true)
  public List<Map<String, Object>> votes(String groupId, String targetType, String targetId) {
    GroupEntity group = groupOrThrow(groupId);
    return votes(group, targetType, targetId);
  }

  @Transactional(readOnly = true)
  public List<Map<String, Object>> votes(
    String groupId,
    java.util.UUID userId,
    String targetType,
    String targetId
  ) {
    GroupAccess access = memberGroup(groupId, userId);
    return votes(access.group(), targetType, targetId, access.user());
  }

  private List<Map<String, Object>> votes(GroupEntity group, String targetType, String targetId) {
    return votes(group, targetType, targetId, null);
  }

  private List<Map<String, Object>> votes(
    GroupEntity group,
    String targetType,
    String targetId,
    UserEntity currentUser
  ) {
    String normalizedTargetType = blankToNull(targetType);
    String normalizedTargetId = blankToNull(targetId);
    return voteRepository.findByGroupOrderByCreatedAtAsc(group).stream()
      .filter(vote -> normalizedTargetType == null || normalizedTargetType.equalsIgnoreCase(vote.getTargetType()))
      .filter(vote -> normalizedTargetId == null || normalizedTargetId.equals(vote.getTargetId()))
      .map(vote -> voteCard(vote, null, currentUser))
      .toList();
  }

  @Transactional
  public Map<String, Object> createVote(String groupId, CreateVoteRequest request) {
    return createVote(groupOrThrow(groupId), request);
  }

  @Transactional
  public Map<String, Object> createVote(String groupId, java.util.UUID userId, CreateVoteRequest request) {
    return createVote(memberGroup(groupId, userId).group(), request);
  }

  private Map<String, Object> createVote(GroupEntity group, CreateVoteRequest request) {
    String publicId = nextPublicId(voteRepository.findAll().stream()
      .map(VoteEntity::getPublicId)
      .toList(), 501);
    String targetType = normalizeVoteTargetType(request.targetType());
    String targetId = resolveVoteTargetId(group, targetType, request.targetId());
    PlanEntity targetPlan = "PLAN".equals(targetType) ? planOrThrow(group, targetId) : null;
    List<String> requestedOptions = request.options() == null || request.options().isEmpty()
      ? List.of("A", "B")
      : request.options();
    List<String> candidateIds = voteCandidateIds(request, requestedOptions, targetPlan);
    List<String> options = candidateIds.isEmpty()
      ? requestedOptions
      : candidateIds.stream()
        .map(candidateId -> placeCandidateOrThrow(targetPlan, candidateId).getName())
        .toList();

    VoteEntity vote = voteRepository.save(new VoteEntity(
      publicId,
      group,
      targetType,
      targetId,
      request.voteType().trim(),
      request.title().trim(),
      toJson(Map.of("options", options))
    ));
    List<VoteOptionEntity> savedOptions = saveVoteOptions(vote, targetPlan, options, candidateIds);
    Map<String, Object> outboxPayload = new LinkedHashMap<>();
    outboxPayload.put("groupId", group.getPublicId());
    outboxPayload.put("voteId", vote.getPublicId());
    outboxPayload.put("targetType", vote.getTargetType());
    outboxPayload.put("targetId", vote.getTargetId());
    outboxPayload.put("options", options);
    outboxPayload.put("candidateIds", candidateIds);
    outboxService.record("vote.created", "vote", vote.getId(), outboxPayload);
    return voteCard(vote, savedOptions);
  }

  @Transactional(readOnly = true)
  public Map<String, Object> vote(String groupId, String voteId) {
    return voteCard(voteOrThrow(groupOrThrow(groupId), voteId));
  }

  @Transactional(readOnly = true)
  public Map<String, Object> vote(String groupId, String voteId, java.util.UUID userId) {
    GroupAccess access = memberGroup(groupId, userId);
    return voteCard(voteOrThrow(access.group(), voteId), null, access.user());
  }

  @Transactional
  public Map<String, Object> submitVoteResponse(
    String groupId,
    String voteId,
    java.util.UUID userId,
    SubmitVoteResponseRequest request
  ) {
    GroupAccess access = memberGroup(groupId, userId);
    VoteEntity vote = voteOrThrow(access.group(), voteId);
    if (!"open".equalsIgnoreCase(vote.getStatus())) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "vote_closed");
    }
    VoteOptionEntity option = voteOptionOrThrow(vote, request.optionId());
    List<VoteResponseEntity> existingResponses = voteResponseRepository.findByVoteAndUser(vote, access.user());
    if (!existingResponses.isEmpty()) {
      voteResponseRepository.deleteAll(existingResponses);
    }
    VoteResponseEntity response = voteResponseRepository.save(new VoteResponseEntity(
      vote,
      option,
      access.user(),
      toJson(Map.of("optionId", option.getPublicId()))
    ));
    outboxService.record("vote.response_upserted", "vote_response", response.getId(), Map.of(
      "groupId", access.group().getPublicId(),
      "voteId", vote.getPublicId(),
      "optionId", option.getPublicId(),
      "userId", access.user().getId().toString()
    ));
    return voteCard(vote, voteOptionRepository.findByVoteOrderBySortOrderAsc(vote), access.user());
  }

  @Transactional(readOnly = true)
  public List<Map<String, Object>> placeCandidates(String groupId, String planId, java.util.UUID userId) {
    GroupAccess access = memberGroup(groupId, userId);
    PlanEntity plan = planOrThrow(access.group(), planId);
    return placeCandidateRepository.findByPlanOrderByCreatedAtAsc(plan).stream()
      .map(candidate -> placeCandidateCard(candidate, access.user()))
      .toList();
  }

  @Transactional(readOnly = true)
  public Map<String, Object> placeCandidate(
    String groupId,
    String planId,
    String candidateId,
    java.util.UUID userId
  ) {
    GroupAccess access = memberGroup(groupId, userId);
    PlanEntity plan = planOrThrow(access.group(), planId);
    return placeCandidateCard(placeCandidateOrThrow(plan, candidateId), access.user());
  }

  @Transactional
  public Map<String, Object> createPlaceCandidate(
    String groupId,
    String planId,
    java.util.UUID userId,
    CreatePlaceCandidateRequest request
  ) {
    GroupAccess access = memberGroup(groupId, userId);
    GroupEntity group = access.group();
    PlanEntity plan = planOrThrow(group, planId);
    String publicId = nextPublicId(placeCandidateRepository.findAll().stream()
      .map(PlaceCandidateEntity::getPublicId)
      .toList(), 201);
    ExternalPlaceEntity externalPlace = resolveExternalPlace(request);
    String payload = toJson(placeCandidatePayload(request, externalPlace));
    PlaceCandidateEntity candidate = placeCandidateRepository.save(new PlaceCandidateEntity(
      publicId,
      group,
      plan,
      externalPlace,
      request.name().trim(),
      stringOrDefault(request.category(), "장소"),
      stringOrDefault(request.address(), ""),
      payload
    ));
    outboxService.record("place_candidate.created", "place_candidate", candidate.getId(), Map.of(
      "groupId", group.getPublicId(),
      "planId", plan.getPublicId(),
      "candidateId", candidate.getPublicId(),
      "name", candidate.getName()
    ));
    return placeCandidateCard(candidate, access.user());
  }

  @Transactional
  public Map<String, Object> upsertMyPlaceCandidateHeart(
    String groupId,
    String planId,
    String candidateId,
    java.util.UUID userId,
    UpsertPlaceCandidateHeartRequest request
  ) {
    GroupAccess access = memberGroup(groupId, userId);
    GroupEntity group = access.group();
    PlanEntity plan = planOrThrow(group, planId);
    PlaceCandidateEntity candidate = placeCandidateOrThrow(plan, candidateId);
    UserEntity user = access.user();
    boolean hearted = request == null || request.hearted() == null || request.hearted();
    var existingHeart = placeCandidateHeartRepository.findByCandidateAndUser(candidate, user);
    if (hearted && existingHeart.isEmpty()) {
      placeCandidateHeartRepository.save(new PlaceCandidateHeartEntity(candidate, user));
    }
    if (!hearted) {
      existingHeart.ifPresent(placeCandidateHeartRepository::delete);
    }
    outboxService.record("place_candidate.heart_updated", "place_candidate", candidate.getId(), Map.of(
      "groupId", group.getPublicId(),
      "planId", plan.getPublicId(),
      "candidateId", candidate.getPublicId(),
      "userId", user.getId().toString(),
      "hearted", hearted
    ));
    return placeCandidateCard(candidate, user);
  }

  @Transactional
  public Map<String, Object> createSchedulePlace(
    String groupId,
    String planId,
    java.util.UUID userId,
    CreateSchedulePlaceRequest request
  ) {
    GroupEntity group = memberGroup(groupId, userId).group();
    PlanEntity plan = planOrThrow(group, planId);
    PlaceCandidateEntity candidate = request.candidateId() == null || request.candidateId().isBlank()
      ? null
      : placeCandidateOrThrow(plan, request.candidateId());
    String placeName = request.name() == null || request.name().isBlank()
      ? candidate == null ? null : candidate.getName()
      : request.name().trim();
    if (placeName == null || placeName.isBlank()) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "blank_schedule_place_name");
    }
    String publicId = nextPublicId(schedulePlaceRepository.findAll().stream()
      .map(SchedulePlaceEntity::getPublicId)
      .toList(), 701);
    int sortOrder = schedulePlaceRepository.findByPlanOrderBySortOrderAsc(plan).size() + 1;
    SchedulePlaceEntity schedulePlace = schedulePlaceRepository.save(new SchedulePlaceEntity(
      publicId,
      group,
      plan,
      candidate,
      placeName,
      parseNullableInstant(request.startsAt()),
      parseNullableInstant(request.endsAt()),
      sortOrder,
      blankToNull(request.note())
    ));
    Map<String, Object> outboxPayload = new LinkedHashMap<>();
    outboxPayload.put("groupId", group.getPublicId());
    outboxPayload.put("planId", plan.getPublicId());
    outboxPayload.put("schedulePlaceId", schedulePlace.getPublicId());
    outboxPayload.put(
      "candidateId",
      schedulePlace.getPlaceCandidate() == null ? null : schedulePlace.getPlaceCandidate().getPublicId()
    );
    outboxPayload.put("name", schedulePlace.getName());
    outboxService.record("schedule_place.created", "schedule_place", schedulePlace.getId(), outboxPayload);
    return schedulePlaceCard(group, plan, schedulePlace);
  }

  @Transactional(readOnly = true)
  public List<Map<String, Object>> schedulePlaces(String groupId, String planId, java.util.UUID userId) {
    GroupEntity group = memberGroup(groupId, userId).group();
    PlanEntity plan = planOrThrow(group, planId);
    return schedulePlaceRepository.findByPlanOrderBySortOrderAsc(plan).stream()
      .map(schedulePlace -> schedulePlaceCard(plan.getGroup(), plan, schedulePlace))
      .toList();
  }

  @Transactional
  public void deleteSchedulePlace(
    String groupId,
    String planId,
    String schedulePlaceId,
    java.util.UUID userId
  ) {
    GroupEntity group = memberGroup(groupId, userId).group();
    PlanEntity plan = planOrThrow(group, planId);
    SchedulePlaceEntity schedulePlace = schedulePlaceOrThrow(plan, schedulePlaceId);
    schedulePlaceRepository.delete(schedulePlace);
    outboxService.record("schedule_place.deleted", "schedule_place", schedulePlace.getId(), Map.of(
      "groupId", group.getPublicId(),
      "planId", plan.getPublicId(),
      "schedulePlaceId", schedulePlace.getPublicId()
    ));
  }

  @Transactional(readOnly = true)
  public Map<String, Object> settlementDraft(String groupId, String planId) {
    PlanEntity plan = planOrThrow(groupOrThrow(groupId), planId);
    SettlementDraftEntity draft = settlementDraftRepository.findByPlan(plan)
      .orElseGet(() -> new SettlementDraftEntity("draft", plan.getGroup(), plan, defaultSettlementPayload(plan)));
    return settlementDraftCard(draft);
  }

  @Transactional
  public Map<String, Object> updateSettlementDraft(
    String groupId,
    String planId,
    UpdateSettlementDraftRequest request
  ) {
    GroupEntity group = groupOrThrow(groupId);
    PlanEntity plan = planOrThrow(group, planId);
    requireSettlementItems(request.items());
    SettlementDraftEntity draft = settlementDraftRepository.findByPlan(plan)
      .orElseGet(() -> new SettlementDraftEntity(
        nextPublicId(settlementDraftRepository.findAll().stream()
          .map(SettlementDraftEntity::getPublicId)
          .toList(), 301),
        group,
        plan,
        defaultSettlementPayload(plan)
      ));
    draft.setPayload(toJson(settlementPayloadFromItems(plan, request.items())));
    return settlementDraftCard(settlementDraftRepository.save(draft));
  }

  @Transactional(readOnly = true)
  public Map<String, Object> previewSettlement(String groupId, String planId, SettlementPreviewRequest request) {
    PlanEntity plan = planOrThrow(groupOrThrow(groupId), planId);
    requireSettlementItems(request.items());
    Map<String, Object> payload = settlementPayloadFromItems(plan, request.items());
    return settlementSummaryCard("preview", plan, payload, true);
  }

  @Transactional
  public Map<String, Object> createSettlement(String groupId, String planId, SettlementPreviewRequest request) {
    GroupEntity group = groupOrThrow(groupId);
    PlanEntity plan = planOrThrow(group, planId);
    requireSettlementItems(request.items());
    Map<String, Object> payload = settlementPayloadFromItems(plan, request.items());
    String publicId = nextPublicId(settlementRepository.findAll().stream()
      .map(SettlementEntity::getPublicId)
      .toList(), 301);
    SettlementEntity settlement = settlementRepository.save(new SettlementEntity(
      publicId,
      group,
      plan,
      toJson(payload)
    ));
    outboxService.record("settlement.created", "settlement", settlement.getId(), Map.of(
      "groupId", group.getPublicId(),
      "planId", plan.getPublicId(),
      "settlementId", settlement.getPublicId()
    ));
    outboxService.record("notification.requested", "settlement", settlement.getId(), Map.of(
      "groupId", group.getPublicId(),
      "planId", plan.getPublicId(),
      "settlementId", settlement.getPublicId(),
      "channel", "activity"
    ));
    return settlementSummaryCard(settlement.getPublicId(), plan, payload, false);
  }

  @Transactional(readOnly = true)
  public Map<String, Object> settlement(String groupId, String planId) {
    PlanEntity plan = planOrThrow(groupOrThrow(groupId), planId);
    return settlementRepository.findFirstByPlanOrderByCreatedAtDesc(plan)
      .map(settlement -> settlementSummaryCard(settlement.getPublicId(), plan, readObject(settlement.getPayload()), false))
      .orElseGet(() -> settlementSummaryCard("draft", plan, readObject(defaultSettlementPayload(plan)), true));
  }

  private UserEntity userOrThrow(java.util.UUID userId) {
    return userRepository.findByIdAndDeletedAtIsNull(userId)
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "user_not_found"));
  }

  private UserEntity userOrThrow(String userId) {
    try {
      return userOrThrow(java.util.UUID.fromString(userId));
    } catch (IllegalArgumentException exception) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "invalid_user_id", exception);
    }
  }

  private GroupEntity groupOrThrow(String groupId) {
    return groupRepository.findByPublicId(groupId)
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "group_not_found"));
  }

  private GroupAccess memberGroup(String groupId, java.util.UUID userId) {
    UserEntity user = userOrThrow(userId);
    GroupEntity group = groupOrThrow(groupId);
    if (user.getId() == null || !groupRepository.isUserMember(group.getPublicId(), user.getId())) {
      throw new ResponseStatusException(HttpStatus.FORBIDDEN, "not_group_member");
    }
    return new GroupAccess(group, user);
  }

  private PlanEntity planOrThrow(GroupEntity group, String planId) {
    return planRepository.findByGroupAndPublicId(group, planId)
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "plan_not_found"));
  }

  private VoteEntity voteOrThrow(GroupEntity group, String voteId) {
    return voteRepository.findByGroupAndPublicId(group, voteId)
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "vote_not_found"));
  }

  private VoteOptionEntity voteOptionOrThrow(VoteEntity vote, String optionId) {
    String normalizedOptionId = blankToNull(optionId);
    if (normalizedOptionId == null) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "blank_vote_option_id");
    }
    return voteOptionRepository.findByVoteOrderBySortOrderAsc(vote).stream()
      .filter(option -> normalizedOptionId.equals(option.getPublicId()))
      .findFirst()
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "vote_option_not_found"));
  }

  private PlaceCandidateEntity placeCandidateOrThrow(PlanEntity plan, String candidateId) {
    return placeCandidateRepository.findByPlanAndPublicId(plan, candidateId)
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "place_candidate_not_found"));
  }

  private SchedulePlaceEntity schedulePlaceOrThrow(PlanEntity plan, String schedulePlaceId) {
    return schedulePlaceRepository.findByPlanAndPublicId(plan, schedulePlaceId)
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "schedule_place_not_found"));
  }

  private void requireSettlementItems(List<SettlementDraftItemRequest> items) {
    if (items == null || items.isEmpty()) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "missing_settlement_items");
    }
  }

  private Map<String, Object> groupCard(GroupEntity group) {
    Map<String, Object> value = new LinkedHashMap<>();
    value.put("id", group.getPublicId());
    value.put("name", group.getName());
    value.put("memberCount", 1);
    value.put("memberCountLabel", "1명");
    value.put("role", "owner");
    return value;
  }

  private Map<String, Object> planCard(PlanEntity plan) {
    List<Map<String, Object>> participants = activeParticipantCards(plan);
    Map<String, Object> value = new LinkedHashMap<>();
    value.put("id", plan.getPublicId());
    value.put("groupId", plan.getGroup().getPublicId());
    value.put("title", plan.getTitle());
    value.put("startsAt", plan.getStartsAt() == null ? null : plan.getStartsAt().toString());
    value.put("endsAt", plan.getEndsAt() == null ? null : plan.getEndsAt().toString());
    value.put("dateLabel", plan.getStartsAt() == null ? "일정 미정" : DATE_LABEL.format(plan.getStartsAt()));
    value.put("status", plan.getStatus());
    value.put("placeName", stringOrDefault(plan.getLocationNote(), "장소 미정"));
    value.put("memo", stringOrDefault(plan.getDescription(), ""));
    value.put("participants", participants);
    value.put("members", participants.stream().map(this::memberCard).toList());
    value.put("memberCount", participants.size());
    value.put("memberCountLabel", participants.size() + "명");
    return value;
  }

  private Map<String, Object> voteCard(VoteEntity vote) {
    return voteCard(vote, null);
  }

  private Map<String, Object> voteCard(VoteEntity vote, List<VoteOptionEntity> optionRows) {
    return voteCard(vote, optionRows, null);
  }

  private Map<String, Object> voteCard(VoteEntity vote, List<VoteOptionEntity> optionRows, UserEntity currentUser) {
    Map<String, Object> value = new LinkedHashMap<>();
    value.put("id", vote.getPublicId());
    value.put("groupId", vote.getGroup().getPublicId());
    value.put("title", vote.getTitle());
    value.put("voteType", vote.getVoteType());
    value.put("targetType", vote.getTargetType());
    value.put("targetId", vote.getTargetId());
    value.put("status", vote.getStatus());
    value.put("closed", !"open".equalsIgnoreCase(vote.getStatus()));
    long participantCount = voteResponseRepository.countDistinctUsersByVote(vote);
    value.put("participantCount", Math.toIntExact(participantCount));
    value.put("participantCountLabel", participantCount + "명 참여");
    value.put("options", optionRows == null ? voteOptions(vote, currentUser) : optionRows.stream()
      .map(option -> voteOptionCard(option, currentUser))
      .toList());
    if (currentUser != null) {
      String myOptionId = voteResponseRepository.findFirstByVoteAndUserOrderByCreatedAtDesc(vote, currentUser)
        .map(VoteResponseEntity::getVoteOption)
        .map(VoteOptionEntity::getPublicId)
        .orElse("");
      value.put("myOptionId", myOptionId);
      value.put("joinedByMe", !myOptionId.isBlank());
    }
    return value;
  }

  private List<?> voteOptions(VoteEntity vote) {
    return voteOptions(vote, null);
  }

  private List<?> voteOptions(VoteEntity vote, UserEntity currentUser) {
    List<VoteOptionEntity> optionRows = voteOptionRepository.findByVoteOrderBySortOrderAsc(vote);
    if (optionRows != null && !optionRows.isEmpty()) {
      return optionRows.stream().map(option -> voteOptionCard(option, currentUser)).toList();
    }
    return readOptions(vote.getPayload());
  }

  private Map<String, Object> voteOptionCard(VoteOptionEntity option) {
    return voteOptionCard(option, null);
  }

  private Map<String, Object> voteOptionCard(VoteOptionEntity option, UserEntity currentUser) {
    if ("PLACE_CANDIDATE".equalsIgnoreCase(option.getTargetType()) && option.getVote().getTargetId() != null) {
      return placeCandidateVoteOptionCard(option, currentUser);
    }
    Map<String, Object> value = textVoteOptionCard(option.getLabel());
    value.put("id", option.getPublicId());
    value.put("targetType", stringOrDefault(option.getTargetType(), "TEXT"));
    value.put("targetId", option.getTargetId());
    putVoteResultFields(value, option, currentUser);
    return value;
  }

  private Map<String, Object> placeCandidateVoteOptionCard(VoteOptionEntity option, UserEntity currentUser) {
    GroupEntity group = option.getVote().getGroup();
    PlanEntity plan = planOrThrow(group, option.getVote().getTargetId());
    PlaceCandidateEntity candidate = placeCandidateOrThrow(plan, option.getTargetId());
    Map<String, Object> value = new LinkedHashMap<>();
    value.put("id", option.getPublicId());
    value.put("label", candidate.getName());
    value.put("targetType", option.getTargetType());
    value.put("targetId", option.getTargetId());
    value.put("candidateId", candidate.getPublicId());
    value.put("candidateName", candidate.getName());
    value.put("name", candidate.getName());
    value.put("category", stringOrDefault(candidate.getCategory(), "장소"));
    value.put("address", stringOrDefault(candidate.getAddress(), ""));
    value.put("heartCount", candidateHeartCount(candidate));
    putVoteResultFields(value, option, currentUser);
    return value;
  }

  private Map<String, Object> textVoteOptionCard(String label) {
    Map<String, Object> value = new LinkedHashMap<>();
    value.put("label", label);
    value.put("targetType", "TEXT");
    value.put("responseCount", 0);
    value.put("countLabel", "0표");
    value.put("progress", 0);
    return value;
  }

  private void putVoteResultFields(Map<String, Object> value, VoteOptionEntity option) {
    putVoteResultFields(value, option, null);
  }

  private void putVoteResultFields(Map<String, Object> value, VoteOptionEntity option, UserEntity currentUser) {
    long totalResponses = voteResponseRepository.countByVote(option.getVote());
    long optionResponses = voteResponseRepository.countByVoteOption(option);
    value.put("responseCount", Math.toIntExact(optionResponses));
    value.put("countLabel", optionResponses + "표");
    value.put("progress", totalResponses == 0 ? 0 : (double) optionResponses / totalResponses);
    if (currentUser != null) {
      value.put("selectedByMe", voteResponseRepository.existsByVoteOptionAndUser(option, currentUser));
    }
  }

  private ExternalPlaceEntity resolveExternalPlace(CreatePlaceCandidateRequest request) {
    String provider = normalizeProvider(request.provider());
    String providerPlaceId = blankToNull(request.providerPlaceId());
    if (provider == null || providerPlaceId == null) {
      return null;
    }
    return externalPlaceRepository.findByProviderAndProviderPlaceId(provider, providerPlaceId)
      .orElseGet(() -> externalPlaceRepository.save(new ExternalPlaceEntity(
        provider,
        providerPlaceId,
        request.name().trim(),
        blankToNull(request.category()),
        blankToNull(request.address()),
        blankToNull(request.roadAddress()),
        firstNonNull(request.latitude(), request.lat()),
        firstNonNull(request.longitude(), request.lng()),
        blankToNull(request.sourceUrl()),
        toJson(externalPlacePayload(request))
      )));
  }

  private Map<String, Object> externalPlacePayload(CreatePlaceCandidateRequest request) {
    Map<String, Object> payload = new LinkedHashMap<>();
    payload.put("sourceUrl", blankToNull(request.sourceUrl()));
    payload.put("fetchedAt", blankToNull(request.fetchedAt()));
    payload.put("selectedSnapshot", true);
    return payload;
  }

  private Map<String, Object> placeCandidatePayload(
    CreatePlaceCandidateRequest request,
    ExternalPlaceEntity externalPlace
  ) {
    Map<String, Object> payload = new LinkedHashMap<>();
    payload.put("summary", stringOrDefault(request.summary(), "팀원이 추가한 장소 후보입니다."));
    payload.put("tags", request.tags() == null ? List.of() : request.tags());
    payload.put("favoriteCount", 0);
    payload.put("source", externalPlace == null ? "manual" : externalPlace.getProvider().toLowerCase(Locale.ROOT));
    payload.put("sourceLabel", externalPlace == null ? "직접 추가" : "외부 검색");
    payload.put("provider", externalPlace == null ? null : externalPlace.getProvider());
    payload.put("providerPlaceId", externalPlace == null ? null : externalPlace.getProviderPlaceId());
    payload.put("roadAddress", blankToNull(request.roadAddress()));
    payload.put("sourceUrl", blankToNull(request.sourceUrl()));
    payload.put("lat", firstNonNull(request.latitude(), request.lat()));
    payload.put("lng", firstNonNull(request.longitude(), request.lng()));
    payload.put("fetchedAt", blankToNull(request.fetchedAt()));
    return payload;
  }

  private Map<String, Object> placeCandidateCard(PlaceCandidateEntity candidate, UserEntity user) {
    Map<String, Object> payload = readObject(candidate.getPayload());
    ExternalPlaceEntity externalPlace = candidate.getExternalPlace();
    Double lat = firstNonNullDouble(payload.get("lat"), payload.get("latitude"), externalPlace == null ? null : externalPlace.getLatitude());
    Double lng = firstNonNullDouble(payload.get("lng"), payload.get("longitude"), externalPlace == null ? null : externalPlace.getLongitude());
    String provider = stringOrDefault(asString(payload.get("provider")), externalPlace == null ? null : externalPlace.getProvider());
    String providerPlaceId = stringOrDefault(asString(payload.get("providerPlaceId")), externalPlace == null ? null : externalPlace.getProviderPlaceId());
    String roadAddress = stringOrDefault(asString(payload.get("roadAddress")), externalPlace == null ? null : externalPlace.getRoadAddress());
    String sourceUrl = stringOrDefault(asString(payload.get("sourceUrl")), externalPlace == null ? null : externalPlace.getHomepageUrl());
    int heartCount = candidateHeartCount(candidate);
    boolean myHearted = placeCandidateHeartRepository.existsByCandidateAndUser(candidate, user);
    Map<String, Object> value = new LinkedHashMap<>();
    value.put("id", candidate.getPublicId());
    value.put("groupId", candidate.getGroup().getPublicId());
    value.put("planId", candidate.getPlan().getPublicId());
    value.put("name", candidate.getName());
    value.put("category", stringOrDefault(candidate.getCategory(), "장소"));
    value.put("summary", stringOrDefault(asString(payload.get("summary")), "약속 장소 후보입니다."));
    value.put("favoriteCount", heartCount);
    value.put("heartCount", heartCount);
    value.put("myHearted", myHearted);
    value.put("distanceLabel", stringOrDefault(asString(payload.get("distanceLabel")), "거리 정보 준비 중"));
    value.put("travelTimeLabel", stringOrDefault(asString(payload.get("travelTimeLabel")), "이동 시간 준비 중"));
    value.put("priceLabel", stringOrDefault(asString(payload.get("priceLabel")), "가격 정보 준비 중"));
    value.put("isOpen", true);
    value.put("address", stringOrDefault(candidate.getAddress(), externalPlace == null ? "" : stringOrDefault(externalPlace.getAddress(), "")));
    value.put("source", stringOrDefault(asString(payload.get("source")), "manual"));
    value.put("sourceLabel", stringOrDefault(asString(payload.get("sourceLabel")), "직접 추가"));
    value.put("externalPlaceId", externalPlace == null ? null : externalPlace.getPublicId());
    value.put("provider", provider);
    value.put("providerPlaceId", providerPlaceId);
    value.put("roadAddress", roadAddress);
    value.put("sourceUrl", sourceUrl);
    value.put("lat", lat);
    value.put("lng", lng);
    value.put("latitude", lat);
    value.put("longitude", lng);
    value.put("fetchedAt", payload.get("fetchedAt"));
    value.put("createdAt", candidate.getCreatedAt() == null ? null : candidate.getCreatedAt().toString());
    value.put("openingLabel", stringOrDefault(asString(payload.get("openingLabel")), "영업 정보 확인 중"));
    value.put("memberFits", List.of());
    value.put("tags", stringList(payload.get("tags")));
    value.put("reasons", stringList(payload.get("reasons")));
    return value;
  }

  private int candidateHeartCount(PlaceCandidateEntity candidate) {
    Map<String, Object> payload = readObject(candidate.getPayload());
    int payloadFavoriteCount = intOrDefault(payload.get("favoriteCount"), 0);
    return Math.max(payloadFavoriteCount, Math.toIntExact(placeCandidateHeartRepository.countByCandidate(candidate)));
  }

  private Map<String, Object> schedulePlaceCard(GroupEntity group, PlanEntity plan, SchedulePlaceEntity schedulePlace) {
    Map<String, Object> value = new LinkedHashMap<>();
    value.put("id", schedulePlace.getPublicId());
    value.put("groupId", group.getPublicId());
    value.put("planId", plan.getPublicId());
    value.put("candidateId", schedulePlace.getPlaceCandidate() == null ? null : schedulePlace.getPlaceCandidate().getPublicId());
    value.put("name", schedulePlace.getName());
    value.put("placeName", schedulePlace.getName());
    value.put("startsAt", schedulePlace.getStartsAt() == null ? null : schedulePlace.getStartsAt().toString());
    value.put("endsAt", schedulePlace.getEndsAt() == null ? null : schedulePlace.getEndsAt().toString());
    value.put("note", schedulePlace.getNote());
    value.put("sortOrder", schedulePlace.getSortOrder());
    return value;
  }

  private List<String> voteCandidateIds(
    CreateVoteRequest request,
    List<String> requestedOptions,
    PlanEntity targetPlan
  ) {
    List<String> explicitCandidateIds = compactStrings(request.placeCandidateIds());
    if (!explicitCandidateIds.isEmpty()) {
      requirePlanTargetForCandidateVote(targetPlan);
      explicitCandidateIds.forEach(candidateId -> placeCandidateOrThrow(targetPlan, candidateId));
      return explicitCandidateIds;
    }
    List<String> optionCandidateIds = compactStrings(requestedOptions);
    if (
      targetPlan != null
        && "PLACE".equalsIgnoreCase(request.voteType())
        && !optionCandidateIds.isEmpty()
        && optionCandidateIds.stream().allMatch(this::looksLikePublicCandidateId)
    ) {
      optionCandidateIds.forEach(candidateId -> placeCandidateOrThrow(targetPlan, candidateId));
      return optionCandidateIds;
    }
    return List.of();
  }

  private List<VoteOptionEntity> saveVoteOptions(
    VoteEntity vote,
    PlanEntity targetPlan,
    List<String> options,
    List<String> candidateIds
  ) {
    List<VoteOptionEntity> savedOptions = new ArrayList<>();
    for (int index = 0; index < options.size(); index += 1) {
      String candidateId = index < candidateIds.size() ? candidateIds.get(index) : null;
      PlaceCandidateEntity candidate = candidateId == null ? null : placeCandidateOrThrow(targetPlan, candidateId);
      String label = candidate == null ? options.get(index) : candidate.getName();
      String targetType = candidate == null ? "TEXT" : "PLACE_CANDIDATE";
      String targetId = candidate == null ? label : candidate.getPublicId();
      VoteOptionEntity option = new VoteOptionEntity(
        vote,
        "vopt-" + vote.getPublicId() + "-" + (index + 1),
        label,
        targetType,
        targetId,
        index + 1,
        candidate == null ? "{}" : toJson(Map.of("candidateId", candidate.getPublicId()))
      );
      VoteOptionEntity savedOption = voteOptionRepository.save(option);
      savedOptions.add(savedOption == null ? option : savedOption);
    }
    return savedOptions;
  }

  private void requirePlanTargetForCandidateVote(PlanEntity targetPlan) {
    if (targetPlan == null) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "missing_vote_plan_for_place_candidate");
    }
  }

  private boolean looksLikePublicCandidateId(String value) {
    return value != null && value.matches("\\d+");
  }

  private List<String> compactStrings(List<String> values) {
    if (values == null) {
      return List.of();
    }
    return values.stream()
      .filter(value -> value != null && !value.isBlank())
      .map(String::trim)
      .toList();
  }

  private Map<String, Object> participantCard(PlanParticipantEntity participant) {
    UserEntity user = participant.getUser();
    Map<String, Object> value = new LinkedHashMap<>();
    value.put("id", participant.getId().toString());
    value.put("userId", user.getId().toString());
    value.put("nickname", nickname(user));
    value.put("profileImageUrl", user.getProfileImageUrl());
    value.put("preferenceProfile", readJsonObject(user.getPreferenceProfile()));
    value.put("status", participant.getStatus());
    value.put("response", participant.getResponse());
    value.put("joinedAt", participant.getJoinedAt() == null ? null : participant.getJoinedAt().toString());
    value.put("fallback", false);
    return value;
  }

  private List<Map<String, Object>> activeParticipantCards(PlanEntity plan) {
    return planParticipantRepository.findByPlanOrderByCreatedAtAsc(plan).stream()
      .filter(this::isActivePlanParticipant)
      .map(this::participantCard)
      .toList();
  }

  private boolean isActivePlanParticipant(PlanParticipantEntity participant) {
    String status = participant.getStatus();
    return status == null
      || (!"left".equalsIgnoreCase(status) && !"declined".equalsIgnoreCase(status));
  }

  private Map<String, Object> memberCard(Map<String, Object> participant) {
    Map<String, Object> value = new LinkedHashMap<>();
    value.put("name", stringOrDefault((String) participant.get("nickname"), "참여자"));
    value.put("nickname", stringOrDefault((String) participant.get("nickname"), "참여자"));
    value.put("message", "");
    value.put("badge", "참여 중");
    value.put("selected", true);
    value.put("userId", participant.get("userId"));
    value.put("profileImageUrl", participant.get("profileImageUrl"));
    value.put("preferenceProfile", participant.get("preferenceProfile"));
    return value;
  }

  private String nickname(UserEntity user) {
    return stringOrDefault(user.getNickname(), "나");
  }

  private Map<String, Object> settlementDraftCard(SettlementDraftEntity draft) {
    Map<String, Object> payload = readObject(draft.getPayload());
    Map<String, Object> value = new LinkedHashMap<>();
    value.put("id", draft.getPublicId());
    value.put("groupId", draft.getGroup().getPublicId());
    value.put("planId", draft.getPlan().getPublicId());
    value.put("items", settlementItems(payload));
    value.put("memo", stringOrDefault(asString(payload.get("memo")), ""));
    value.put("preview", settlementSummaryCard("preview", draft.getPlan(), payload, true));
    return value;
  }

  private Map<String, Object> settlementSummaryCard(
    String publicId,
    PlanEntity plan,
    Map<String, Object> payload,
    boolean preview
  ) {
    List<Map<String, Object>> items = settlementItems(payload);
    int totalAmount = items.stream()
      .map(item -> intOrDefault(item.get("amount"), 0))
      .reduce(0, Integer::sum);
    String payerName = items.stream()
      .map(item -> asString(item.get("payerName")))
      .filter(value -> value != null && !value.isBlank())
      .findFirst()
      .orElse("지민");
    List<String> targets = items.stream()
      .flatMap(item -> stringList(item.get("targetNames")).stream())
      .distinct()
      .toList();
    int targetCount = targets.isEmpty() ? 1 : targets.size();
    int shareAmount = targetCount == 0 ? 0 : Math.round((float) totalAmount / targetCount);

    Map<String, Object> value = new LinkedHashMap<>();
    value.put("id", publicId);
    value.put("planId", plan.getPublicId());
    value.put("planTitle", plan.getTitle());
    value.put("preview", preview);
    value.put("totalAmount", totalAmount);
    value.put("totalAmountLabel", amountLabel(totalAmount));
    value.put("createdDateLabel", preview ? "미리보기" : "정산 생성됨");
    value.put("itemCountLabel", "결제 항목 " + items.size() + "개");
    value.put("finalSummaryLabel", targetCount + "명 기준 " + amountLabel(shareAmount));
    value.put("mySummaryLabel", "내 몫은 " + amountLabel(shareAmount) + "입니다");
    value.put("paymentItems", items.stream()
      .map(item -> settlementPaymentItem(item, targetCount, shareAmount))
      .toList());
    value.put("memberResults", targets.stream()
      .map(name -> settlementMemberResult(name, shareAmount, payerName.equals(name)))
      .toList());
    value.put("transfers", targets.stream()
      .filter(name -> !payerName.equals(name))
      .map(name -> settlementTransfer(name, payerName, shareAmount))
      .toList());
    value.put("shareMessage", stringOrDefault(asString(payload.get("shareMessage")), plan.getTitle() + " 약속 정산입니다."));
    return value;
  }

  private Map<String, Object> settlementPaymentItem(Map<String, Object> item, int targetCount, int shareAmount) {
    String payerName = stringOrDefault(asString(item.get("payerName")), "지민");
    Map<String, Object> value = new LinkedHashMap<>();
    value.put("id", stringOrDefault(asString(item.get("id")), "401"));
    value.put("title", stringOrDefault(asString(item.get("title")), "결제 항목"));
    value.put("amount", intOrDefault(item.get("amount"), 0));
    value.put("amountLabel", amountLabel(intOrDefault(item.get("amount"), 0)));
    value.put("payerShares", List.of(Map.of(
      "name", payerName,
      "amountLabel", amountLabel(intOrDefault(item.get("amount"), 0))
    )));
    value.put("targetLabel", targetCount + "명");
    value.put("splitType", stringOrDefault(asString(item.get("splitType")), "equal"));
    value.put("participants", stringList(item.get("targetNames")).stream()
      .map(name -> Map.of("name", name, "owedAmountLabel", amountLabel(shareAmount), "included", true))
      .toList());
    return value;
  }

  private Map<String, Object> settlementMemberResult(String name, int shareAmount, boolean payer) {
    Map<String, Object> value = new LinkedHashMap<>();
    value.put("name", name);
    value.put("finalShareLabel", amountLabel(shareAmount));
    value.put("paidAmountLabel", payer ? "결제자" : "0원");
    value.put("resultLabel", payer ? "정산 받을 예정" : amountLabel(shareAmount) + " 송금");
    value.put("isMe", false);
    value.put("willReceive", payer);
    return value;
  }

  private Map<String, Object> settlementTransfer(String fromName, String toName, int amount) {
    return Map.of(
      "fromName", fromName,
      "toName", toName,
      "amountLabel", amountLabel(amount)
    );
  }

  private Map<String, Object> settlementPayloadFromItems(PlanEntity plan, List<SettlementDraftItemRequest> items) {
    List<SettlementDraftItemRequest> sourceItems = items == null || items.isEmpty()
      ? List.of(new SettlementDraftItemRequest(
        "401",
        "저녁",
        124000,
        124000,
        null,
        "지민",
        "equal",
        List.of(),
        List.of("지민", "민수", "소연", "현우")
      ))
      : items;
    Map<String, Object> payload = new LinkedHashMap<>();
    payload.put("items", sourceItems.stream().map(this::settlementItemPayload).toList());
    payload.put("memo", "Spring settlement draft");
    payload.put("shareMessage", plan.getTitle() + " 약속 정산입니다.");
    return payload;
  }

  private Map<String, Object> settlementItemPayload(SettlementDraftItemRequest item) {
    Map<String, Object> value = new LinkedHashMap<>();
    value.put("id", stringOrDefault(item.id(), "401"));
    value.put("title", stringOrDefault(item.title(), "결제 항목"));
    value.put("amount", item.amount() == null ? 0 : item.amount());
    value.put("amountWon", item.amountWon() == null ? item.amount() == null ? 0 : item.amount() : item.amountWon());
    value.put("payerUserId", item.payerUserId());
    value.put("payerName", stringOrDefault(item.payerName(), "지민"));
    value.put("splitType", stringOrDefault(item.splitType(), "equal"));
    value.put("targetUserIds", item.targetUserIds() == null ? List.of() : item.targetUserIds());
    value.put("targetNames", item.targetNames() == null || item.targetNames().isEmpty()
      ? List.of("지민", "민수", "소연", "현우")
      : item.targetNames());
    return value;
  }

  private List<Map<String, Object>> settlementItems(Map<String, Object> payload) {
    Object rawItems = payload.get("items");
    if (rawItems instanceof List<?> list) {
      List<Map<String, Object>> values = new ArrayList<>();
      for (Object item : list) {
        if (item instanceof Map<?, ?> map) {
          Map<String, Object> value = new LinkedHashMap<>();
          map.forEach((key, itemValue) -> value.put(String.valueOf(key), itemValue));
          values.add(value);
        }
      }
      if (!values.isEmpty()) {
        return values;
      }
    }
    return List.of(Map.of(
      "id", "401",
      "title", "저녁",
      "amount", 124000,
      "payerName", "지민",
      "splitType", "equal",
      "targetNames", List.of("지민", "민수", "소연", "현우")
    ));
  }

  private String defaultSettlementPayload(PlanEntity plan) {
    return toJson(settlementPayloadFromItems(plan, List.of()));
  }

  private Instant parseNullableInstant(String value) {
    if (value == null || value.isBlank()) {
      return null;
    }
    return parseInstantOrDefault(value);
  }

  private String amountLabel(int amount) {
    return String.format(Locale.KOREA, "%,d원", amount);
  }

  private String asString(Object value) {
    return value == null ? null : String.valueOf(value);
  }

  private int intOrDefault(Object value, int fallback) {
    if (value instanceof Number number) {
      return number.intValue();
    }
    if (value instanceof String string) {
      try {
        return Integer.parseInt(string);
      } catch (NumberFormatException ignored) {
        return fallback;
      }
    }
    return fallback;
  }

  private List<String> stringList(Object value) {
    if (value instanceof List<?> list) {
      List<String> values = new ArrayList<>();
      list.forEach(item -> values.add(String.valueOf(item)));
      return values;
    }
    return List.of();
  }

  private Map<String, Object> readObject(String payload) {
    try {
      Map<?, ?> parsed = objectMapper.readValue(payload, Map.class);
      Map<String, Object> value = new LinkedHashMap<>();
      parsed.forEach((key, item) -> value.put(String.valueOf(key), item));
      return value;
    } catch (JsonProcessingException exception) {
      return new LinkedHashMap<>();
    }
  }

  private String normalizeVoteTargetType(String value) {
    String targetType = stringOrDefault(value, "GROUP").toUpperCase(Locale.ROOT);
    if (!"GROUP".equals(targetType) && !"PLAN".equals(targetType)) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "invalid_vote_target_type");
    }
    return targetType;
  }

  private String resolveVoteTargetId(GroupEntity group, String targetType, String value) {
    String targetId = value == null || value.isBlank() ? null : value.trim();
    if ("GROUP".equals(targetType)) {
      return null;
    }
    if (targetId == null) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "missing_vote_target_id");
    }
    planOrThrow(group, targetId);
    return targetId;
  }

  private String nextPublicId(List<String> values, int fallbackStart) {
    int max = values.stream()
      .map(this::tryParseInt)
      .flatMap(List::stream)
      .max(Comparator.naturalOrder())
      .orElse(fallbackStart - 1);
    return Integer.toString(max + 1);
  }

  private List<Integer> tryParseInt(String value) {
    try {
      return List.of(Integer.parseInt(value));
    } catch (NumberFormatException exception) {
      return List.of();
    }
  }

  private Instant parseInstantOrDefault(String value) {
    if (value == null || value.isBlank()) {
      return Instant.now().plusSeconds(60L * 60L * 24L * 7L);
    }
    try {
      return Instant.parse(value);
    } catch (RuntimeException ignored) {
      try {
        return OffsetDateTime.parse(value).toInstant();
      } catch (RuntimeException exception) {
        throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "invalid_starts_at");
      }
    }
  }

  private String stringOrDefault(String value, String fallback) {
    return value == null || value.isBlank() ? fallback : value.trim();
  }

  private String normalizeProvider(String value) {
    String provider = blankToNull(value);
    return provider == null ? null : provider.toUpperCase(Locale.ROOT);
  }

  private Double firstNonNull(Double first, Double second) {
    return first == null ? second : first;
  }

  private Double firstNonNullDouble(Object... values) {
    for (Object value : values) {
      if (value instanceof Number number) {
        return number.doubleValue();
      }
      if (value instanceof String string && !string.isBlank()) {
        try {
          return Double.parseDouble(string);
        } catch (NumberFormatException ignored) {
          // Try the next fallback value.
        }
      }
    }
    return null;
  }

  private String blankToNull(String value) {
    return value == null || value.isBlank() ? null : value.trim();
  }

  private List<String> readOptions(String payload) {
    try {
      Map<?, ?> parsed = objectMapper.readValue(payload, Map.class);
      Object options = parsed.get("options");
      if (options instanceof List<?> list) {
        List<String> values = new ArrayList<>();
        list.forEach(option -> values.add(String.valueOf(option)));
        return values;
      }
      return List.of();
    } catch (JsonProcessingException exception) {
      return List.of();
    }
  }

  private Map<String, Object> readJsonObject(String payload) {
    if (payload == null || payload.isBlank()) {
      return Map.of();
    }
    try {
      Map<?, ?> parsed = objectMapper.readValue(payload, Map.class);
      Map<String, Object> values = new LinkedHashMap<>();
      parsed.forEach((key, value) -> values.put(String.valueOf(key), value));
      return values;
    } catch (JsonProcessingException exception) {
      return Map.of();
    }
  }

  private Map<String, Object> readPreferenceProfile(String payload) {
    return sanitizeProfilePayload(readJsonObject(payload));
  }

  private Map<String, Object> sanitizeProfilePayload(Map<String, Object> payload) {
    Map<String, Object> values = new LinkedHashMap<>();
    payload.forEach((key, value) -> {
      Object sanitized = sanitizeProfileValue(value);
      if (sanitized != null) {
        values.put(String.valueOf(key), sanitized);
      }
    });
    return values;
  }

  private Object sanitizeProfileValue(Object value) {
    if (value instanceof String string) {
      String trimmed = string.trim();
      return isSafeProfileText(trimmed) ? trimmed : null;
    }
    if (value instanceof Map<?, ?> map) {
      Map<String, Object> values = new LinkedHashMap<>();
      map.forEach((key, item) -> {
        Object sanitized = sanitizeProfileValue(item);
        if (sanitized != null) {
          values.put(String.valueOf(key), sanitized);
        }
      });
      return values;
    }
    if (value instanceof List<?> list) {
      List<Object> values = new ArrayList<>();
      list.forEach(item -> {
        Object sanitized = sanitizeProfileValue(item);
        if (sanitized != null) {
          values.add(sanitized);
        }
      });
      return values;
    }
    if (value instanceof Number || value instanceof Boolean) {
      return value;
    }
    return null;
  }

  private boolean isSafeProfileText(String value) {
    return !looksLikeMojibake(value) && !looksLikeStructuredJsonText(value);
  }

  private boolean looksLikeMojibake(String value) {
    boolean hasUtf8LeadByteGlyph = false;
    boolean hasUtf8ContinuationByteGlyph = false;
    for (int index = 0; index < value.length(); index++) {
      char ch = value.charAt(index);
      if (ch == '\uFFFD' || (ch >= '\u0080' && ch <= '\u009F')) {
        return true;
      }
      if (ch == '\u00C2' || ch == '\u00C3' || ch == '\u00EA' || ch == '\u00EB'
        || ch == '\u00EC' || ch == '\u00ED' || ch == '\u00EE' || ch == '\u00EF'
        || ch == '\u00F0') {
        hasUtf8LeadByteGlyph = true;
      }
      if ((ch >= '\u2018' && ch <= '\u201D') || ch == '\u201A' || ch == '\u201E'
        || ch == '\u2026' || ch == '\u2039' || ch == '\u203A' || ch == '\u0152'
        || ch == '\u0153' || ch == '\u0160' || ch == '\u0161' || ch == '\u017D'
        || ch == '\u017E' || ch == '\u00A0' || ch == '\u00A4' || ch == '\u00A9'
        || ch == '\u00B0' || ch == '\u00B4' || ch == '\u00B5' || ch == '\u00B8') {
        hasUtf8ContinuationByteGlyph = true;
      }
    }
    return hasUtf8LeadByteGlyph && hasUtf8ContinuationByteGlyph;
  }

  private boolean looksLikeStructuredJsonText(String value) {
    if (value.length() < 2) {
      return false;
    }
    boolean objectLike = value.startsWith("{") && value.endsWith("}");
    boolean arrayLike = value.startsWith("[") && value.endsWith("]");
    if (!objectLike && !arrayLike) {
      return false;
    }
    try {
      objectMapper.readTree(value);
      return true;
    } catch (JsonProcessingException ignored) {
      return false;
    }
  }

  private String toJson(Map<String, Object> payload) {
    try {
      return objectMapper.writeValueAsString(payload);
    } catch (JsonProcessingException exception) {
      throw new IllegalStateException("Could not serialize payload", exception);
    }
  }

  private record GroupAccess(GroupEntity group, UserEntity user) {
  }
}
