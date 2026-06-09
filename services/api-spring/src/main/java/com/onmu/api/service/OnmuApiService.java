package com.onmu.api.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.onmu.api.domain.AuthIdentityEntity;
import com.onmu.api.domain.AuthIdentityRepository;
import com.onmu.api.domain.GroupEntity;
import com.onmu.api.domain.GroupRepository;
import com.onmu.api.domain.PlaceCandidateEntity;
import com.onmu.api.domain.PlaceCandidateRepository;
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
import com.onmu.api.domain.VoteRepository;
import com.onmu.api.web.dto.CreateGroupRequest;
import com.onmu.api.web.dto.CreatePlaceCandidateRequest;
import com.onmu.api.web.dto.CreatePlanRequest;
import com.onmu.api.web.dto.CreateSchedulePlaceRequest;
import com.onmu.api.web.dto.CreateVoteRequest;
import com.onmu.api.web.dto.SettlementDraftItemRequest;
import com.onmu.api.web.dto.SettlementPreviewRequest;
import com.onmu.api.web.dto.UpdateSettlementDraftRequest;
import java.time.Instant;
import java.time.OffsetDateTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
public class OnmuApiService {
  private static final ZoneId KST = ZoneId.of("Asia/Seoul");
  private static final DateTimeFormatter DATE_LABEL = DateTimeFormatter.ofPattern("M월 d일").withZone(KST);

  private final UserRepository userRepository;
  private final AuthIdentityRepository authIdentityRepository;
  private final GroupRepository groupRepository;
  private final PlanRepository planRepository;
  private final VoteRepository voteRepository;
  private final PlaceCandidateRepository placeCandidateRepository;
  private final SchedulePlaceRepository schedulePlaceRepository;
  private final SettlementDraftRepository settlementDraftRepository;
  private final SettlementRepository settlementRepository;
  private final OutboxService outboxService;
  private final ObjectMapper objectMapper;

  public OnmuApiService(
    UserRepository userRepository,
    AuthIdentityRepository authIdentityRepository,
    GroupRepository groupRepository,
    PlanRepository planRepository,
    VoteRepository voteRepository,
    PlaceCandidateRepository placeCandidateRepository,
    SchedulePlaceRepository schedulePlaceRepository,
    SettlementDraftRepository settlementDraftRepository,
    SettlementRepository settlementRepository,
    OutboxService outboxService,
    ObjectMapper objectMapper
  ) {
    this.userRepository = userRepository;
    this.authIdentityRepository = authIdentityRepository;
    this.groupRepository = groupRepository;
    this.planRepository = planRepository;
    this.voteRepository = voteRepository;
    this.placeCandidateRepository = placeCandidateRepository;
    this.schedulePlaceRepository = schedulePlaceRepository;
    this.settlementDraftRepository = settlementDraftRepository;
    this.settlementRepository = settlementRepository;
    this.outboxService = outboxService;
    this.objectMapper = objectMapper;
  }

  @Transactional(readOnly = true)
  public Map<String, Object> userMe() {
    UserEntity user = currentUser();
    AuthIdentityEntity identity = authIdentityRepository.findFirstByUserOrderByCreatedAtAsc(user).orElse(null);

    Map<String, Object> value = new LinkedHashMap<>();
    value.put("id", user.getId().toString());
    value.put("displayName", user.getDisplayName());
    value.put("authProvider", identity == null ? "NAVER" : identity.getProvider());
    value.put("authStatus", "dev-scaffold");
    value.put("tokenContract", Map.of(
      "accessToken", "issued-by-spring-main-api",
      "refreshToken", "issued-by-spring-main-api",
      "clientStorage", "flutter-secure-storage"
    ));
    return value;
  }

  @Transactional(readOnly = true)
  public Map<String, Object> homeSummary() {
    List<GroupEntity> groups = groupRepository.findAllByOrderByCreatedAtAsc();
    GroupEntity firstGroup = groups.stream().findFirst().orElseThrow(this::noSeedData);
    List<PlanEntity> plans = planRepository.findByGroupOrderByStartsAtAsc(firstGroup);
    List<VoteEntity> votes = voteRepository.findByGroupOrderByCreatedAtAsc(firstGroup);

    Map<String, Object> value = new LinkedHashMap<>();
    value.put("service", "onmu-api-spring");
    value.put("env", "local");
    value.put("viewer", userMe());
    value.put("groups", groups.stream().map(this::groupCard).toList());
    value.put("upcomingPlans", plans.stream().map(this::planCard).toList());
    value.put("activeVotes", votes.stream().map(this::voteCard).toList());
    value.put("nextPlan", plans.stream().findFirst().map(this::planCard).orElse(null));
    return value;
  }

  @Transactional(readOnly = true)
  public List<Map<String, Object>> groups() {
    return groupRepository.findAllByOrderByCreatedAtAsc().stream().map(this::groupCard).toList();
  }

