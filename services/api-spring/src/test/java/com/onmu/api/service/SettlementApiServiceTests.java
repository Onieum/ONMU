package com.onmu.api.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.argThat;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.inOrder;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.onmu.api.domain.ChatActivityEventEntity;
import com.onmu.api.domain.ChatActivityEventRepository;
import com.onmu.api.domain.CharacterProfileRepository;
import com.onmu.api.domain.GroupEntity;
import com.onmu.api.domain.GroupMemberRepository;
import com.onmu.api.domain.GroupRepository;
import com.onmu.api.domain.NotificationEntity;
import com.onmu.api.domain.NotificationRepository;
import com.onmu.api.domain.PlanEntity;
import com.onmu.api.domain.PlanParticipantEntity;
import com.onmu.api.domain.PlanParticipantRepository;
import com.onmu.api.domain.PlanRepository;
import com.onmu.api.domain.SchedulePlaceRepository;
import com.onmu.api.domain.SettlementConfirmationEntity;
import com.onmu.api.domain.SettlementConfirmationRepository;
import com.onmu.api.domain.SettlementDraftRepository;
import com.onmu.api.domain.SettlementEntity;
import com.onmu.api.domain.SettlementItemEntity;
import com.onmu.api.domain.SettlementItemRepository;
import com.onmu.api.domain.SettlementItemTargetEntity;
import com.onmu.api.domain.SettlementItemTargetRepository;
import com.onmu.api.domain.SettlementRepository;
import com.onmu.api.domain.SettlementSectionEntity;
import com.onmu.api.domain.SettlementSectionRepository;
import com.onmu.api.domain.SettlementTransferEntity;
import com.onmu.api.domain.SettlementTransferRepository;
import com.onmu.api.domain.UserEntity;
import com.onmu.api.domain.UserRepository;
import com.onmu.api.web.dto.SettlementDraftItemRequest;
import com.onmu.api.web.dto.SettlementDraftSectionRequest;
import com.onmu.api.web.dto.SettlementPreviewRequest;
import com.onmu.api.web.dto.SettlementTargetShareRequest;
import com.onmu.api.web.dto.UpdateSettlementDraftRequest;
import com.onmu.api.web.dto.UpdateSettlementItemTargetsRequest;
import java.time.Instant;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InOrder;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.web.server.ResponseStatusException;

@ExtendWith(MockitoExtension.class)
class SettlementApiServiceTests {
  @Mock
  private GroupRepository groupRepository;
  @Mock
  private PlanRepository planRepository;
  @Mock
  private PlanParticipantRepository planParticipantRepository;
  @Mock
  private SchedulePlaceRepository schedulePlaceRepository;
  @Mock
  private UserRepository userRepository;
  @Mock
  private SettlementDraftRepository settlementDraftRepository;
  @Mock
  private SettlementRepository settlementRepository;
  @Mock
  private SettlementSectionRepository settlementSectionRepository;
  @Mock
  private SettlementItemRepository settlementItemRepository;
  @Mock
  private SettlementItemTargetRepository settlementItemTargetRepository;
  @Mock
  private SettlementTransferRepository settlementTransferRepository;
  @Mock
  private SettlementConfirmationRepository settlementConfirmationRepository;
  @Mock
  private ChatActivityEventRepository chatActivityEventRepository;
  @Mock
  private GroupMemberRepository groupMemberRepository;
  @Mock
  private NotificationRepository notificationRepository;
  @Mock
  private NotificationPreferenceService notificationPreferenceService;
  @Mock
  private OutboxService outboxService;
  @Mock
  private CharacterProfileRepository characterProfileRepository;

  private SettlementApiService service;
  private GroupEntity group;
  private PlanEntity plan;
  private UserEntity me;
  private UserEntity jimin;
  private UserEntity minsu;

  @BeforeEach
  void setUp() {
    service = new SettlementApiService(
      groupRepository,
      planRepository,
      planParticipantRepository,
      schedulePlaceRepository,
      userRepository,
      settlementDraftRepository,
      settlementRepository,
      settlementSectionRepository,
      settlementItemRepository,
      settlementItemTargetRepository,
      settlementTransferRepository,
      settlementConfirmationRepository,
      chatActivityEventRepository,
      groupMemberRepository,
      notificationRepository,
      notificationPreferenceService,
      outboxService,
      new UserAvatarReadModelMapper(characterProfileRepository, new ObjectMapper()),
      new ObjectMapper()
    );
    lenient().when(notificationPreferenceService.isEnabled(any(UUID.class), any(String.class), any(String.class)))
      .thenReturn(true);
    group = new GroupEntity("1", "ONMU 개발 모임", null);
    plan = new PlanEntity("101", group, "ONMU API 계약 검증", Instant.parse("2026-06-12T01:00:00Z"), "scheduled");
    me = user("user-me", "나");
    jimin = user("user-jimin", "지민");
    minsu = user("user-minsu", "민수");

    lenient().when(userRepository.findByIdAndDeletedAtIsNull(me.getId())).thenReturn(Optional.of(me));
    lenient().when(userRepository.findByPublicIdAndDeletedAtIsNull("user-me")).thenReturn(Optional.of(me));
    lenient().when(userRepository.findByPublicIdAndDeletedAtIsNull("user-jimin")).thenReturn(Optional.of(jimin));
    lenient().when(userRepository.findByPublicIdAndDeletedAtIsNull("user-minsu")).thenReturn(Optional.of(minsu));
    lenient().when(groupRepository.isUserMember("1", me.getId())).thenReturn(true);
    lenient().when(planParticipantRepository.findByPlanAndUser(plan, me))
      .thenReturn(Optional.of(new PlanParticipantEntity(plan, me, "joined", "accepted")));
    lenient().when(planParticipantRepository.findByPlanOrderByCreatedAtAsc(plan)).thenReturn(List.of(
      new PlanParticipantEntity(plan, me, "joined", "accepted"),
      new PlanParticipantEntity(plan, jimin, "joined", "accepted"),
      new PlanParticipantEntity(plan, minsu, "joined", "accepted")
    ));
    lenient().when(userRepository.findByPublicIdIn(any())).thenAnswer(invocation -> {
      Collection<?> userIds = invocation.getArgument(0);
      if (userIds == null) {
        return List.of();
      }
      return List.of(me, jimin, minsu).stream()
        .filter(user -> userIds.contains(user.getPublicId()))
        .toList();
    });
    lenient().when(userRepository.findByNicknameIn(any())).thenAnswer(invocation -> {
      Collection<?> names = invocation.getArgument(0);
      if (names == null) {
        return List.of();
      }
      return List.of(me, jimin, minsu).stream()
        .filter(user -> names.contains(user.getNickname()))
        .toList();
    });
    lenient().when(characterProfileRepository.findByUserId(any(UUID.class))).thenReturn(Optional.empty());
  }

