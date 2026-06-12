package com.onmu.api.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.argThat;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.fasterxml.jackson.databind.ObjectMapper;
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
import com.onmu.api.domain.SettlementDraftRepository;
import com.onmu.api.domain.SettlementEntity;
import com.onmu.api.domain.SettlementRepository;
import com.onmu.api.domain.UserEntity;
import com.onmu.api.domain.UserRepository;
import com.onmu.api.domain.VoteEntity;
import com.onmu.api.domain.VoteOptionEntity;
import com.onmu.api.domain.VoteOptionRepository;
import com.onmu.api.domain.VoteResponseRepository;
import com.onmu.api.domain.VoteRepository;
import com.onmu.api.web.dto.CreatePlaceCandidateRequest;
import com.onmu.api.web.dto.CreateSchedulePlaceRequest;
import com.onmu.api.web.dto.CreateVoteRequest;
import com.onmu.api.web.dto.SettlementDraftItemRequest;
import com.onmu.api.web.dto.SettlementPreviewRequest;
import com.onmu.api.web.dto.UpdatePlanRequest;
import com.onmu.api.web.dto.UpsertPlaceCandidateHeartRequest;
import com.onmu.api.web.dto.UpsertPlanParticipantRequest;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

@ExtendWith(MockitoExtension.class)
class OnmuApiServiceTests {
  @Mock
  private UserRepository userRepository;
  @Mock
  private AuthIdentityRepository authIdentityRepository;
  @Mock
  private GroupRepository groupRepository;
  @Mock
  private PlanRepository planRepository;
  @Mock
  private VoteRepository voteRepository;
  @Mock
  private ExternalPlaceRepository externalPlaceRepository;
  @Mock
  private PlaceCandidateRepository placeCandidateRepository;
  @Mock
  private PlaceCandidateHeartRepository placeCandidateHeartRepository;
  @Mock
  private SchedulePlaceRepository schedulePlaceRepository;
  @Mock
  private PlanParticipantRepository planParticipantRepository;
  @Mock
  private SettlementDraftRepository settlementDraftRepository;
  @Mock
  private SettlementRepository settlementRepository;
  @Mock
  private VoteOptionRepository voteOptionRepository;
  @Mock
  private VoteResponseRepository voteResponseRepository;
  @Mock
  private OutboxService outboxService;

  private OnmuApiService service;
  private GroupEntity group;
  private PlanEntity plan;
  private VoteEntity vote;

  @BeforeEach
  void setUp() {
    service = new OnmuApiService(
      userRepository,
      authIdentityRepository,
      groupRepository,
      planRepository,
      voteRepository,
      externalPlaceRepository,
      placeCandidateRepository,
      placeCandidateHeartRepository,
      schedulePlaceRepository,
      planParticipantRepository,
      settlementDraftRepository,
      settlementRepository,
      voteOptionRepository,
      voteResponseRepository,
      outboxService,
      new ObjectMapper()
    );
    group = new GroupEntity("1", "ONMU 개발 모임", null);
    plan = new PlanEntity("101", group, "ONMU API 계약 검증", Instant.parse("2026-06-12T01:00:00Z"), "confirmed");
    vote = new VoteEntity("501", group, "PLAN", "101", "PLACE", "장소 후보 선호 투표", "{\"options\":[\"카페\",\"식당\"]}");
  }

  @Test
  void seedIdsAreResolved() {
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(planRepository.findByGroupOrderByStartsAtAsc(group)).thenReturn(List.of(plan));
    when(voteRepository.findByGroupOrderByCreatedAtAsc(group)).thenReturn(List.of(vote));
    when(planRepository.findByGroupAndPublicId(group, "101")).thenReturn(Optional.of(plan));
    when(voteRepository.findByGroupAndPublicId(group, "501")).thenReturn(Optional.of(vote));

    assertThat(service.groupSummary("1")).extracting("group").isNotNull();
    assertThat(service.plan("1", "101")).containsEntry("id", "101");
    assertThat(service.vote("1", "501")).containsEntry("id", "501");
  }