  @Transactional
  public Map<String, Object> createGroup(CreateGroupRequest request) {
    String publicId = nextPublicId(groupRepository.findAllByOrderByCreatedAtAsc().stream()
      .map(GroupEntity::getPublicId)
      .toList(), 1);
    GroupEntity group = groupRepository.save(new GroupEntity(publicId, request.name().trim(), currentUser()));
    return groupCard(group);
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
  public List<Map<String, Object>> plans(String groupId) {
    GroupEntity group = groupOrThrow(groupId);
    return planRepository.findByGroupOrderByStartsAtAsc(group).stream().map(this::planCard).toList();
  }

  @Transactional
  public Map<String, Object> createPlan(String groupId, CreatePlanRequest request) {
    GroupEntity group = groupOrThrow(groupId);
    String publicId = nextPublicId(planRepository.findAll().stream()
      .map(PlanEntity::getPublicId)
      .toList(), 101);
    Instant startsAt = parseInstantOrDefault(request.startsAt());
    PlanEntity plan = planRepository.save(new PlanEntity(
      publicId,
      group,
      request.title().trim(),
      startsAt,
      "draft"
    ));
    outboxService.record("plan.created", "plan", plan.getId(), Map.of(
      "groupId", group.getPublicId(),
      "planId", plan.getPublicId(),
      "title", plan.getTitle()
    ));
    return planCard(plan);
  }

  @Transactional(readOnly = true)
  public Map<String, Object> plan(String groupId, String planId) {
    return planCard(planOrThrow(groupOrThrow(groupId), planId));
  }

  @Transactional(readOnly = true)
  public List<Map<String, Object>> votes(String groupId) {
    GroupEntity group = groupOrThrow(groupId);
    return voteRepository.findByGroupOrderByCreatedAtAsc(group).stream().map(this::voteCard).toList();
  }

  @Transactional
  public Map<String, Object> createVote(String groupId, CreateVoteRequest request) {
    GroupEntity group = groupOrThrow(groupId);
    String publicId = nextPublicId(voteRepository.findAll().stream()
      .map(VoteEntity::getPublicId)
      .toList(), 501);
    String targetType = normalizeVoteTargetType(request.targetType());
    String targetId = resolveVoteTargetId(group, targetType, request.targetId());
    List<String> options = request.options() == null || request.options().isEmpty()
      ? List.of("A", "B")
      : request.options();

    VoteEntity vote = voteRepository.save(new VoteEntity(
      publicId,
      group,
      targetType,
      targetId,
      request.voteType().trim(),
      request.title().trim(),
      toJson(Map.of("options", options))
    ));
    Map<String, Object> outboxPayload = new LinkedHashMap<>();
    outboxPayload.put("groupId", group.getPublicId());
    outboxPayload.put("voteId", vote.getPublicId());
    outboxPayload.put("targetType", vote.getTargetType());
    outboxPayload.put("targetId", vote.getTargetId());
    outboxService.record("vote.created", "vote", vote.getId(), outboxPayload);
    return voteCard(vote);
  }

  @Transactional(readOnly = true)
  public Map<String, Object> vote(String groupId, String voteId) {
    return voteCard(voteOrThrow(groupOrThrow(groupId), voteId));
  }

  @Transactional(readOnly = true)
  public List<Map<String, Object>> placeCandidates(String groupId, String planId) {
    PlanEntity plan = planOrThrow(groupOrThrow(groupId), planId);
    return placeCandidateRepository.findByPlanOrderByCreatedAtAsc(plan).stream()
      .map(this::placeCandidateCard)
      .toList();
  }

  @Transactional
  public Map<String, Object> createPlaceCandidate(
    String groupId,
    String planId,
    CreatePlaceCandidateRequest request
  ) {
    GroupEntity group = groupOrThrow(groupId);
    PlanEntity plan = planOrThrow(group, planId);
    String publicId = nextPublicId(placeCandidateRepository.findAll().stream()
      .map(PlaceCandidateEntity::getPublicId)
      .toList(), 201);
    String payload = toJson(Map.of(
      "summary", stringOrDefault(request.summary(), "팀원이 추가한 장소 후보입니다."),
      "tags", request.tags() == null ? List.of() : request.tags(),
      "favoriteCount", 0
    ));
    PlaceCandidateEntity candidate = placeCandidateRepository.save(new PlaceCandidateEntity(
      publicId,
      group,
      plan,
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
    return placeCandidateCard(candidate);
  }

  @Transactional
  public Map<String, Object> createSchedulePlace(
    String groupId,
    String planId,
    CreateSchedulePlaceRequest request
  ) {
    GroupEntity group = groupOrThrow(groupId);
    PlanEntity plan = planOrThrow(group, planId);
    PlaceCandidateEntity candidate = request.candidateId() == null || request.candidateId().isBlank()
      ? null
      : placeCandidateOrThrow(plan, request.candidateId());
    String publicId = nextPublicId(schedulePlaceRepository.findAll().stream()
      .map(SchedulePlaceEntity::getPublicId)
      .toList(), 701);
    int sortOrder = schedulePlaceRepository.findByPlanOrderBySortOrderAsc(plan).size() + 1;
    SchedulePlaceEntity schedulePlace = schedulePlaceRepository.save(new SchedulePlaceEntity(
      publicId,
      group,
      plan,
      candidate,
      request.name().trim(),
      parseNullableInstant(request.startsAt()),
      sortOrder
    ));
    return schedulePlaceCard(group, plan, schedulePlace);
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

  private UserEntity currentUser() {
    return userRepository.findFirstByOrderByCreatedAtAsc().orElseThrow(this::noSeedData);
  }

  private GroupEntity groupOrThrow(String groupId) {
    return groupRepository.findByPublicId(groupId)
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "group_not_found"));
  }

  private PlanEntity planOrThrow(GroupEntity group, String planId) {
    return planRepository.findByGroupAndPublicId(group, planId)
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "plan_not_found"));
  }