  @Test
  void createSettlementDraftRejectsUpcomingPlan() {
    PlanEntity upcoming = new PlanEntity(
      "101",
      group,
      "다가오는 약속",
      Instant.parse("2026-12-01T01:00:00Z"),
      Instant.parse("2026-12-01T03:00:00Z"),
      "scheduled",
      null,
      "수원"
    );
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(planRepository.findByGroupAndPublicId(group, "101")).thenReturn(Optional.of(upcoming));
    when(planParticipantRepository.findByPlanAndUser(upcoming, me))
      .thenReturn(Optional.of(new PlanParticipantEntity(upcoming, me, "joined", "accepted")));

    org.assertj.core.api.Assertions.assertThatThrownBy(() ->
        service.createSettlementDraft("1", "101", me.getId()))
      .isInstanceOfSatisfying(ResponseStatusException.class, exception -> {
        assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(exception.getReason()).isEqualTo("settlement_plan_not_eligible");
      });
  }

  @Test
  void createSettlementDraftReturnsActiveFinalizedSettlement() {
    SettlementEntity finalized = new SettlementEntity("302", group, plan, "{}");
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(planRepository.findByGroupAndPublicId(group, "101")).thenReturn(Optional.of(plan));
    when(settlementRepository.findFirstByPlanAndStatusInOrderByCreatedAtDesc(plan, List.of("finalized", "completed")))
      .thenReturn(Optional.of(finalized));
    when(settlementSectionRepository.findBySettlementOrderBySortOrderAsc(finalized)).thenReturn(List.of());
    when(settlementItemRepository.findBySettlementOrderByCreatedAtAsc(finalized)).thenReturn(List.of());
    when(settlementTransferRepository.findBySettlementOrderByCreatedAtAsc(finalized)).thenReturn(List.of());

    MapLike result = new MapLike(service.createSettlementDraft("1", "101", me.getId()));

    assertThat(result.value("id")).isEqualTo("302");
    assertThat(result.value("status")).isEqualTo("finalized");
    verify(settlementDraftRepository, never()).save(any());
  }

  @Test
  void createSettlementDraftReturnsCompletedSettlementInsteadOfCreatingNewDraft() {
    SettlementEntity completed = new SettlementEntity("302", group, plan, "{}");
    completed.markCompleted();
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(planRepository.findByGroupAndPublicId(group, "101")).thenReturn(Optional.of(plan));
    when(settlementRepository.findFirstByPlanAndStatusInOrderByCreatedAtDesc(
      plan,
      List.of("finalized", "completed")
    )).thenReturn(Optional.of(completed));
    when(settlementSectionRepository.findBySettlementOrderBySortOrderAsc(completed)).thenReturn(List.of());
    when(settlementItemRepository.findBySettlementOrderByCreatedAtAsc(completed)).thenReturn(List.of());
    when(settlementTransferRepository.findBySettlementOrderByCreatedAtAsc(completed)).thenReturn(List.of());

    MapLike result = new MapLike(service.createSettlementDraft("1", "101", me.getId()));

    assertThat(result.value("id")).isEqualTo("302");
    assertThat(result.value("status")).isEqualTo("completed");
    verify(settlementDraftRepository, never()).save(any());
  }