  @Test
  void homeSummaryUsesAuthenticatedViewer() {
    UserEntity viewer = user("00000000-0000-0000-0000-000000000099", "인증 사용자");
    when(groupRepository.findAllByOrderByCreatedAtAsc()).thenReturn(List.of(group));
    when(planRepository.findByGroupOrderByStartsAtAsc(group)).thenReturn(List.of(plan));
    when(voteRepository.findByGroupOrderByCreatedAtAsc(group)).thenReturn(List.of(vote));
    when(userRepository.findByIdAndDeletedAtIsNull(viewer.getId())).thenReturn(Optional.of(viewer));
    when(authIdentityRepository.findFirstByUserOrderByCreatedAtAsc(viewer)).thenReturn(Optional.empty());

    Map<String, Object> summary = service.homeSummary(viewer.getId());

    assertThat(summary).extracting("viewer")
      .isInstanceOfSatisfying(Map.class, viewerValue ->
        assertThat(viewerValue).containsEntry("displayName", "인증 사용자"));
  }

  @Test
  void missingGroupIdReturns404WithoutSeedFallback() {
    when(groupRepository.findByPublicId("not-found")).thenReturn(Optional.empty());

    assertThatThrownBy(() -> service.groupSummary("not-found"))
      .isInstanceOfSatisfying(ResponseStatusException.class, exception ->
        assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND));
  }

  @Test
  void missingPlanIdReturns404WithoutSeedFallback() {
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(planRepository.findByGroupAndPublicId(group, "not-found")).thenReturn(Optional.empty());

    assertThatThrownBy(() -> service.plan("1", "not-found"))
      .isInstanceOfSatisfying(ResponseStatusException.class, exception ->
        assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND));
  }

  @Test
  void updatePlanRejectsBlankTitle() {
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(planRepository.findByGroupAndPublicId(group, "101")).thenReturn(Optional.of(plan));

    assertThatThrownBy(() -> service.updatePlan(
      "1",
      "101",
      new UpdatePlanRequest(" ", null, null)
    ))
      .isInstanceOfSatisfying(ResponseStatusException.class, exception -> {
        assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(exception.getReason()).isEqualTo("blank_plan_title");
      });
  }

  @Test
  void updatePlanRecordsOutboxEvent() {
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(planRepository.findByGroupAndPublicId(group, "101")).thenReturn(Optional.of(plan));

    var updated = service.updatePlan(
      "1",
      "101",
      new UpdatePlanRequest("업데이트 약속", "2026-06-13T01:00:00Z", "draft")
    );

    assertThat(updated)
      .containsEntry("id", "101")
      .containsEntry("title", "업데이트 약속")
      .containsEntry("startsAt", "2026-06-13T01:00:00Z")
      .containsEntry("status", "draft");
    verify(outboxService).record(
      eq("plan.updated"),
      eq("plan"),
      any(),
      argThat(payload -> "1".equals(payload.get("groupId"))
        && "101".equals(payload.get("planId"))
        && "업데이트 약속".equals(payload.get("title")))
    );
  }

  @Test
  void missingVoteIdReturns404WithoutSeedFallback() {
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(voteRepository.findByGroupAndPublicId(group, "not-found")).thenReturn(Optional.empty());

    assertThatThrownBy(() -> service.vote("1", "not-found"))
      .isInstanceOfSatisfying(ResponseStatusException.class, exception ->
        assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND));
  }

  @Test
  void voteDetailKeepsStringOptionsWhenNoVoteOptionRowsExist() {
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(voteRepository.findByGroupAndPublicId(group, "501")).thenReturn(Optional.of(vote));
    when(voteOptionRepository.findByVoteOrderBySortOrderAsc(vote)).thenReturn(List.of());

    var detail = service.vote("1", "501");

    assertThat(detail.get("options")).isEqualTo(List.of("카페", "식당"));
  }

  @Test
  void creatingVoteRecordsOutboxEvent() {
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(planRepository.findByGroupAndPublicId(group, "101")).thenReturn(Optional.of(plan));
    when(voteRepository.findAll()).thenReturn(List.of(vote));
    when(voteRepository.save(any(VoteEntity.class))).thenAnswer(invocation -> invocation.getArgument(0));

    var created = service.createVote("1", new CreateVoteRequest(
      "PLACE",
      "PLAN",
      "101",
      "CD smoke vote",
      List.of("A", "B")
    ));

    assertThat(created).containsEntry("id", "502");
    verify(outboxService).record(
      eq("vote.created"),
      eq("vote"),
      any(),
      argThat(payload -> "1".equals(payload.get("groupId"))
        && "502".equals(payload.get("voteId"))
        && "PLAN".equals(payload.get("targetType"))
        && "101".equals(payload.get("targetId")))
    );
  }

  @Test
  void creatingPlaceCandidateVoteConnectsCandidateOptionDetails() {
    PlaceCandidateEntity candidate = new PlaceCandidateEntity(
      "201",
      group,
      plan,
      "온무식당",
      "한식",
      "서울",
      "{\"favoriteCount\":2}"
    );
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(planRepository.findByGroupAndPublicId(group, "101")).thenReturn(Optional.of(plan));
    when(voteRepository.findAll()).thenReturn(List.of(vote));
    when(voteRepository.save(any(VoteEntity.class))).thenAnswer(invocation -> invocation.getArgument(0));
    when(voteOptionRepository.save(any(VoteOptionEntity.class))).thenAnswer(invocation -> invocation.getArgument(0));
    when(placeCandidateRepository.findByPlanAndPublicId(plan, "201")).thenReturn(Optional.of(candidate));
    when(placeCandidateHeartRepository.countByCandidate(candidate)).thenReturn(3L);

    var created = service.createVote("1", new CreateVoteRequest(
      "PLACE",
      "PLAN",
      "101",
      "장소 후보 투표",
      List.of("201")
    ));

    assertThat(created).containsEntry("id", "502");
    assertThat(created.get("options")).asList()
      .singleElement()
      .satisfies(option -> {
        assertThat(option).isInstanceOf(java.util.Map.class);
        java.util.Map<?, ?> optionMap = (java.util.Map<?, ?>) option;
        assertThat(optionMap.get("candidateId")).isEqualTo("201");
        assertThat(optionMap.get("candidateName")).isEqualTo("온무식당");
        assertThat(optionMap.get("address")).isEqualTo("서울");
        assertThat(optionMap.get("heartCount")).isEqualTo(3);
      });
  }

  @Test
  void voteDetailReturnsPlaceCandidateOptionDetails() {
    PlaceCandidateEntity candidate = new PlaceCandidateEntity("201", group, plan, "온무식당", "한식", "서울", "{}");
    VoteOptionEntity option = new VoteOptionEntity(
      vote,
      "vopt-501-1",
      "온무식당",
      "PLACE_CANDIDATE",
      "201",
      1,
      "{\"candidateId\":\"201\"}"
    );
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(voteRepository.findByGroupAndPublicId(group, "501")).thenReturn(Optional.of(vote));
    when(voteOptionRepository.findByVoteOrderBySortOrderAsc(vote)).thenReturn(List.of(option));
    when(planRepository.findByGroupAndPublicId(group, "101")).thenReturn(Optional.of(plan));
    when(placeCandidateRepository.findByPlanAndPublicId(plan, "201")).thenReturn(Optional.of(candidate));
    when(placeCandidateHeartRepository.countByCandidate(candidate)).thenReturn(2L);
    when(voteResponseRepository.countByVote(vote)).thenReturn(4L);
    when(voteResponseRepository.countByVoteOption(option)).thenReturn(3L);

    var detail = service.vote("1", "501");

    assertThat(detail.get("options")).asList()
      .singleElement()
      .satisfies(rawOption -> {
        java.util.Map<?, ?> optionMap = (java.util.Map<?, ?>) rawOption;
        assertThat(optionMap.get("label")).isEqualTo("온무식당");
        assertThat(optionMap.get("candidateId")).isEqualTo("201");
        assertThat(optionMap.get("candidateName")).isEqualTo("온무식당");
        assertThat(optionMap.get("address")).isEqualTo("서울");
        assertThat(optionMap.get("heartCount")).isEqualTo(2);
        assertThat(optionMap.get("responseCount")).isEqualTo(3);
        assertThat(optionMap.get("countLabel")).isEqualTo("3표");
        assertThat(optionMap.get("progress")).isEqualTo(0.75);
      });
  }

  @Test
  void voteListReturnsPlaceCandidateOptionDetails() {
    PlaceCandidateEntity candidate = new PlaceCandidateEntity("201", group, plan, "온무식당", "한식", "서울", "{}");
    VoteOptionEntity option = new VoteOptionEntity(
      vote,
      "vopt-501-1",
      "온무식당",
      "PLACE_CANDIDATE",
      "201",
      1,
      "{\"candidateId\":\"201\"}"
    );
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(voteRepository.findByGroupOrderByCreatedAtAsc(group)).thenReturn(List.of(vote));
    when(voteOptionRepository.findByVoteOrderBySortOrderAsc(vote)).thenReturn(List.of(option));
    when(planRepository.findByGroupAndPublicId(group, "101")).thenReturn(Optional.of(plan));
    when(placeCandidateRepository.findByPlanAndPublicId(plan, "201")).thenReturn(Optional.of(candidate));
    when(placeCandidateHeartRepository.countByCandidate(candidate)).thenReturn(2L);

    var votes = service.votes("1");

    assertThat(votes).singleElement()
      .satisfies(rawVote -> assertThat((List<?>) rawVote.get("options"))
        .singleElement()
        .satisfies(rawOption -> {
          java.util.Map<?, ?> optionMap = (java.util.Map<?, ?>) rawOption;
          assertThat(optionMap.get("candidateId")).isEqualTo("201");
          assertThat(optionMap.get("candidateName")).isEqualTo("온무식당");
        }));
  }

  @Test
  void creatingPlaceCandidateVoteRejectsInvalidCandidateId() {
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(planRepository.findByGroupAndPublicId(group, "101")).thenReturn(Optional.of(plan));
    when(placeCandidateRepository.findByPlanAndPublicId(plan, "999")).thenReturn(Optional.empty());

    assertThatThrownBy(() -> service.createVote("1", new CreateVoteRequest(
      "PLACE",
      "PLAN",
      "101",
      "잘못된 후보 투표",
      List.of(),
      List.of("999")
    )))
      .isInstanceOfSatisfying(ResponseStatusException.class, exception -> {
        assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND);
        assertThat(exception.getReason()).isEqualTo("place_candidate_not_found");
      });
  }

  @Test
  void voteCreatedOutboxPayloadPreservesCandidateIdsAndOptions() {
    PlaceCandidateEntity candidate = new PlaceCandidateEntity("201", group, plan, "온무식당", "한식", "서울", "{}");
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(planRepository.findByGroupAndPublicId(group, "101")).thenReturn(Optional.of(plan));
    when(voteRepository.findAll()).thenReturn(List.of(vote));
    when(voteRepository.save(any(VoteEntity.class))).thenAnswer(invocation -> invocation.getArgument(0));
    when(placeCandidateRepository.findByPlanAndPublicId(plan, "201")).thenReturn(Optional.of(candidate));

    service.createVote("1", new CreateVoteRequest(
      "PLACE",
      "PLAN",
      "101",
      "장소 후보 투표",
      List.of(),
      List.of("201")
    ));

    verify(outboxService).record(
      eq("vote.created"),
      eq("vote"),
      any(),
      argThat(payload -> List.of("201").equals(payload.get("candidateIds"))
        && List.of("온무식당").equals(payload.get("options")))
    );
  }

  @Test
  void creatingGroupTargetVoteDoesNotAutofillPlanTargetId() {
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(voteRepository.findAll()).thenReturn(List.of(vote));
    when(voteRepository.save(any(VoteEntity.class))).thenAnswer(invocation -> invocation.getArgument(0));

    var created = service.createVote("1", new CreateVoteRequest(
      "PLACE",
      "GROUP",
      null,
      "Group vote",
      List.of("A", "B")
    ));

    assertThat(created)
      .containsEntry("targetType", "GROUP")
      .containsEntry("targetId", null);
    verify(outboxService).record(
      eq("vote.created"),
      eq("vote"),
      any(),
      argThat(payload -> "GROUP".equals(payload.get("targetType"))
        && payload.containsKey("targetId")
        && payload.get("targetId") == null)
    );
  }

  @Test
  void missingTargetTypeDefaultsToGroup() {
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(voteRepository.findAll()).thenReturn(List.of(vote));
    when(voteRepository.save(any(VoteEntity.class))).thenAnswer(invocation -> invocation.getArgument(0));

    var created = service.createVote("1", new CreateVoteRequest(
      "PLACE",
      null,
      null,
      "Default group vote",
      List.of("A", "B")
    ));

    assertThat(created)
      .containsEntry("targetType", "GROUP")
      .containsEntry("targetId", null);
  }

  @Test
  void planTargetRequiresTargetId() {
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));

    assertThatThrownBy(() -> service.createVote("1", new CreateVoteRequest(
      "PLACE",
      "PLAN",
      null,
      "Missing target",
      List.of("A", "B")
    )))
      .isInstanceOfSatisfying(ResponseStatusException.class, exception -> {
        assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(exception.getReason()).isEqualTo("missing_vote_target_id");
      });
  }

  @Test
  void planTargetMustExistInsideSameGroup() {
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(planRepository.findByGroupAndPublicId(group, "not-found")).thenReturn(Optional.empty());

    assertThatThrownBy(() -> service.createVote("1", new CreateVoteRequest(
      "PLACE",
      "PLAN",
      "not-found",
      "Missing plan target",
      List.of("A", "B")
    )))
      .isInstanceOfSatisfying(ResponseStatusException.class, exception -> {
        assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND);
        assertThat(exception.getReason()).isEqualTo("plan_not_found");
      });
  }

  @Test
  void unsupportedTargetTypeReturns400() {
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));

    assertThatThrownBy(() -> service.createVote("1", new CreateVoteRequest(
      "PLACE",
      "BOGUS",
      "101",
      "Invalid target",
      List.of("A", "B")
    )))
      .isInstanceOfSatisfying(ResponseStatusException.class, exception -> {
        assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(exception.getReason()).isEqualTo("invalid_vote_target_type");
      });
  }

  @Test
  void participantsFallbackToCurrentUserWhenNoRowsExist() {
    UserEntity user = user("00000000-0000-0000-0000-000000000001", "테스트 사용자");
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(planRepository.findByGroupAndPublicId(group, "101")).thenReturn(Optional.of(plan));
    when(planParticipantRepository.findByPlanOrderByCreatedAtAsc(plan)).thenReturn(List.of());
    when(userRepository.findFirstByOrderByCreatedAtAsc()).thenReturn(Optional.of(user));

    var participants = service.planParticipants("1", "101");

    assertThat(participants).singleElement()
      .satisfies(participant -> assertThat(participant)
        .containsEntry("userId", user.getId().toString())
        .containsEntry("displayName", "테스트 사용자")
        .containsEntry("status", "joined")
        .containsEntry("response", "accepted")
        .containsEntry("fallback", true));
  }

  @Test
  void upsertingMyParticipantResponseCreatesAndUpdatesOutboxEvent() {
    UserEntity user = user("00000000-0000-0000-0000-000000000001", "테스트 사용자");
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(planRepository.findByGroupAndPublicId(group, "101")).thenReturn(Optional.of(plan));
    when(userRepository.findFirstByOrderByCreatedAtAsc()).thenReturn(Optional.of(user));
    when(planParticipantRepository.findByPlanAndUser(plan, user)).thenReturn(Optional.empty());
    when(planParticipantRepository.save(any(PlanParticipantEntity.class))).thenAnswer(invocation -> invocation.getArgument(0));

    var created = service.upsertMyPlanParticipant(
      "1",
      "101",
      new UpsertPlanParticipantRequest("joined", "accepted")
    );

    assertThat(created)
      .containsEntry("userId", user.getId().toString())
      .containsEntry("status", "joined")
      .containsEntry("response", "accepted");
    verify(outboxService).record(
      eq("plan.participant_updated"),
      eq("plan_participant"),
      any(),
      argThat(payload -> "1".equals(payload.get("groupId"))
        && "101".equals(payload.get("planId"))
        && user.getId().toString().equals(payload.get("userId"))
        && "joined".equals(payload.get("status"))
        && "accepted".equals(payload.get("response")))
    );
  }

  @Test
  void creatingPlaceCandidateRecordsOutboxEvent() {
    UserEntity user = user("00000000-0000-0000-0000-000000000001", "테스트 사용자");
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(planRepository.findByGroupAndPublicId(group, "101")).thenReturn(Optional.of(plan));
    when(userRepository.findFirstByOrderByCreatedAtAsc()).thenReturn(Optional.of(user));
    when(placeCandidateRepository.findAll()).thenReturn(List.of(
      new PlaceCandidateEntity("201", group, plan, "온무식당", "한식", "서울", "{}")
    ));
    when(placeCandidateRepository.save(any(PlaceCandidateEntity.class))).thenAnswer(invocation -> invocation.getArgument(0));
    when(placeCandidateHeartRepository.countByCandidate(any(PlaceCandidateEntity.class))).thenReturn(0L);
    when(placeCandidateHeartRepository.existsByCandidateAndUser(any(PlaceCandidateEntity.class), eq(user))).thenReturn(false);

    var created = service.createPlaceCandidate(
      "1",
      "101",
      new CreatePlaceCandidateRequest("새 후보", "카페", "서울", "후보 설명", List.of("카페"))
    );

    assertThat(created)
      .containsEntry("id", "202")
      .containsEntry("name", "새 후보")
      .containsEntry("heartCount", 0)
      .containsEntry("myHearted", false);
    verify(outboxService).record(
      eq("place_candidate.created"),
      eq("place_candidate"),
      any(),
      argThat(payload -> "1".equals(payload.get("groupId"))
        && "101".equals(payload.get("planId"))
        && "202".equals(payload.get("candidateId")))
    );
  }

  @Test
  void creatingPlaceCandidateStoresExternalPlaceSnapshot() {
    UserEntity user = user("00000000-0000-0000-0000-000000000001", "테스트 사용자");
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(planRepository.findByGroupAndPublicId(group, "101")).thenReturn(Optional.of(plan));
    when(userRepository.findFirstByOrderByCreatedAtAsc()).thenReturn(Optional.of(user));
    when(placeCandidateRepository.findAll()).thenReturn(List.of());
    when(externalPlaceRepository.findByProviderAndProviderPlaceId("KAKAO", "kakao-123"))
      .thenReturn(Optional.empty());
    when(externalPlaceRepository.save(any(ExternalPlaceEntity.class))).thenAnswer(invocation -> invocation.getArgument(0));
    when(placeCandidateRepository.save(any(PlaceCandidateEntity.class))).thenAnswer(invocation -> invocation.getArgument(0));
    when(placeCandidateHeartRepository.countByCandidate(any(PlaceCandidateEntity.class))).thenReturn(0L);
    when(placeCandidateHeartRepository.existsByCandidateAndUser(any(PlaceCandidateEntity.class), eq(user))).thenReturn(false);

    var created = service.createPlaceCandidate(
      "1",
      "101",
      new CreatePlaceCandidateRequest(
        "검색 후보",
        "카페",
        "서울 지번주소",
        "검색 결과에서 추가한 후보",
        List.of("카페"),
        "kakao",
        "kakao-123",
        "서울 도로명주소",
        37.501,
        127.001,
        null,
        null,
        "https://place.map.kakao.com/123",
        "2026-06-10T00:00:00Z"
      )
    );

    assertThat(created)
      .containsEntry("id", "201")
      .containsEntry("provider", "KAKAO")
      .containsEntry("providerPlaceId", "kakao-123")
      .containsEntry("source", "kakao")
      .containsEntry("roadAddress", "서울 도로명주소")
      .containsEntry("lat", 37.501)
      .containsEntry("lng", 127.001)
      .containsKey("externalPlaceId");
    verify(externalPlaceRepository).save(argThat((ExternalPlaceEntity place) ->
      "KAKAO".equals(place.getProvider())
        && "kakao-123".equals(place.getProviderPlaceId())
        && "검색 후보".equals(place.getName())
        && "서울 도로명주소".equals(place.getRoadAddress())
        && Double.valueOf(37.501).equals(place.getLatitude())
        && Double.valueOf(127.001).equals(place.getLongitude())
    ));
  }

  @Test
  void placeCandidateDetailReturnsHeartStateAndDisplayFields() {
    UserEntity user = user("00000000-0000-0000-0000-000000000001", "테스트 사용자");
    PlaceCandidateEntity candidate = new PlaceCandidateEntity(
      "201",
      group,
      plan,
      "온무식당",
      "한식",
      "서울",
      "{\"source\":\"manual\",\"lat\":37.5665,\"lng\":126.9780,\"favoriteCount\":3}"
    );
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(planRepository.findByGroupAndPublicId(group, "101")).thenReturn(Optional.of(plan));
    when(placeCandidateRepository.findByPlanAndPublicId(plan, "201")).thenReturn(Optional.of(candidate));
    when(userRepository.findFirstByOrderByCreatedAtAsc()).thenReturn(Optional.of(user));
    when(placeCandidateHeartRepository.countByCandidate(candidate)).thenReturn(4L);
    when(placeCandidateHeartRepository.existsByCandidateAndUser(candidate, user)).thenReturn(true);

    var detail = service.placeCandidate("1", "101", "201");

    assertThat(detail)
      .containsEntry("id", "201")
      .containsEntry("name", "온무식당")
      .containsEntry("address", "서울")
      .containsEntry("source", "manual")
      .containsEntry("heartCount", 4)
      .containsEntry("myHearted", true)
      .containsEntry("lat", 37.5665)
      .containsEntry("lng", 126.9780);
    assertThat(detail).containsKey("createdAt");
  }

  @Test
  void placeCandidateListIncludesHeartState() {
    UserEntity user = user("00000000-0000-0000-0000-000000000001", "테스트 사용자");
    PlaceCandidateEntity candidate = new PlaceCandidateEntity(
      "201",
      group,
      plan,
      "온무식당",
      "한식",
      "서울",
      "{\"favoriteCount\":3}"
    );
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(planRepository.findByGroupAndPublicId(group, "101")).thenReturn(Optional.of(plan));
    when(userRepository.findFirstByOrderByCreatedAtAsc()).thenReturn(Optional.of(user));
    when(placeCandidateRepository.findByPlanOrderByCreatedAtAsc(plan)).thenReturn(List.of(candidate));
    when(placeCandidateHeartRepository.countByCandidate(candidate)).thenReturn(5L);
    when(placeCandidateHeartRepository.existsByCandidateAndUser(candidate, user)).thenReturn(true);

    var candidates = service.placeCandidates("1", "101");

    assertThat(candidates).singleElement()
      .satisfies(value -> assertThat(value)
        .containsEntry("id", "201")
        .containsEntry("heartCount", 5)
        .containsEntry("myHearted", true));
  }

  @Test
  void upsertingMyPlaceCandidateHeartCreatesHeartOnceAndRecordsOutboxEvent() {
    UserEntity user = user("00000000-0000-0000-0000-000000000001", "테스트 사용자");
    PlaceCandidateEntity candidate = new PlaceCandidateEntity("201", group, plan, "온무식당", "한식", "서울", "{}");
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(planRepository.findByGroupAndPublicId(group, "101")).thenReturn(Optional.of(plan));
    when(placeCandidateRepository.findByPlanAndPublicId(plan, "201")).thenReturn(Optional.of(candidate));
    when(userRepository.findFirstByOrderByCreatedAtAsc()).thenReturn(Optional.of(user));
    when(placeCandidateHeartRepository.findByCandidateAndUser(candidate, user)).thenReturn(Optional.empty());
    when(placeCandidateHeartRepository.save(any(PlaceCandidateHeartEntity.class))).thenAnswer(invocation -> invocation.getArgument(0));
    when(placeCandidateHeartRepository.countByCandidate(candidate)).thenReturn(1L);
    when(placeCandidateHeartRepository.existsByCandidateAndUser(candidate, user)).thenReturn(true);

    var result = service.upsertMyPlaceCandidateHeart(
      "1",
      "101",
      "201",
      new UpsertPlaceCandidateHeartRequest(true)
    );

    assertThat(result)
      .containsEntry("id", "201")
      .containsEntry("heartCount", 1)
      .containsEntry("myHearted", true);
    verify(placeCandidateHeartRepository, times(1)).save(any(PlaceCandidateHeartEntity.class));
    verify(outboxService).record(
      eq("place_candidate.heart_updated"),
      eq("place_candidate"),
      eq(candidate.getId()),
      argThat(payload -> "1".equals(payload.get("groupId"))
        && "101".equals(payload.get("planId"))
        && "201".equals(payload.get("candidateId"))
        && Boolean.TRUE.equals(payload.get("hearted")))
    );
  }

  @Test
  void upsertingExistingHeartDoesNotCreateDuplicateHeart() {
    UserEntity user = user("00000000-0000-0000-0000-000000000001", "테스트 사용자");
    PlaceCandidateEntity candidate = new PlaceCandidateEntity("201", group, plan, "온무식당", "한식", "서울", "{}");
    PlaceCandidateHeartEntity existingHeart = new PlaceCandidateHeartEntity(candidate, user);
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(planRepository.findByGroupAndPublicId(group, "101")).thenReturn(Optional.of(plan));
    when(placeCandidateRepository.findByPlanAndPublicId(plan, "201")).thenReturn(Optional.of(candidate));
    when(userRepository.findFirstByOrderByCreatedAtAsc()).thenReturn(Optional.of(user));
    when(placeCandidateHeartRepository.findByCandidateAndUser(candidate, user)).thenReturn(Optional.of(existingHeart));
    when(placeCandidateHeartRepository.countByCandidate(candidate)).thenReturn(1L);
    when(placeCandidateHeartRepository.existsByCandidateAndUser(candidate, user)).thenReturn(true);

    var result = service.upsertMyPlaceCandidateHeart(
      "1",
      "101",
      "201",
      new UpsertPlaceCandidateHeartRequest(true)
    );

    assertThat(result).containsEntry("heartCount", 1).containsEntry("myHearted", true);
    verify(placeCandidateHeartRepository, times(0)).save(any(PlaceCandidateHeartEntity.class));
  }

  @Test
  void creatingSchedulePlaceRecordsOutboxEventAndReturnsScheduleFields() {
    PlaceCandidateEntity candidate = new PlaceCandidateEntity("201", group, plan, "온무식당", "한식", "서울", "{}");
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(planRepository.findByGroupAndPublicId(group, "101")).thenReturn(Optional.of(plan));
    when(placeCandidateRepository.findByPlanAndPublicId(plan, "201")).thenReturn(Optional.of(candidate));
    when(schedulePlaceRepository.findAll()).thenReturn(List.of(
      new SchedulePlaceEntity("701", group, plan, candidate, "기존 장소", null, 1)
    ));
    when(schedulePlaceRepository.findByPlanOrderBySortOrderAsc(plan)).thenReturn(List.of());
    when(schedulePlaceRepository.save(any(SchedulePlaceEntity.class))).thenAnswer(invocation -> invocation.getArgument(0));

    var created = service.createSchedulePlace(
      "1",
      "101",
      new CreateSchedulePlaceRequest("201", null, "2026-06-12T02:00:00Z", "2026-06-12T03:00:00Z", "점심")
    );

    assertThat(created)
      .containsEntry("id", "702")
      .containsEntry("candidateId", "201")
      .containsEntry("placeName", "온무식당")
      .containsEntry("startsAt", "2026-06-12T02:00:00Z")
      .containsEntry("endsAt", "2026-06-12T03:00:00Z")
      .containsEntry("note", "점심");
    verify(outboxService).record(
      eq("schedule_place.created"),
      eq("schedule_place"),
      any(),
      argThat(payload -> "1".equals(payload.get("groupId"))
        && "101".equals(payload.get("planId"))
        && "702".equals(payload.get("schedulePlaceId"))
        && "201".equals(payload.get("candidateId")))
    );
  }

  @Test
  void creatingSettlementRecordsSettlementAndNotificationOutboxEvents() {
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(planRepository.findByGroupAndPublicId(group, "101")).thenReturn(Optional.of(plan));
    when(settlementRepository.findAll()).thenReturn(List.of(
      new SettlementEntity("301", group, plan, "{}")
    ));
    when(settlementRepository.save(any(SettlementEntity.class))).thenAnswer(invocation -> invocation.getArgument(0));

    var created = service.createSettlement("1", "101", new SettlementPreviewRequest(List.of(settlementItem())));

    assertThat(created).containsEntry("id", "302").containsEntry("preview", false);
    verify(outboxService).record(
      eq("settlement.created"),
      eq("settlement"),
      any(),
      argThat(payload -> "302".equals(payload.get("settlementId")))
    );
    verify(outboxService).record(
      eq("notification.requested"),
      eq("settlement"),
      any(),
      argThat(payload -> "activity".equals(payload.get("channel"))
        && "302".equals(payload.get("settlementId")))
    );
  }

  @Test
  void emptySettlementRequestReturns400() {
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(planRepository.findByGroupAndPublicId(group, "101")).thenReturn(Optional.of(plan));

    assertThatThrownBy(() -> service.createSettlement("1", "101", new SettlementPreviewRequest(List.of())))
      .isInstanceOfSatisfying(ResponseStatusException.class, exception -> {
        assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(exception.getReason()).isEqualTo("missing_settlement_items");
      });
  }

  private SettlementDraftItemRequest settlementItem() {
    return new SettlementDraftItemRequest(
      "401",
      "Coffee",
      12000,
      12000,
      null,
      "Jimin",
      "equal",
      List.of(),
      List.of("Jimin", "Minsu")
    );
  }

  private UserEntity user(String id, String displayName) {
    return new UserEntity(java.util.UUID.fromString(id), displayName);
  }
}