  private VoteEntity voteOrThrow(GroupEntity group, String voteId) {
    return voteRepository.findByGroupAndPublicId(group, voteId)
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "vote_not_found"));
  }

  private PlaceCandidateEntity placeCandidateOrThrow(PlanEntity plan, String candidateId) {
    return placeCandidateRepository.findByPlanAndPublicId(plan, candidateId)
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "place_candidate_not_found"));
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
    Map<String, Object> value = new LinkedHashMap<>();
    value.put("id", plan.getPublicId());
    value.put("groupId", plan.getGroup().getPublicId());
    value.put("title", plan.getTitle());
    value.put("startsAt", plan.getStartsAt() == null ? null : plan.getStartsAt().toString());
    value.put("dateLabel", plan.getStartsAt() == null ? "일정 미정" : DATE_LABEL.format(plan.getStartsAt()));
    value.put("status", plan.getStatus());
    value.put("placeName", "장소 미정");
    return value;
  }

  private Map<String, Object> voteCard(VoteEntity vote) {
    Map<String, Object> value = new LinkedHashMap<>();
    value.put("id", vote.getPublicId());
    value.put("groupId", vote.getGroup().getPublicId());
    value.put("title", vote.getTitle());
    value.put("voteType", vote.getVoteType());
    value.put("targetType", vote.getTargetType());
    value.put("targetId", vote.getTargetId());
    value.put("status", vote.getStatus());
    value.put("closed", !"open".equalsIgnoreCase(vote.getStatus()));
    value.put("options", readOptions(vote.getPayload()));
    return value;
  }

  private Map<String, Object> placeCandidateCard(PlaceCandidateEntity candidate) {
    Map<String, Object> payload = readObject(candidate.getPayload());
    Map<String, Object> value = new LinkedHashMap<>();
    value.put("id", candidate.getPublicId());
    value.put("groupId", candidate.getGroup().getPublicId());
    value.put("planId", candidate.getPlan().getPublicId());
    value.put("name", candidate.getName());
    value.put("category", stringOrDefault(candidate.getCategory(), "장소"));
    value.put("summary", stringOrDefault(asString(payload.get("summary")), "약속 장소 후보입니다."));
    value.put("favoriteCount", intOrDefault(payload.get("favoriteCount"), 0));
    value.put("distanceLabel", stringOrDefault(asString(payload.get("distanceLabel")), "거리 정보 준비 중"));
    value.put("travelTimeLabel", stringOrDefault(asString(payload.get("travelTimeLabel")), "이동 시간 준비 중"));
    value.put("priceLabel", stringOrDefault(asString(payload.get("priceLabel")), "가격 정보 준비 중"));
    value.put("isOpen", true);
    value.put("address", stringOrDefault(candidate.getAddress(), ""));
    value.put("openingLabel", stringOrDefault(asString(payload.get("openingLabel")), "영업 정보 확인 중"));
    value.put("memberFits", List.of());
    value.put("tags", stringList(payload.get("tags")));
    value.put("reasons", stringList(payload.get("reasons")));
    return value;
  }

  private Map<String, Object> schedulePlaceCard(GroupEntity group, PlanEntity plan, SchedulePlaceEntity schedulePlace) {
    Map<String, Object> value = new LinkedHashMap<>();
    value.put("id", schedulePlace.getPublicId());
    value.put("groupId", group.getPublicId());
    value.put("planId", plan.getPublicId());
    value.put("candidateId", schedulePlace.getPlaceCandidate() == null ? null : schedulePlace.getPlaceCandidate().getPublicId());
    value.put("name", schedulePlace.getName());
    value.put("startsAt", schedulePlace.getStartsAt() == null ? null : schedulePlace.getStartsAt().toString());
    value.put("sortOrder", schedulePlace.getSortOrder());
    return value;
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

  private String toJson(Map<String, Object> payload) {
    try {
      return objectMapper.writeValueAsString(payload);
    } catch (JsonProcessingException exception) {
      throw new IllegalStateException("Could not serialize payload", exception);
    }
  }

  private ResponseStatusException noSeedData() {
    return new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "dev_seed_data_missing");
  }
}