  @Test
  void finalizeSettlementUsesDraftSectionsAndCalculatesMinimumTransfers() {
    PlanEntity pastPlan = new PlanEntity(
      "101",
      group,
      "지난 약속",
      Instant.parse("2026-06-01T01:00:00Z"),
      Instant.parse("2026-06-01T03:00:00Z"),
      "completed",
      null,
      "수원"
    );
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(planRepository.findByGroupAndPublicId(group, "101")).thenReturn(Optional.of(pastPlan));
    when(planParticipantRepository.findByPlanAndUser(pastPlan, me))
      .thenReturn(Optional.of(new PlanParticipantEntity(pastPlan, me, "joined", "accepted")));
    when(planParticipantRepository.findByPlanOrderByCreatedAtAsc(pastPlan)).thenReturn(List.of(
      new PlanParticipantEntity(pastPlan, me, "joined", "accepted"),
      new PlanParticipantEntity(pastPlan, jimin, "joined", "accepted"),
      new PlanParticipantEntity(pastPlan, minsu, "joined", "accepted")
    ));
    when(settlementDraftRepository.findActiveByPlan(pastPlan)).thenReturn(Optional.empty());
    when(settlementDraftRepository.findPublicIds()).thenReturn(List.of());
    when(settlementDraftRepository.save(any())).thenAnswer(invocation -> invocation.getArgument(0));
    when(settlementSectionRepository.save(any())).thenAnswer(invocation -> invocation.getArgument(0));
    when(settlementItemRepository.save(any(SettlementItemEntity.class))).thenAnswer(invocation -> invocation.getArgument(0));
    when(settlementItemTargetRepository.save(any(SettlementItemTargetEntity.class)))
      .thenAnswer(invocation -> invocation.getArgument(0));

    service.createSettlementDraft("1", "101", me.getId());
    com.onmu.api.domain.SettlementDraftEntity draft =
      new com.onmu.api.domain.SettlementDraftEntity("301", group, pastPlan, "{}");
    when(settlementDraftRepository.findActiveByPlanForUpdate(pastPlan))
      .thenReturn(Optional.of(draft));
    when(settlementDraftRepository.findByPlanForUpdate(pastPlan))
      .thenReturn(Optional.of(draft));
    when(settlementItemRepository.findBySettlementDraft(any())).thenReturn(List.of());
    when(settlementRepository.findPublicIds()).thenReturn(List.of());
    when(settlementRepository.save(any(SettlementEntity.class))).thenAnswer(invocation -> invocation.getArgument(0));
    when(settlementTransferRepository.save(any(SettlementTransferEntity.class)))
      .thenAnswer(invocation -> invocation.getArgument(0));
    when(chatActivityEventRepository.save(any(ChatActivityEventEntity.class)))
      .thenAnswer(invocation -> invocation.getArgument(0));
    when(notificationRepository.save(any(NotificationEntity.class))).thenAnswer(invocation -> invocation.getArgument(0));

    service.updateSettlementDraft("1", "101", me.getId(), new UpdateSettlementDraftRequest(List.of(
      new SettlementDraftSectionRequest(
        "section-a",
        null,
        "A장소",
        userId(jimin),
        List.of(new SettlementDraftItemRequest(
          "401",
          "커피",
          10000,
          "equal",
          List.of(userId(me), userId(jimin), userId(minsu))
        ))
      ),
      new SettlementDraftSectionRequest(
        "section-b",
        null,
        "B장소",
        userId(me),
        List.of(new SettlementDraftItemRequest(
          "402",
          "저녁",
          30000,
          "equal",
          List.of(userId(me), userId(jimin), userId(minsu))
        ))
      ),
      new SettlementDraftSectionRequest(
        "section-c",
        null,
        "C장소",
        userId(minsu),
        List.of(new SettlementDraftItemRequest(
          "403",
          "디저트",
          20000,
          "equal",
          List.of(userId(me), userId(jimin), userId(minsu))
        ))
      )
    ), null));

    MapLike created = new MapLike(service.finalizeSettlement("1", "101", me.getId()));

    assertThat(created.value("status")).isEqualTo("finalized");
    assertThat(created.value("totalAmountLabel")).isEqualTo("60,000원");
    assertThat(created.firstTransfer().get("fromName")).isEqualTo("지민");
    assertThat(created.firstTransfer().get("toName")).isEqualTo("나");
    assertThat(created.firstTransfer().get("amountLabel")).isEqualTo("10,000원");
    verify(settlementTransferRepository, times(2)).save(any(SettlementTransferEntity.class));
    verify(outboxService).record(eq("settlement.finalized"), eq("settlement"), any(), any());
  }

  @Test
  void receivedConfirmationCompletesSettlementWhenAllReceiversConfirmed() {
    SettlementEntity settlement = new SettlementEntity("302", group, plan, "{}");
    SettlementTransferEntity transfer = new SettlementTransferEntity(settlement, minsu, jimin, 6000, "민수 -> 지민");
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(planRepository.findByGroupAndPublicId(group, "101")).thenReturn(Optional.of(plan));
    when(planParticipantRepository.findByPlanAndUser(plan, jimin))
      .thenReturn(Optional.of(new PlanParticipantEntity(plan, jimin, "joined", "accepted")));
    when(userRepository.findByIdAndDeletedAtIsNull(jimin.getId())).thenReturn(Optional.of(jimin));
    when(groupRepository.isUserMember("1", jimin.getId())).thenReturn(true);
    when(settlementRepository.findByPlanAndPublicIdForUpdate(plan, "302")).thenReturn(Optional.of(settlement));
    when(settlementTransferRepository.findBySettlementAndPublicId(settlement, transfer.getPublicId()))
      .thenReturn(Optional.of(transfer));
    when(settlementConfirmationRepository.findBySettlementTransferAndUserAndConfirmationType(transfer, jimin, "received"))
      .thenReturn(Optional.empty());
    when(settlementConfirmationRepository.save(any(SettlementConfirmationEntity.class)))
      .thenAnswer(invocation -> invocation.getArgument(0));
    when(settlementTransferRepository.findBySettlementOrderByCreatedAtAsc(settlement)).thenReturn(List.of(transfer));
    when(settlementConfirmationRepository.existsBySettlementTransferAndConfirmationType(transfer, "received"))
      .thenReturn(true);

    MapLike result = new MapLike(service.markTransferReceived("1", "101", "302", transfer.getPublicId(), jimin.getId()));

    assertThat(result.value("status")).isEqualTo("completed");
    verify(chatActivityEventRepository).save(argThat(event -> "settlement.completed".equals(event.getEventType())
      && event.getPlan() == plan));
    verify(outboxService).record(eq("settlement.completed"), eq("settlement"), any(), any());
  }

