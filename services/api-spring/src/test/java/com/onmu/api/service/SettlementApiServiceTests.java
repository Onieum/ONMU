package com.onmu.api.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.argThat;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.onmu.api.domain.ChatActivityEventEntity;
import com.onmu.api.domain.ChatActivityEventRepository;
import com.onmu.api.domain.GroupEntity;
import com.onmu.api.domain.GroupMemberRepository;
import com.onmu.api.domain.GroupRepository;
import com.onmu.api.domain.NotificationEntity;
import com.onmu.api.domain.NotificationRepository;
import com.onmu.api.domain.PlanEntity;
import com.onmu.api.domain.PlanRepository;
import com.onmu.api.domain.SettlementDraftRepository;
import com.onmu.api.domain.SettlementEntity;
import com.onmu.api.domain.SettlementItemEntity;
import com.onmu.api.domain.SettlementItemRepository;
import com.onmu.api.domain.SettlementItemTargetEntity;
import com.onmu.api.domain.SettlementItemTargetRepository;
import com.onmu.api.domain.SettlementRepository;
import com.onmu.api.domain.SettlementTransferEntity;
import com.onmu.api.domain.SettlementTransferRepository;
import com.onmu.api.domain.UserEntity;
import com.onmu.api.domain.UserRepository;
import com.onmu.api.web.dto.SettlementDraftItemRequest;
import com.onmu.api.web.dto.SettlementPreviewRequest;
import java.time.Instant;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
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
  private UserRepository userRepository;
  @Mock
  private SettlementDraftRepository settlementDraftRepository;
  @Mock
  private SettlementRepository settlementRepository;
  @Mock
  private SettlementItemRepository settlementItemRepository;
  @Mock
  private SettlementItemTargetRepository settlementItemTargetRepository;
  @Mock
  private SettlementTransferRepository settlementTransferRepository;
  @Mock
  private ChatActivityEventRepository chatActivityEventRepository;
  @Mock
  private GroupMemberRepository groupMemberRepository;
  @Mock
  private NotificationRepository notificationRepository;
  @Mock
  private OutboxService outboxService;

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
      userRepository,
      settlementDraftRepository,
      settlementRepository,
      settlementItemRepository,
      settlementItemTargetRepository,
      settlementTransferRepository,
      chatActivityEventRepository,
      groupMemberRepository,
      notificationRepository,
      outboxService,
      new ObjectMapper()
    );
    group = new GroupEntity("1", "ONMU 개발 모임", null);
    plan = new PlanEntity("101", group, "ONMU API 계약 검증", Instant.parse("2026-06-12T01:00:00Z"), "scheduled");
    me = user("user-me", "나");
    jimin = user("user-jimin", "지민");
    minsu = user("user-minsu", "민수");

    lenient().when(userRepository.findByIdAndDeletedAtIsNull(me.getId())).thenReturn(Optional.of(me));
    lenient().when(groupRepository.isUserMember("1", me.getId())).thenReturn(true);
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
  }

  @Test
  void previewSettlementCalculatesTransfersWithoutWritingTables() {
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(planRepository.findByGroupAndPublicId(group, "101")).thenReturn(Optional.of(plan));

    MapLike preview = new MapLike(service.previewSettlement("1", "101", me.getId(), request()));

    assertThat(preview.value("preview")).isEqualTo(true);
    assertThat(preview.value("totalAmountLabel")).isEqualTo("12,000원");
    assertThat(preview.firstTransfer().get("fromName")).isEqualTo("민수");
    assertThat(preview.firstTransfer().get("toName")).isEqualTo("지민");
    assertThat(preview.firstTransfer().get("amountLabel")).isEqualTo("6,000원");
    verifyNoInteractions(settlementRepository, settlementItemRepository, settlementItemTargetRepository,
      settlementTransferRepository, outboxService);
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
    when(settlementRepository.findAll()).thenReturn(List.of(new SettlementEntity("301", group, plan, "{}")));
    when(settlementRepository.save(any(SettlementEntity.class))).thenAnswer(invocation -> invocation.getArgument(0));
    when(settlementItemRepository.findAll()).thenReturn(List.of());
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
    assertThat(created.firstTransfer().get("amountLabel")).isEqualTo("6,000원");
    verify(settlementItemRepository).save(any(SettlementItemEntity.class));
    verify(settlementItemTargetRepository, times(2)).save(any(SettlementItemTargetEntity.class));
    verify(settlementTransferRepository).save(any(SettlementTransferEntity.class));
    verify(chatActivityEventRepository).save(argThat(event -> "settlement.created".equals(event.getEventType())
      && event.getPlan() == plan));
    verify(notificationRepository, times(2)).save(argThat(notification ->
      "settlement_created".equals(notification.getNotificationType())
        && notification.getPlan() == plan
        && "queued".equals(notification.getStatus())));
    verify(outboxService).record(eq("settlement.created"), eq("settlement"), any(),
      argThat(payload -> "302".equals(payload.get("settlementId"))));
    verify(outboxService, times(2)).record(eq("notification.requested"), eq("notification"), any(),
      argThat(payload -> "302".equals(payload.get("settlementId"))
        && payload.containsKey("notificationId")
        && "settlement_created".equals(payload.get("notificationType"))));
  }

  @Test
  void userPublicIdsArePreferredOverNicknameFallback() {
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(planRepository.findByGroupAndPublicId(group, "101")).thenReturn(Optional.of(plan));

    MapLike preview = new MapLike(service.previewSettlement("1", "101", me.getId(), new SettlementPreviewRequest(List.of(
      new SettlementDraftItemRequest(
        "401",
        "커피",
        12000,
        12000,
        "user-jimin",
        "동명이인 표시 이름",
        "equal",
        List.of("user-jimin", "user-minsu"),
        List.of("동명이인 표시 이름", "민수")
      )
    ))));

    assertThat(preview.firstTransfer().get("fromName")).isEqualTo("민수");
    assertThat(preview.firstTransfer().get("toName")).isEqualTo("지민");
  }

  @Test
  void duplicateNicknameFallbackReturnsValidationError() {
    UserEntity anotherJimin = user("user-jimin-2", "지민");
    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(planRepository.findByGroupAndPublicId(group, "101")).thenReturn(Optional.of(plan));
    when(userRepository.findByNicknameIn(any())).thenReturn(List.of(jimin, anotherJimin));

    org.assertj.core.api.Assertions.assertThatThrownBy(() -> service.previewSettlement("1", "101", me.getId(), nameFallbackRequest()))
      .isInstanceOfSatisfying(ResponseStatusException.class, exception -> {
        assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(exception.getReason()).isEqualTo("ambiguous_settlement_member_name");
      });
  }

  @Test
  void settlementByIdReadsItemsTargetsAndTransfers() {
    SettlementEntity settlement = new SettlementEntity(
      "302",
      group,
      plan,
      "{\"items\":[{\"id\":\"403\",\"payerUserId\":\"user-jimin\",\"payerName\":\"지민\",\"amountWon\":12000}]}"
    );
    SettlementItemEntity item = new SettlementItemEntity(
      null,
      settlement,
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
    when(settlementItemRepository.findBySettlementOrderByCreatedAtAsc(settlement)).thenReturn(List.of(item));
    when(settlementItemTargetRepository.findBySettlementItemInOrderByCreatedAtAsc(List.of(item)))
      .thenReturn(List.of(jiminTarget, minsuTarget));
    when(settlementTransferRepository.findBySettlementOrderByCreatedAtAsc(settlement)).thenReturn(List.of(transfer));

    MapLike result = new MapLike(service.settlementById("1", "101", "302", me.getId()));

    assertThat(result.value("id")).isEqualTo("302");
    assertThat(result.firstPaymentItem().get("id")).isEqualTo("403");
    assertThat(result.firstPayerShare().get("userId")).isEqualTo("user-jimin");
    assertThat(result.firstTransfer().get("fromName")).isEqualTo("민수");
  }

  @Test
  void settlementByIdUsesPayloadPayerSharesBeforeTopLevelPayer() {
    when(userRepository.findByIdAndDeletedAtIsNull(jimin.getId())).thenReturn(Optional.of(jimin));
    when(groupRepository.isUserMember("1", jimin.getId())).thenReturn(true);
    SettlementEntity settlement = new SettlementEntity(
      "303",
      group,
      plan,
      """
      {"items":[{"id":"404","payerName":"민수","amount":60000,"payerShares":[{"name":"민수","amount":20000},{"userId":"user-jimin","payerName":"지민","amountWon":40000}]}]}
      """
    );
    SettlementItemEntity item = new SettlementItemEntity(
      null,
      settlement,
      "404",
      "카페",
      60000,
      "custom",
      "사용자 메모"
    );
    SettlementItemTargetEntity jiminTarget = new SettlementItemTargetEntity(item, jimin, 20000);
    SettlementItemTargetEntity minsuTarget = new SettlementItemTargetEntity(item, minsu, 20000);
    SettlementItemTargetEntity meTarget = new SettlementItemTargetEntity(item, me, 20000);

    when(groupRepository.findByPublicId("1")).thenReturn(Optional.of(group));
    when(planRepository.findByGroupAndPublicId(group, "101")).thenReturn(Optional.of(plan));
    when(settlementRepository.findByPlanAndPublicId(plan, "303")).thenReturn(Optional.of(settlement));
    when(settlementItemRepository.findBySettlementOrderByCreatedAtAsc(settlement)).thenReturn(List.of(item));
    when(settlementItemTargetRepository.findBySettlementItemInOrderByCreatedAtAsc(List.of(item)))
      .thenReturn(List.of(jiminTarget, minsuTarget, meTarget));
    when(settlementTransferRepository.findBySettlementOrderByCreatedAtAsc(settlement)).thenReturn(List.of());

    MapLike result = new MapLike(service.settlementById("1", "101", "303", jimin.getId()));

    assertThat(result.payerShares()).hasSize(2);
    assertThat(result.payerShares().get(0).get("name")).isEqualTo("민수");
    assertThat(result.payerShares().get(0).get("amountLabel")).isEqualTo("20,000원");
    assertThat(result.payerShares().get(1).get("name")).isEqualTo("지민");
    assertThat(result.payerShares().get(1).get("amountLabel")).isEqualTo("40,000원");
    assertThat(result.firstTransfer().get("fromName")).isEqualTo("나");
    assertThat(result.firstTransfer().get("toName")).isEqualTo("지민");
    assertThat(result.firstTransfer().get("amountLabel")).isEqualTo("20,000원");
    assertThat(result.value("mySummaryLabel")).isEqualTo("나는 20,000원 받을 예정");
    assertThat(result.memberResult("지민").get("paidAmountLabel")).isEqualTo("40,000원");
    assertThat(result.memberResult("민수").get("resultLabel")).isEqualTo("정산 완료");
  }

  private SettlementPreviewRequest request() {
    return new SettlementPreviewRequest(List.of(new SettlementDraftItemRequest(
      "401",
      "커피",
      12000,
      12000,
      "user-jimin",
      "지민",
      "equal",
      List.of("user-jimin", "user-minsu"),
      List.of("지민", "민수")
    )));
  }

  private SettlementPreviewRequest nameFallbackRequest() {
    return new SettlementPreviewRequest(List.of(new SettlementDraftItemRequest(
      "401",
      "커피",
      12000,
      12000,
      null,
      "지민",
      "equal",
      List.of(),
      List.of("지민", "민수")
    )));
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
    java.util.Map<String, Object> firstTransfer() {
      return ((List<java.util.Map<String, Object>>) value.get("transfers")).get(0);
    }
  }
}
