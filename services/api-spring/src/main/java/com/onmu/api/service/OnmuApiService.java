package com.onmu.api.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.onmu.api.domain.AuthIdentityEntity;
import com.onmu.api.domain.AuthIdentityRepository;
import com.onmu.api.domain.GroupEntity;
import com.onmu.api.domain.GroupRepository;
import com.onmu.api.domain.PlanEntity;
import com.onmu.api.domain.PlanRepository;
import com.onmu.api.domain.UserEntity;
import com.onmu.api.domain.UserRepository;
import com.onmu.api.domain.VoteEntity;
import com.onmu.api.domain.VoteRepository;
import com.onmu.api.web.dto.CreateGroupRequest;
import com.onmu.api.web.dto.CreatePlanRequest;
import com.onmu.api.web.dto.CreateVoteRequest;
import java.time.Instant;
import java.time.OffsetDateTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
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
  private final OutboxService outboxService;
  private final ObjectMapper objectMapper;

  public OnmuApiService(
    UserRepository userRepository,
    AuthIdentityRepository authIdentityRepository,
    GroupRepository groupRepository,
    PlanRepository planRepository,
    VoteRepository voteRepository,
    OutboxService outboxService,
    ObjectMapper objectMapper
  ) {
    this.userRepository = userRepository;
    this.authIdentityRepository = authIdentityRepository;
    this.groupRepository = groupRepository;
    this.planRepository = planRepository;
    this.voteRepository = voteRepository;
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
    GroupEntity group = groupOrFallback(groupId);
    Map<String, Object> value = new LinkedHashMap<>();
    value.put("group", groupCard(group));
    value.put("plans", plans(group.getPublicId()));
    value.put("votes", votes(group.getPublicId()));
    return value;
  }

  @Transactional(readOnly = true)
  public List<Map<String, Object>> plans(String groupId) {
    GroupEntity group = groupOrFallback(groupId);
    return planRepository.findByGroupOrderByStartsAtAsc(group).stream().map(this::planCard).toList();
  }

  @Transactional
  public Map<String, Object> createPlan(String groupId, CreatePlanRequest request) {
    GroupEntity group = groupOrFallback(groupId);
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
    return planCard(planOrFallback(groupOrFallback(groupId), planId));
  }

  @Transactional(readOnly = true)
  public List<Map<String, Object>> votes(String groupId) {
    GroupEntity group = groupOrFallback(groupId);
    return voteRepository.findByGroupOrderByCreatedAtAsc(group).stream().map(this::voteCard).toList();
  }

  @Transactional
  public Map<String, Object> createVote(String groupId, CreateVoteRequest request) {
    GroupEntity group = groupOrFallback(groupId);
    String publicId = nextPublicId(voteRepository.findAll().stream()
      .map(VoteEntity::getPublicId)
      .toList(), 501);
    String targetType = stringOrDefault(request.targetType(), "PLAN");
    String targetId = stringOrDefault(request.targetId(), firstPlanId(group));
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
    outboxService.record("vote.created", "vote", vote.getId(), Map.of(
      "groupId", group.getPublicId(),
      "voteId", vote.getPublicId(),
      "targetType", vote.getTargetType(),
      "targetId", vote.getTargetId()
    ));
    return voteCard(vote);
  }

  @Transactional(readOnly = true)
  public Map<String, Object> vote(String groupId, String voteId) {
    return voteCard(voteOrFallback(groupOrFallback(groupId), voteId));
  }

  private UserEntity currentUser() {
    return userRepository.findFirstByOrderByCreatedAtAsc().orElseThrow(this::noSeedData);
  }

  private GroupEntity groupOrFallback(String groupId) {
    return groupRepository.findByPublicId(groupId)
      .or(() -> groupRepository.findAllByOrderByCreatedAtAsc().stream().findFirst())
      .orElseThrow(this::noSeedData);
  }

  private PlanEntity planOrFallback(GroupEntity group, String planId) {
    return planRepository.findByGroupAndPublicId(group, planId)
      .or(() -> planRepository.findByGroupOrderByStartsAtAsc(group).stream().findFirst())
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "plan_not_found"));
  }

  private VoteEntity voteOrFallback(GroupEntity group, String voteId) {
    return voteRepository.findByGroupAndPublicId(group, voteId)
      .or(() -> voteRepository.findByGroupOrderByCreatedAtAsc(group).stream().findFirst())
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "vote_not_found"));
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

  private String firstPlanId(GroupEntity group) {
    return planRepository.findByGroupOrderByStartsAtAsc(group).stream()
      .map(PlanEntity::getPublicId)
      .findFirst()
      .orElse("101");
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