  @Test
  void receivedConfirmationDoesNotMarkSenderParticipantAsReceived() {
    SettlementEntity settlement = new SettlementEntity("302", group, plan, "{}");
    SettlementSectionEntity section = new SettlementSectionEntity(
      null,
      settlement,
      "section-a",
      null,
      "기타 비용",
      jimin,
      0
    );
    SettlementItemEntity item = new SettlementItemEntity(
      null,
      settlement,
      section,
      "403",
      "커피",
      12000,
      "menu",
      "사용자 메모"
    );
    SettlementItemTargetEntity jiminTarget = new SettlementItemTargetEntity(item, jimin, 6000);
    SettlementItemTargetEntity minsuTarget = new SettlementItemTargetEntity(item, minsu, 6000);
    SettlementTransferEntity transfer = new SettlementTransferEntity(settlement, minsu, jimin, 6000, "민수 -> 지민");
    transfer.markReceived();

    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(planRepository.findByGroupAndPublicId(group, "101")).thenReturn(Optional.of(plan));
    when(settlementRepository.findByPlanAndPublicId(plan, "302")).thenReturn(Optional.of(settlement));
    when(settlementSectionRepository.findBySettlementOrderBySortOrderAsc(settlement)).thenReturn(List.of(section));
    when(settlementItemRepository.findBySectionOrderByCreatedAtAsc(section)).thenReturn(List.of(item));
    when(settlementItemTargetRepository.findBySettlementItemInOrderByCreatedAtAsc(List.of(item)))
      .thenReturn(List.of(jiminTarget, minsuTarget));
    when(settlementTransferRepository.findBySettlementOrderByCreatedAtAsc(settlement)).thenReturn(List.of(transfer));

    MapLike result = new MapLike(service.settlementById("1", "101", "302", me.getId()));

    assertThat(result.participantStatus("민수").get("sent")).isEqualTo(false);
    assertThat(result.participantStatus("민수").get("completed")).isEqualTo(false);
    assertThat(result.participantStatus("지민").get("received")).isEqualTo(true);
    assertThat(result.participantStatus("지민").get("completed")).isEqualTo(true);
  }

