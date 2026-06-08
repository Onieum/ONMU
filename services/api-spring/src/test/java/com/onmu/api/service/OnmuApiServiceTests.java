package com.onmu.api.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.argThat;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.onmu.api.domain.AuthIdentityRepository;
import com.onmu.api.domain.GroupEntity;
import com.onmu.api.domain.GroupRepository;
import com.onmu.api.domain.PlaceCandidateEntity;
import com.onmu.api.domain.PlaceCandidateRepository;
import com.onmu.api.domain.PlanEntity;
import com.onmu.api.domain.PlanRepository;
import com.onmu.api.domain.SchedulePlaceRepository;
import com.onmu.api.domain.SettlementDraftRepository;
import com.onmu.api.domain.SettlementEntity;
import com.onmu.api.domain.SettlementRepository;
import com.onmu.api.domain.UserRepository;
import com.onmu.api.domain.VoteEntity;
import com.onmu.api.domain.VoteRepository;
import com.onmu.api.web.dto.CreatePlaceCandidateRequest;
import com.onmu.api.web.dto.CreateVoteRequest;
import com.onmu.api.web.dto.SettlementPreviewRequest;
import java.time.Instant;
import java.util.List;
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
  private PlaceCandidateRepository placeCandidateRepository;
  @Mock
  private SchedulePlaceRepository schedulePlaceRepository;
  @Mock
  private SettlementDraftRepository settlementDraftRepository;
  @Mock
  private SettlementRepository settlementRepository;
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
      placeCandidateRepository,
      schedulePlaceRepository,
      settlementDraftRepository,
      settlementRepository,
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
  void missingVoteIdReturns404WithoutSeedFallback() {
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(voteRepository.findByGroupAndPublicId(group, "not-found")).thenReturn(Optional.empty());

    assertThatThrownBy(() -> service.vote("1", "not-found"))
      .isInstanceOfSatisfying(ResponseStatusException.class, exception ->
        assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND));
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
  void creatingPlaceCandidateRecordsOutboxEvent() {
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(planRepository.findByGroupAndPublicId(group, "101")).thenReturn(Optional.of(plan));
    when(placeCandidateRepository.findAll()).thenReturn(List.of(
      new PlaceCandidateEntity("201", group, plan, "온무식당", "한식", "서울", "{}")
    ));
    when(placeCandidateRepository.save(any(PlaceCandidateEntity.class))).thenAnswer(invocation -> invocation.getArgument(0));

    var created = service.createPlaceCandidate(
      "1",
      "101",
      new CreatePlaceCandidateRequest("새 후보", "카페", "서울", "후보 설명", List.of("카페"))
    );

    assertThat(created).containsEntry("id", "202").containsEntry("name", "새 후보");
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
  void creatingSettlementRecordsSettlementAndNotificationOutboxEvents() {
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(planRepository.findByGroupAndPublicId(group, "101")).thenReturn(Optional.of(plan));
    when(settlementRepository.findAll()).thenReturn(List.of(
      new SettlementEntity("301", group, plan, "{}")
    ));
    when(settlementRepository.save(any(SettlementEntity.class))).thenAnswer(invocation -> invocation.getArgument(0));

    var created = service.createSettlement("1", "101", new SettlementPreviewRequest(List.of()));

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
}