  @Test
  void currentSettlementDoesNotReturnCompletedSettlementAsActive() {
    SettlementEntity completedSettlement = new SettlementEntity("302", group, plan, "{}");
    completedSettlement.markCompleted();
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(planRepository.findByGroupAndPublicId(group, "101")).thenReturn(Optional.of(plan));
    when(settlementDraftRepository.findActiveByPlan(plan)).thenReturn(Optional.empty());
    when(settlementRepository.findFirstByPlanAndStatusInOrderByCreatedAtDesc(eq(plan), any()))
      .thenAnswer(invocation -> {
        @SuppressWarnings("unchecked")
        List<String> statuses = invocation.getArgument(1, List.class);
        return statuses.contains("completed") ? Optional.of(completedSettlement) : Optional.empty();
      });

    org.assertj.core.api.Assertions.assertThatThrownBy(() -> service.currentSettlement("1", "101", me.getId()))
      .isInstanceOfSatisfying(ResponseStatusException.class, exception -> {
        assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND);
        assertThat(exception.getReason()).isEqualTo("settlement_not_found");
      });
  }

  @Test
  void finalizeSettlementReturnsExistingCompletedSettlementInsteadOfCreatingAnotherResult() {
    SettlementEntity completed = new SettlementEntity("302", group, plan, "{}");
    completed.markCompleted();
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(planRepository.findByGroupAndPublicId(group, "101")).thenReturn(Optional.of(plan));
    when(settlementRepository.findFirstByPlanAndStatusInOrderByCreatedAtDesc(
      plan,
      List.of("finalized", "completed")
    )).thenReturn(Optional.of(completed));
    when(settlementSectionRepository.findBySettlementOrderBySortOrderAsc(completed)).thenReturn(List.of());
    when(settlementItemRepository.findBySettlementOrderByCreatedAtAsc(completed)).thenReturn(List.of());
    when(settlementTransferRepository.findBySettlementOrderByCreatedAtAsc(completed)).thenReturn(List.of());

    MapLike result = new MapLike(service.finalizeSettlement("1", "101", me.getId()));

    assertThat(result.value("id")).isEqualTo("302");
    assertThat(result.value("status")).isEqualTo("completed");
    verify(settlementRepository, never()).save(any(SettlementEntity.class));
  }

  @Test
  void finalizeSettlementRechecksFinalResultAfterDraftLock() {
    SettlementEntity completed = new SettlementEntity("302", group, plan, "{}");
    completed.markCompleted();
    com.onmu.api.domain.SettlementDraftEntity draft =
      new com.onmu.api.domain.SettlementDraftEntity("301", group, plan, "{}");
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(planRepository.findByGroupAndPublicId(group, "101")).thenReturn(Optional.of(plan));
    when(settlementRepository.findFirstByPlanAndStatusInOrderByCreatedAtDesc(
      plan,
      List.of("finalized", "completed")
    )).thenReturn(Optional.empty(), Optional.of(completed));
    when(settlementDraftRepository.findByPlanForUpdate(plan)).thenReturn(Optional.of(draft));
    when(settlementSectionRepository.findBySettlementOrderBySortOrderAsc(completed)).thenReturn(List.of());
    when(settlementItemRepository.findBySettlementOrderByCreatedAtAsc(completed)).thenReturn(List.of());
    when(settlementTransferRepository.findBySettlementOrderByCreatedAtAsc(completed)).thenReturn(List.of());

    MapLike result = new MapLike(service.finalizeSettlement("1", "101", me.getId()));

    assertThat(result.value("id")).isEqualTo("302");
    assertThat(result.value("status")).isEqualTo("completed");
    verify(settlementRepository, never()).save(any(SettlementEntity.class));
  }

  @Test
  void updateSettlementDraftFlushesDeletedSectionsBeforeReusingPublicIds() {
    com.onmu.api.domain.SettlementDraftEntity draft =
      new com.onmu.api.domain.SettlementDraftEntity("301", group, plan, "{}");
    SettlementSectionEntity previousSection = new SettlementSectionEntity(
      draft,
      null,
      "section-a",
      null,
      "기타 비용",
      jimin,
      0
    );
    SettlementItemEntity previousItem = new SettlementItemEntity(
      draft,
      null,
      previousSection,
      "401",
      "커피",
      12000,
      "menu",
      null
    );

    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(planRepository.findByGroupAndPublicId(group, "101")).thenReturn(Optional.of(plan));
    when(settlementDraftRepository.findActiveByPlanForUpdate(plan)).thenReturn(Optional.of(draft));
    when(settlementSectionRepository.findBySettlementDraftOrderBySortOrderAsc(draft))
      .thenReturn(List.of(previousSection))
      .thenReturn(List.of());
    when(settlementItemRepository.findBySectionOrderByCreatedAtAsc(previousSection)).thenReturn(List.of(previousItem));
    when(settlementItemRepository.findBySettlementDraft(draft)).thenReturn(List.of());
    when(settlementDraftRepository.save(draft)).thenReturn(draft);
    when(settlementSectionRepository.save(any(SettlementSectionEntity.class)))
      .thenAnswer(invocation -> invocation.getArgument(0));
    when(settlementItemRepository.save(any(SettlementItemEntity.class))).thenAnswer(invocation -> invocation.getArgument(0));
    when(settlementItemTargetRepository.save(any(SettlementItemTargetEntity.class)))
      .thenAnswer(invocation -> invocation.getArgument(0));

    service.updateSettlementDraft("1", "101", me.getId(), new UpdateSettlementDraftRequest(List.of(
      new SettlementDraftSectionRequest(
        "section-a",
        null,
        "기타 비용",
        userId(me),
        List.of(new SettlementDraftItemRequest(
          "402",
          "음료",
          9000,
          "menu",
          List.of(userId(me), userId(jimin))
        ))
      )
    ), null));

    InOrder inOrder = inOrder(settlementItemTargetRepository, settlementItemRepository, settlementSectionRepository);
    inOrder.verify(settlementItemTargetRepository).deleteBySettlementItemIn(List.of(previousItem));
    inOrder.verify(settlementItemRepository).deleteBySectionIn(List.of(previousSection));
    inOrder.verify(settlementSectionRepository).deleteBySettlementDraft(draft);
    inOrder.verify(settlementSectionRepository).flush();
    inOrder.verify(settlementSectionRepository).save(argThat(section -> "section-a".equals(section.getPublicId())));
  }

  @Test
  void updateSettlementDraftPersistsCustomTargetSharesWhenAmountsMatch() {
    com.onmu.api.domain.SettlementDraftEntity draft =
      new com.onmu.api.domain.SettlementDraftEntity("301", group, plan, "{}");
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(planRepository.findByGroupAndPublicId(group, "101")).thenReturn(Optional.of(plan));
    when(settlementDraftRepository.findActiveByPlanForUpdate(plan)).thenReturn(Optional.of(draft));
    when(settlementSectionRepository.findBySettlementDraftOrderBySortOrderAsc(draft)).thenReturn(List.of());
    when(settlementItemRepository.findBySettlementDraft(draft)).thenReturn(List.of());
    when(settlementDraftRepository.save(draft)).thenReturn(draft);
    when(settlementSectionRepository.save(any(SettlementSectionEntity.class)))
      .thenAnswer(invocation -> invocation.getArgument(0));
    when(settlementItemRepository.save(any(SettlementItemEntity.class))).thenAnswer(invocation -> invocation.getArgument(0));
    when(settlementItemTargetRepository.save(any(SettlementItemTargetEntity.class)))
      .thenAnswer(invocation -> invocation.getArgument(0));

    service.updateSettlementDraft("1", "101", me.getId(), new UpdateSettlementDraftRequest(List.of(
      new SettlementDraftSectionRequest(
        "section-a",
        null,
        "기타 비용",
        userId(me),
        List.of(new SettlementDraftItemRequest(
          "401",
          "커피",
          12000,
          "menu",
          List.of(),
          List.of(
            new SettlementTargetShareRequest(userId(me), 8000L),
            new SettlementTargetShareRequest(userId(jimin), 4000L)
          )
        ))
      )
    ), null));

    verify(settlementItemTargetRepository).save(argThat(target ->
      target.getUser() == me && target.getAmountWon() == 8000L));
    verify(settlementItemTargetRepository).save(argThat(target ->
      target.getUser() == jimin && target.getAmountWon() == 4000L));
  }

  @Test
  void updateSettlementDraftRejectsCustomTargetSharesWhenTotalDoesNotMatchItemAmount() {
    com.onmu.api.domain.SettlementDraftEntity draft =
      new com.onmu.api.domain.SettlementDraftEntity("301", group, plan, "{}");
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(planRepository.findByGroupAndPublicId(group, "101")).thenReturn(Optional.of(plan));
    when(settlementDraftRepository.findActiveByPlanForUpdate(plan)).thenReturn(Optional.of(draft));

    org.assertj.core.api.Assertions.assertThatThrownBy(() ->
        service.updateSettlementDraft("1", "101", me.getId(), new UpdateSettlementDraftRequest(List.of(
          new SettlementDraftSectionRequest(
            "section-a",
            null,
            "기타 비용",
            userId(me),
            List.of(new SettlementDraftItemRequest(
              "401",
              "커피",
              12000,
              "menu",
              List.of(),
              List.of(
                new SettlementTargetShareRequest(userId(me), 8000L),
                new SettlementTargetShareRequest(userId(jimin), 3000L)
              )
            ))
          )
        ), null)))
      .isInstanceOfSatisfying(ResponseStatusException.class, exception -> {
        assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(exception.getReason()).isEqualTo("settlement_target_amount_mismatch");
      });
  }

  @Test
  void updateSettlementDraftItemTargetsPersistsCustomTargetShares() {
    com.onmu.api.domain.SettlementDraftEntity draft =
      new com.onmu.api.domain.SettlementDraftEntity("301", group, plan, "{}");
    SettlementItemEntity item = new SettlementItemEntity(
      draft,
      null,
      null,
      "401",
      "커피",
      12000,
      "menu",
      null
    );
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(planRepository.findByGroupAndPublicId(group, "101")).thenReturn(Optional.of(plan));
    when(settlementDraftRepository.findActiveByPlanForUpdate(plan)).thenReturn(Optional.of(draft));
    when(settlementItemRepository.findBySettlementDraftAndPublicId(draft, "401")).thenReturn(Optional.of(item));
    when(settlementItemTargetRepository.save(any(SettlementItemTargetEntity.class)))
      .thenAnswer(invocation -> invocation.getArgument(0));

    service.updateSettlementDraftItemTargets("1", "101", "401", me.getId(), new UpdateSettlementItemTargetsRequest(
      List.of(),
      List.of(
        new SettlementTargetShareRequest(userId(me), 8000L),
        new SettlementTargetShareRequest(userId(jimin), 4000L)
      )
    ));

    verify(settlementItemTargetRepository).deleteBySettlementItem(item);
    verify(settlementItemTargetRepository).save(argThat(target ->
      target.getUser() == me && target.getAmountWon() == 8000L));
    verify(settlementItemTargetRepository).save(argThat(target ->
      target.getUser() == jimin && target.getAmountWon() == 4000L));
  }

  @Test
  void previewSettlementCalculatesTransfersWithoutWritingTables() {
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(planRepository.findByGroupAndPublicId(group, "101")).thenReturn(Optional.of(plan));
    when(settlementDraftRepository.findActiveByPlan(plan))
      .thenReturn(Optional.of(new com.onmu.api.domain.SettlementDraftEntity("301", group, plan, requestPayload())));

    MapLike preview = new MapLike(service.previewSettlement("1", "101", me.getId(), request()));

    assertThat(preview.value("preview")).isEqualTo(true);
    assertThat(preview.value("totalAmountLabel")).isEqualTo("12,000원");
    assertThat(preview.firstTransfer().get("fromName")).isEqualTo("민수");
    assertThat(preview.firstTransfer().get("toName")).isEqualTo("지민");
    assertThat(preview.firstTransfer().get("amountLabel")).isEqualTo("6,000원");
    verify(settlementRepository, never()).save(any());
    verify(settlementItemRepository, never()).save(any());
    verify(settlementItemTargetRepository, never()).save(any());
    verify(settlementTransferRepository, never()).save(any());
    verifyNoInteractions(outboxService);
  }

  @Test
  void previewSettlementRejectsNonGroupMember() {
    when(userRepository.findByIdAndDeletedAtIsNull(me.getId())).thenReturn(Optional.of(me));
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(groupRepository.isUserMember("1", me.getId())).thenReturn(false);

    org.assertj.core.api.Assertions.assertThatThrownBy(() ->
        service.previewSettlement("1", "101", me.getId(), request()))
      .isInstanceOfSatisfying(ResponseStatusException.class, exception -> {
        assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN);
        assertThat(exception.getReason()).isEqualTo("not_group_member");
      });
  }

  @Test
  void createSettlementPersistsItemsTargetsTransfersAndOutboxEvents() {
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(planRepository.findByGroupAndPublicId(group, "101")).thenReturn(Optional.of(plan));
    when(settlementDraftRepository.findByPlanForUpdate(plan))
      .thenReturn(Optional.of(new com.onmu.api.domain.SettlementDraftEntity("301", group, plan, requestPayload())));
    when(settlementRepository.findPublicIds()).thenReturn(List.of("301"));
    when(settlementRepository.save(any(SettlementEntity.class))).thenAnswer(invocation -> invocation.getArgument(0));
    when(settlementItemRepository.save(any(SettlementItemEntity.class))).thenAnswer(invocation -> invocation.getArgument(0));
    when(settlementItemTargetRepository.save(any(SettlementItemTargetEntity.class)))
      .thenAnswer(invocation -> invocation.getArgument(0));
    when(settlementTransferRepository.save(any(SettlementTransferEntity.class)))
      .thenAnswer(invocation -> invocation.getArgument(0));
    when(chatActivityEventRepository.save(any(ChatActivityEventEntity.class)))
      .thenAnswer(invocation -> invocation.getArgument(0));
    when(notificationRepository.save(any(NotificationEntity.class))).thenAnswer(invocation -> invocation.getArgument(0));

    MapLike created = new MapLike(service.createSettlement("1", "101", me.getId(), request()));

    assertThat(created.value("id")).isEqualTo("302");
    assertThat(created.value("preview")).isEqualTo(false);
    assertThat(created.value("status")).isEqualTo("finalized");
    assertThat(created.firstTransfer().get("amountLabel")).isEqualTo("6,000원");
    verify(settlementItemRepository).save(any(SettlementItemEntity.class));
    verify(settlementItemTargetRepository, times(2)).save(any(SettlementItemTargetEntity.class));
    verify(settlementTransferRepository).save(any(SettlementTransferEntity.class));
    verify(chatActivityEventRepository).save(argThat(event -> "settlement.finalized".equals(event.getEventType())
      && event.getPlan() == plan));
    verify(notificationRepository, times(2)).save(argThat(notification ->
      "settlement_requested".equals(notification.getNotificationType())
        && notification.getPlan() == plan
        && "queued".equals(notification.getStatus())));
    verify(outboxService).record(eq("settlement.finalized"), eq("settlement"), any(),
      argThat(payload -> "302".equals(payload.get("settlementId"))));
    verify(outboxService, times(2)).record(eq("notification.requested"), eq("notification"), any(),
      argThat(payload -> "302".equals(payload.get("settlementId"))
        && payload.containsKey("notificationId")
        && "settlement_requested".equals(payload.get("notificationType"))));
  }

  @Test
  void createSettlementSkipsInboxNotificationWhenSettlementPreferenceIsDisabled() {
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(planRepository.findByGroupAndPublicId(group, "101")).thenReturn(Optional.of(plan));
    when(settlementDraftRepository.findByPlanForUpdate(plan))
      .thenReturn(Optional.of(new com.onmu.api.domain.SettlementDraftEntity("301", group, plan, requestPayload())));
    when(settlementRepository.findPublicIds()).thenReturn(List.of("301"));
    when(settlementRepository.save(any(SettlementEntity.class))).thenAnswer(invocation -> invocation.getArgument(0));
    when(settlementItemRepository.save(any(SettlementItemEntity.class))).thenAnswer(invocation -> invocation.getArgument(0));
    when(settlementItemTargetRepository.save(any(SettlementItemTargetEntity.class)))
      .thenAnswer(invocation -> invocation.getArgument(0));
    when(settlementTransferRepository.save(any(SettlementTransferEntity.class)))
      .thenAnswer(invocation -> invocation.getArgument(0));
    when(chatActivityEventRepository.save(any(ChatActivityEventEntity.class)))
      .thenAnswer(invocation -> invocation.getArgument(0));
    when(notificationPreferenceService.isEnabled(any(UUID.class), eq("settlement_requested"), eq("in_app")))
      .thenReturn(false);

    MapLike created = new MapLike(service.createSettlement("1", "101", me.getId(), request()));

    assertThat(created.value("status")).isEqualTo("finalized");
    verify(notificationRepository, never()).save(any(NotificationEntity.class));
    verify(outboxService, never()).record(eq("notification.requested"), eq("notification"), any(), any());
    verify(outboxService).record(eq("settlement.finalized"), eq("settlement"), any(), any());
  }

  @Test
  void previewSettlementUsesParticipantUserIds() {
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(planRepository.findByGroupAndPublicId(group, "101")).thenReturn(Optional.of(plan));
    when(settlementDraftRepository.findActiveByPlan(plan))
      .thenReturn(Optional.of(new com.onmu.api.domain.SettlementDraftEntity("301", group, plan, requestPayload())));

    MapLike preview = new MapLike(service.previewSettlement("1", "101", me.getId(), request()));

    assertThat(preview.firstTransfer().get("fromName")).isEqualTo("민수");
    assertThat(preview.firstTransfer().get("toName")).isEqualTo("지민");
    verify(userRepository, never()).findByNicknameIn(any());
  }

  @Test
  void unknownParticipantUserIdReturnsValidationErrorWithoutNicknameFallback() {
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(planRepository.findByGroupAndPublicId(group, "101")).thenReturn(Optional.of(plan));
    when(settlementDraftRepository.findActiveByPlan(plan))
      .thenReturn(Optional.of(new com.onmu.api.domain.SettlementDraftEntity("301", group, plan, unknownTargetPayload())));

    org.assertj.core.api.Assertions.assertThatThrownBy(() -> service.previewSettlement("1", "101", me.getId(), request()))
      .isInstanceOfSatisfying(ResponseStatusException.class, exception -> {
        assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(exception.getReason()).isEqualTo("settlement_participant_not_found");
      });
    verify(userRepository, never()).findByNicknameIn(any());
  }

  @Test
  void settlementByIdReadsItemsTargetsAndTransfers() {
    minsu.updateProfile(
      null,
      null,
      null,
      "{\"gender\":\"male\",\"skinTone\":\"skin_2\",\"hairStyle\":\"hair_style_2\",\"hairColor\":\"hair_color_1\",\"eyeStyle\":\"eye_style_1\",\"eyeColor\":\"eye_color_1\",\"clothes\":\"top_1\"}",
      null
    );
    jimin.updateProfile(
      null,
      null,
      null,
      "{\"gender\":\"female\",\"skinTone\":\"skin_1\",\"hairStyle\":\"hair_style_3\",\"hairColor\":\"hair_color_2\",\"eyeStyle\":\"eye_style_1\",\"eyeColor\":\"eye_color_1\",\"clothes\":\"top_0\"}",
      null
    );
    SettlementEntity settlement = new SettlementEntity(
      "302",
      group,
      plan,
      "{}"
    );
    SettlementSectionEntity section = new SettlementSectionEntity(
      null,
      settlement,
      "section-a",
      null,
      "카페",
      jimin,
      0
    );
    SettlementItemEntity item = new SettlementItemEntity(
      null,
      settlement,
      section,
      "403",
      "커피",
      12000,
      "equal",
      "사용자 메모"
    );
    SettlementItemTargetEntity jiminTarget = new SettlementItemTargetEntity(item, jimin, 6000);
    SettlementItemTargetEntity minsuTarget = new SettlementItemTargetEntity(item, minsu, 6000);
    SettlementTransferEntity transfer = new SettlementTransferEntity(settlement, minsu, jimin, 6000, "민수 -> 지민");

    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(planRepository.findByGroupAndPublicId(group, "101")).thenReturn(Optional.of(plan));
    when(settlementRepository.findByPlanAndPublicId(plan, "302")).thenReturn(Optional.of(settlement));
    when(settlementSectionRepository.findBySettlementOrderBySortOrderAsc(settlement)).thenReturn(List.of(section));
    when(settlementItemRepository.findBySectionOrderByCreatedAtAsc(section)).thenReturn(List.of(item));
    when(settlementItemTargetRepository.findBySettlementItemInOrderByCreatedAtAsc(List.of(item)))
      .thenReturn(List.of(jiminTarget, minsuTarget));
    when(settlementTransferRepository.findBySettlementOrderByCreatedAtAsc(settlement)).thenReturn(List.of(transfer));

    MapLike result = new MapLike(service.settlementById("1", "101", "302", me.getId()));

    assertThat(result.value("id")).isEqualTo("302");
    assertThat(result.firstPaymentItem().get("id")).isEqualTo("403");
    assertThat(result.firstPayerShare().get("userId")).isEqualTo(userId(jimin));
    assertThat(result.firstPayerShare().get("pixelCharacter"))
      .asInstanceOf(org.assertj.core.api.InstanceOfAssertFactories.MAP)
      .containsEntry("hairStyle", "hair_style_3");
    assertThat(result.participantStatus("민수").get("pixelCharacter"))
      .asInstanceOf(org.assertj.core.api.InstanceOfAssertFactories.MAP)
      .containsEntry("hairStyle", "hair_style_2");
    assertThat(result.firstTransfer().get("fromName")).isEqualTo("민수");
    assertThat(result.firstTransfer().get("fromPixelCharacter"))
      .asInstanceOf(org.assertj.core.api.InstanceOfAssertFactories.MAP)
      .containsEntry("hairStyle", "hair_style_2");
  }

  @Test
  void settlementByIdUsesSectionPayerForPaidTotalsAndTransfers() {
    SettlementEntity settlement = new SettlementEntity(
      "303",
      group,
      plan,
      "{}"
    );
    SettlementSectionEntity section = new SettlementSectionEntity(
      null,
      settlement,
      "section-a",
      null,
      "카페",
      jimin,
      0
    );
    SettlementItemEntity item = new SettlementItemEntity(
      null,
      settlement,
      section,
      "404",
      "카페",
      60000,
      "menu",
      "사용자 메모"
    );
    SettlementItemTargetEntity jiminTarget = new SettlementItemTargetEntity(item, jimin, 20000);
    SettlementItemTargetEntity minsuTarget = new SettlementItemTargetEntity(item, minsu, 20000);
    SettlementItemTargetEntity meTarget = new SettlementItemTargetEntity(item, me, 20000);

    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(planRepository.findByGroupAndPublicId(group, "101")).thenReturn(Optional.of(plan));
    when(settlementRepository.findByPlanAndPublicId(plan, "303")).thenReturn(Optional.of(settlement));
    when(settlementSectionRepository.findBySettlementOrderBySortOrderAsc(settlement)).thenReturn(List.of(section));
    when(settlementItemRepository.findBySectionOrderByCreatedAtAsc(section)).thenReturn(List.of(item));
    when(settlementItemTargetRepository.findBySettlementItemInOrderByCreatedAtAsc(List.of(item)))
      .thenReturn(List.of(jiminTarget, minsuTarget, meTarget));
    when(settlementTransferRepository.findBySettlementOrderByCreatedAtAsc(settlement)).thenReturn(List.of());

    MapLike result = new MapLike(service.settlementById("1", "101", "303", me.getId()));

    assertThat(result.payerShares()).hasSize(1);
    assertThat(result.payerShares().get(0).get("name")).isEqualTo("지민");
    assertThat(result.payerShares().get(0).get("amountLabel")).isEqualTo("60,000원");
    assertThat(result.firstTransfer().get("fromName")).isEqualTo("나");
    assertThat(result.firstTransfer().get("toName")).isEqualTo("지민");
    assertThat(result.firstTransfer().get("amountLabel")).isEqualTo("20,000원");
    assertThat(result.value("mySummaryLabel")).isEqualTo("나는 20,000원 송금");
    assertThat(result.memberResult("지민").get("paidAmountLabel")).isEqualTo("60,000원");
    assertThat(result.memberResult("민수").get("resultLabel")).isEqualTo("20,000원 송금");
  }

  private SettlementPreviewRequest request() {
    return new SettlementPreviewRequest(List.of(new SettlementDraftSectionRequest(
      "section-a",
      null,
      "기타 비용",
      userId(jimin),
      List.of(new SettlementDraftItemRequest(
        "401",
        "커피",
        12000,
        "menu",
        List.of(userId(jimin), userId(minsu))
      ))
    )));
  }

  private String requestPayload() {
    return """
      {"sections":[{"id":"section-a","title":"기타 비용","payerUserId":"%s","items":[{"id":"401","title":"커피","amountWon":12000,"splitType":"menu","targetUserIds":["%s","%s"]}]}]}
      """.formatted(userId(jimin), userId(jimin), userId(minsu));
  }

  private String unknownTargetPayload() {
    return """
      {"sections":[{"id":"section-a","title":"기타 비용","payerUserId":"%s","items":[{"id":"401","title":"커피","amountWon":12000,"splitType":"menu","targetUserIds":["%s","unknown-user"]}]}]}
      """.formatted(userId(jimin), userId(jimin));
  }

  private String userId(UserEntity user) {
    return user.getId().toString();
  }

  private UserEntity user(String publicId, String nickname) {
    try {
      var constructor = UserEntity.class.getDeclaredConstructor();
      constructor.setAccessible(true);
      UserEntity user = constructor.newInstance();
      ReflectionTestUtils.setField(user, "id", UUID.randomUUID());
      ReflectionTestUtils.setField(user, "publicId", publicId);
      ReflectionTestUtils.setField(user, "nickname", nickname);
      return user;
    } catch (ReflectiveOperationException exception) {
      throw new IllegalStateException("Could not create test user fixture", exception);
    }
  }

  private record MapLike(java.util.Map<String, Object> value) {
    Object value(String key) {
      return value.get(key);
    }

    @SuppressWarnings("unchecked")
    java.util.Map<String, Object> firstPaymentItem() {
      return ((List<java.util.Map<String, Object>>) value.get("paymentItems")).get(0);
    }

    @SuppressWarnings("unchecked")
    java.util.Map<String, Object> firstPayerShare() {
      return ((List<java.util.Map<String, Object>>) firstPaymentItem().get("payerShares")).get(0);
    }

    @SuppressWarnings("unchecked")
    List<java.util.Map<String, Object>> payerShares() {
      return (List<java.util.Map<String, Object>>) firstPaymentItem().get("payerShares");
    }

    @SuppressWarnings("unchecked")
    java.util.Map<String, Object> memberResult(String name) {
      return ((List<java.util.Map<String, Object>>) value.get("memberResults")).stream()
        .filter(result -> name.equals(result.get("name")))
        .findFirst()
        .orElseThrow();
    }

    @SuppressWarnings("unchecked")
    java.util.Map<String, Object> participantStatus(String name) {
      return ((List<java.util.Map<String, Object>>) value.get("participantStatuses")).stream()
        .filter(result -> name.equals(result.get("name")))
        .findFirst()
        .orElseThrow();
    }

    @SuppressWarnings("unchecked")
    java.util.Map<String, Object> firstTransfer() {
      return ((List<java.util.Map<String, Object>>) value.get("transfers")).get(0);
    }
  }
}
