package com.onmu.api.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.onmu.api.domain.ChatActivityEventEntity;
import com.onmu.api.domain.ChatActivityEventRepository;
import com.onmu.api.domain.GroupEntity;
import com.onmu.api.domain.GroupMemberRepository;
import com.onmu.api.domain.GroupRepository;
import com.onmu.api.domain.NotificationEntity;
import com.onmu.api.domain.NotificationRepository;
import com.onmu.api.domain.PlanEntity;
import com.onmu.api.domain.PlanParticipantEntity;
import com.onmu.api.domain.PlanParticipantRepository;
import com.onmu.api.domain.PlanRepository;
import com.onmu.api.domain.SchedulePlaceEntity;
import com.onmu.api.domain.SchedulePlaceRepository;
import com.onmu.api.domain.SettlementConfirmationEntity;
import com.onmu.api.domain.SettlementConfirmationRepository;
import com.onmu.api.domain.SettlementDraftEntity;
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
import java.util.ArrayList;
import java.util.Collection;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
public class SettlementApiService {
  private static final String STATUS_DRAFT = "draft";
  private static final String STATUS_FINALIZED = "finalized";
  private static final String STATUS_COMPLETED = "completed";
  private static final String SETTLEMENT_NOTIFICATION_TYPE = "settlement_requested";
  private static final String EXTRA_SECTION_ID = "extra";

  private final GroupRepository groupRepository;
  private final PlanRepository planRepository;
  private final PlanParticipantRepository planParticipantRepository;
  private final SchedulePlaceRepository schedulePlaceRepository;
  private final UserRepository userRepository;
  private final SettlementDraftRepository settlementDraftRepository;
  private final SettlementRepository settlementRepository;
  private final SettlementSectionRepository settlementSectionRepository;
  private final SettlementItemRepository settlementItemRepository;
  private final SettlementItemTargetRepository settlementItemTargetRepository;
  private final SettlementTransferRepository settlementTransferRepository;
  private final SettlementConfirmationRepository settlementConfirmationRepository;
  private final ChatActivityEventRepository chatActivityEventRepository;
  @SuppressWarnings("unused")
  private final GroupMemberRepository groupMemberRepository;
  private final NotificationRepository notificationRepository;
  private final NotificationPreferenceService notificationPreferenceService;
  private final OutboxService outboxService;
  private final UserAvatarReadModelMapper userAvatarReadModelMapper;
  private final ObjectMapper objectMapper;

  public SettlementApiService(
    GroupRepository groupRepository,
    PlanRepository planRepository,
    PlanParticipantRepository planParticipantRepository,
    SchedulePlaceRepository schedulePlaceRepository,
    UserRepository userRepository,
    SettlementDraftRepository settlementDraftRepository,
    SettlementRepository settlementRepository,
    SettlementSectionRepository settlementSectionRepository,
    SettlementItemRepository settlementItemRepository,
    SettlementItemTargetRepository settlementItemTargetRepository,
    SettlementTransferRepository settlementTransferRepository,
    SettlementConfirmationRepository settlementConfirmationRepository,
    ChatActivityEventRepository chatActivityEventRepository,
    GroupMemberRepository groupMemberRepository,
    NotificationRepository notificationRepository,
    NotificationPreferenceService notificationPreferenceService,
    OutboxService outboxService,
    UserAvatarReadModelMapper userAvatarReadModelMapper,
    ObjectMapper objectMapper
  ) {
    this.groupRepository = groupRepository;
    this.planRepository = planRepository;
    this.planParticipantRepository = planParticipantRepository;
    this.schedulePlaceRepository = schedulePlaceRepository;
    this.userRepository = userRepository;
    this.settlementDraftRepository = settlementDraftRepository;
    this.settlementRepository = settlementRepository;
    this.settlementSectionRepository = settlementSectionRepository;
    this.settlementItemRepository = settlementItemRepository;
    this.settlementItemTargetRepository = settlementItemTargetRepository;
    this.settlementTransferRepository = settlementTransferRepository;
    this.settlementConfirmationRepository = settlementConfirmationRepository;
    this.chatActivityEventRepository = chatActivityEventRepository;
    this.groupMemberRepository = groupMemberRepository;
    this.notificationRepository = notificationRepository;
    this.notificationPreferenceService = notificationPreferenceService;
    this.outboxService = outboxService;
    this.userAvatarReadModelMapper = userAvatarReadModelMapper;
    this.objectMapper = objectMapper;
  }

  @Transactional
  public Map<String, Object> createSettlementDraft(String groupId, String planId, UUID userId) {
    SettlementAccess access = settlementAccess(groupId, planId, userId);
    Optional<SettlementEntity> finalSettlement = settlementRepository.findFirstByPlanAndStatusInOrderByCreatedAtDesc(
      access.plan(),
      List.of(STATUS_FINALIZED, STATUS_COMPLETED)
    );
    if (finalSettlement.isPresent()) {
      return settlementCard(finalSettlement.get(), false, access.user());
    }
    validateSettlementEligible(access.plan());
    return settlementDraftRepository.findActiveByPlan(access.plan())
      .map(draft -> settlementDraftCard(draft, true, access.user()))
      .orElseGet(() -> createInitialDraft(access));
  }

  @Transactional(readOnly = true)
  public Map<String, Object> settlementDraft(String groupId, String planId, UUID userId) {
    SettlementAccess access = settlementAccess(groupId, planId, userId);
    SettlementDraftEntity draft = settlementDraftRepository.findActiveByPlan(access.plan())
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "settlement_draft_not_found"));
    return settlementDraftCard(draft, true, access.user());
  }

  @Transactional
  public Map<String, Object> updateSettlementDraft(
    String groupId,
    String planId,
    UUID userId,
    UpdateSettlementDraftRequest request
  ) {
    SettlementAccess access = settlementAccess(groupId, planId, userId);
    SettlementDraftEntity draft = settlementDraftRepository.findActiveByPlanForUpdate(access.plan())
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "settlement_draft_not_found"));
    if (!STATUS_DRAFT.equals(draft.getStatus())) {
      throw new ResponseStatusException(HttpStatus.CONFLICT, "settlement_already_finalized");
    }

    List<SectionInput> sectionInputs = sectionInputs(
      request == null ? List.of() : request.sections(),
      access.plan(),
      activeParticipants(access.plan())
    );
    replaceDraftSections(draft, sectionInputs);
    draft.setPayload(toJson(payloadFromSections(access.plan(), sectionInputs, stringOrDefault(request == null ? null : request.memo(), ""))));
    draft.markUpdatedBy(access.user());
    SettlementDraftEntity saved = settlementDraftRepository.save(draft);
    return settlementDraftCard(saved, true, access.user());
  }

  @Transactional
  public Map<String, Object> updateSettlementDraftItemTargets(
    String groupId,
    String planId,
    String itemId,
    UUID userId,
    UpdateSettlementItemTargetsRequest request
  ) {
    SettlementAccess access = settlementAccess(groupId, planId, userId);
    SettlementDraftEntity draft = settlementDraftRepository.findActiveByPlanForUpdate(access.plan())
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "settlement_draft_not_found"));
    SettlementItemEntity item = settlementItemRepository.findBySettlementDraftAndPublicId(draft, itemId)
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "settlement_item_not_found"));
    List<UserEntity> participants = activeParticipants(access.plan());
    List<TargetShare> targetShares = targetSharesFromRequest(
      item.getAmountWon(),
      request == null ? List.of() : request.targetShares(),
      request == null ? List.of() : request.targetUserIds(),
      participants
    );
    settlementItemTargetRepository.deleteBySettlementItem(item);
    for (TargetShare target : targetShares) {
      settlementItemTargetRepository.save(new SettlementItemTargetEntity(item, target.user(), target.amountWon()));
    }
    draft.markUpdatedBy(access.user());
    draft.setPayload(toJson(payloadFromSectionViews(access.plan(), sectionViewsForDraft(draft), "")));
    return settlementDraftCard(draft, true, access.user());
  }

  @Transactional(readOnly = true)
  public Map<String, Object> previewSettlement(
    String groupId,
    String planId,
    UUID userId,
    SettlementPreviewRequest request
  ) {
    SettlementAccess access = settlementAccess(groupId, planId, userId);
    SettlementDraftEntity draft = settlementDraftRepository.findActiveByPlan(access.plan())
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "settlement_draft_not_found"));
    List<SectionView> sections = sectionViewsForDraft(draft);
    return settlementSummaryCard("preview", STATUS_DRAFT, access.plan(), sections, calculateTransfers(itemViews(sections)), true, access.user());
  }

  @Transactional
  public Map<String, Object> createSettlement(String groupId, String planId, UUID userId, SettlementPreviewRequest request) {
    return finalizeSettlement(groupId, planId, userId);
  }

  @Transactional
  public Map<String, Object> finalizeSettlement(String groupId, String planId, UUID userId) {
    SettlementAccess access = settlementAccess(groupId, planId, userId);
    Optional<SettlementEntity> existingFinalSettlement = findFinalSettlement(access.plan());
    if (existingFinalSettlement.isPresent()) {
      return settlementCard(existingFinalSettlement.get(), false, access.user());
    }
    Optional<SettlementDraftEntity> draftForUpdate = settlementDraftRepository.findByPlanForUpdate(access.plan());
    if (draftForUpdate.isEmpty()) {
      return findFinalSettlement(access.plan())
        .map(settlement -> settlementCard(settlement, false, access.user()))
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "settlement_draft_not_found"));
    }
    SettlementDraftEntity draft = draftForUpdate.get();
    Optional<SettlementEntity> finalSettlementAfterLock = findFinalSettlement(access.plan());
    if (finalSettlementAfterLock.isPresent()) {
      return settlementCard(finalSettlementAfterLock.get(), false, access.user());
    }
    if (!STATUS_DRAFT.equals(draft.getStatus())) {
      throw new ResponseStatusException(HttpStatus.CONFLICT, "settlement_already_finalized");
    }
    List<SectionView> sections = sectionViewsForDraft(draft);
    List<ItemView> items = itemViews(sections);
    if (items.isEmpty()) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "missing_settlement_items");
    }

    String publicId = nextPublicId(settlementRepository.findAll().stream().map(SettlementEntity::getPublicId).toList(), 301);
    SettlementEntity settlement = new SettlementEntity(
      publicId,
      access.group(),
      access.plan(),
      toJson(payloadFromSectionViews(access.plan(), sections, ""))
    );
    settlement.markCreatedBy(access.user());
    SettlementEntity savedSettlement = settlementRepository.save(settlement);
    copySectionsToSettlement(savedSettlement, sections);

    List<TransferView> transfers = calculateTransfers(items);
    for (TransferView transfer : transfers) {
      settlementTransferRepository.save(new SettlementTransferEntity(
        savedSettlement,
        transfer.fromUser(),
        transfer.toUser(),
        transfer.amountWon(),
        transfer.fromName() + " -> " + transfer.toName()
      ));
    }
    draft.markFinalized(savedSettlement);
    settlementDraftRepository.save(draft);

    if (transfers.isEmpty()) {
      savedSettlement.markCompleted();
      outboxService.record("settlement.completed", "settlement", savedSettlement.getId(), settlementEventPayload(access.group(), access.plan(), savedSettlement));
    } else {
      createSettlementSideEffects(access.group(), access.plan(), savedSettlement, sections, transfers, access.user());
      outboxService.record("settlement.finalized", "settlement", savedSettlement.getId(), settlementEventPayload(access.group(), access.plan(), savedSettlement));
    }
    return settlementCard(savedSettlement, false, access.user());
  }

  @Transactional(readOnly = true)
  public Map<String, Object> settlement(String groupId, String planId, UUID userId) {
    return currentSettlement(groupId, planId, userId);
  }

  @Transactional(readOnly = true)
  public Map<String, Object> currentSettlement(String groupId, String planId, UUID userId) {
    SettlementAccess access = settlementAccess(groupId, planId, userId);
    return settlementDraftRepository.findActiveByPlan(access.plan())
      .map(draft -> settlementDraftCard(draft, true, access.user()))
      .or(() -> settlementRepository.findFirstByPlanAndStatusInOrderByCreatedAtDesc(access.plan(), List.of(STATUS_FINALIZED))
        .map(settlement -> settlementCard(settlement, false, access.user())))
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "settlement_not_found"));
  }

  @Transactional(readOnly = true)
  public Map<String, Object> settlementById(String groupId, String planId, String settlementId, UUID userId) {
    SettlementAccess access = settlementAccess(groupId, planId, userId);
    SettlementEntity settlement = settlementRepository.findByPlanAndPublicId(access.plan(), settlementId)
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "settlement_not_found"));
    return settlementCard(settlement, false, access.user());
  }

  @Transactional(readOnly = true)
  public Map<String, Object> settlementBasis(String groupId, String planId, String settlementId, UUID userId) {
    SettlementAccess access = settlementAccess(groupId, planId, userId);
    SettlementEntity settlement = settlementRepository.findByPlanAndPublicId(access.plan(), settlementId)
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "settlement_not_found"));
    List<SectionView> sections = sectionViewsForSettlement(settlement);
    List<ItemView> items = itemViews(sections);
    Map<String, MemberBalance> balances = memberBalances(items);
    List<TransferView> transfers = persistedOrCalculatedTransfers(settlement, items);

    Map<String, Object> value = new LinkedHashMap<>();
    value.put("settlementId", settlement.getPublicId());
    value.put("planTitle", access.plan().getTitle());
    value.put("totalAmountLabel", amountLabel(items.stream().map(ItemView::amountWon).reduce(0L, Long::sum)));
    value.put("sections", sections.stream().map(this::basisSectionCard).toList());
    value.put("participants", balances.values().stream().map(this::basisParticipantCard).toList());
    value.put("transfers", transfers.stream().map(this::transferCard).toList());
    value.put("summary", "각 사용자의 실제 지출액과 부담액 차이를 계산한 뒤, 부족한 사람에서 초과 지출한 사람으로 최소 이체 건수를 만들었어요.");
    return value;
  }

  @Transactional
  public Map<String, Object> markTransferSent(String groupId, String planId, String settlementId, String transferId, UUID userId) {
    SettlementAccess access = settlementAccess(groupId, planId, userId);
    SettlementAndTransfer target = settlementTransferForUpdate(access.plan(), settlementId, transferId);
    if (!sameUser(target.transfer().getFromUser(), access.user())) {
      throw new ResponseStatusException(HttpStatus.FORBIDDEN, "settlement_confirmation_forbidden");
    }
    saveConfirmation(target.transfer(), access.user(), "sent");
    target.transfer().markSent();
    return settlementCard(target.settlement(), false, access.user());
  }

  @Transactional
  public Map<String, Object> markTransferReceived(String groupId, String planId, String settlementId, String transferId, UUID userId) {
    SettlementAccess access = settlementAccess(groupId, planId, userId);
    SettlementAndTransfer target = settlementTransferForUpdate(access.plan(), settlementId, transferId);
    if (!sameUser(target.transfer().getToUser(), access.user())) {
      throw new ResponseStatusException(HttpStatus.FORBIDDEN, "settlement_confirmation_forbidden");
    }
    saveConfirmation(target.transfer(), access.user(), "received");
    target.transfer().markReceived();
    if (allReceiversConfirmed(target.settlement())) {
      target.settlement().markCompleted();
      createSettlementCompletedActivity(access.group(), access.plan(), target.settlement(), access.user());
      outboxService.record("settlement.completed", "settlement", target.settlement().getId(), settlementEventPayload(access.group(), access.plan(), target.settlement()));
    }
    return settlementCard(target.settlement(), false, access.user());
  }

  private Map<String, Object> createInitialDraft(SettlementAccess access) {
    SettlementDraftEntity draft = new SettlementDraftEntity(
      nextPublicId(settlementDraftRepository.findAll().stream().map(SettlementDraftEntity::getPublicId).toList(), 301),
      access.group(),
      access.plan(),
      "{}"
    );
    draft.markCreatedBy(access.user());
    SettlementDraftEntity saved = settlementDraftRepository.save(draft);
    List<SectionInput> sections = initialSections(access.plan(), access.user());
    replaceDraftSections(saved, sections);
    saved.setPayload(toJson(payloadFromSections(access.plan(), sections, "")));
    return settlementDraftCard(saved, true, access.user());
  }

  private void replaceDraftSections(SettlementDraftEntity draft, List<SectionInput> sections) {
    boolean deletedRows = false;
    List<SettlementSectionEntity> previousSections = settlementSectionRepository.findBySettlementDraftOrderBySortOrderAsc(draft);
    if (!previousSections.isEmpty()) {
      List<SettlementItemEntity> previousItems = previousSections.stream()
        .map(settlementItemRepository::findBySectionOrderByCreatedAtAsc)
        .flatMap(Collection::stream)
        .toList();
      if (!previousItems.isEmpty()) {
        settlementItemTargetRepository.deleteBySettlementItemIn(previousItems);
        settlementItemRepository.deleteBySectionIn(previousSections);
      }
      settlementSectionRepository.deleteBySettlementDraft(draft);
      deletedRows = true;
    }
    List<SettlementItemEntity> unsectionedItems = settlementItemRepository.findBySettlementDraft(draft);
    if (!unsectionedItems.isEmpty()) {
      settlementItemTargetRepository.deleteBySettlementItemIn(unsectionedItems);
      settlementItemRepository.deleteBySettlementDraft(draft);
      deletedRows = true;
    }
    if (deletedRows) {
      settlementSectionRepository.flush();
    }

    for (SectionInput section : sections) {
      SettlementSectionEntity savedSection = settlementSectionRepository.save(new SettlementSectionEntity(
        draft,
        null,
        section.publicId(),
        section.schedulePlace(),
        section.title(),
        section.payer(),
        section.sortOrder()
      ));
      saveItems(savedSection, draft, null, section.items());
    }
  }

  private void copySectionsToSettlement(SettlementEntity settlement, List<SectionView> sections) {
    for (SectionView section : sections) {
      SettlementSectionEntity savedSection = settlementSectionRepository.save(new SettlementSectionEntity(
        null,
        settlement,
        section.publicId(),
        section.schedulePlace(),
        section.title(),
        section.payer(),
        section.sortOrder()
      ));
      saveItems(savedSection, null, settlement, section.items());
    }
  }

  private void saveItems(
    SettlementSectionEntity section,
    SettlementDraftEntity draft,
    SettlementEntity settlement,
    List<ItemView> items
  ) {
    for (ItemView itemView : items) {
      SettlementItemEntity item = settlementItemRepository.save(new SettlementItemEntity(
        draft,
        settlement,
        section,
        itemView.publicId(),
        itemView.title(),
        itemView.amountWon(),
        itemView.splitType(),
        null
      ));
      for (TargetShare target : itemView.targets()) {
        settlementItemTargetRepository.save(new SettlementItemTargetEntity(item, target.user(), target.amountWon()));
      }
    }
  }

  private void createSettlementSideEffects(
    GroupEntity group,
    PlanEntity plan,
    SettlementEntity settlement,
    List<SectionView> sections,
    List<TransferView> transfers,
    UserEntity actor
  ) {
    Map<String, Object> activityPayload = new LinkedHashMap<>();
    activityPayload.put("senderName", "ONMU");
    activityPayload.put("message", plan.getTitle() + " 정산이 확정됐어요.");
    activityPayload.put("messageType", "settlement_card");
    activityPayload.put("cardType", "settlement");
    activityPayload.put("planId", plan.getPublicId());
    activityPayload.put("settlementId", settlement.getPublicId());
    activityPayload.put("settlementStatus", settlement.getStatus());
    activityPayload.put("itemCount", itemViews(sections).size());
    activityPayload.put("transferCount", transfers.size());
    activityPayload.put("totalAmountLabel", amountLabel(itemViews(sections).stream().map(ItemView::amountWon).reduce(0L, Long::sum)));
    activityPayload.put("source", "spring_api");
    chatActivityEventRepository.save(new ChatActivityEventEntity(
      group,
      plan,
      actor,
      "settlement.finalized",
      toJson(activityPayload),
      Instant.now()
    ));

    for (UserEntity recipient : settlementRecipients(sections)) {
      if (!notificationPreferenceService.isEnabled(recipient.getId(), SETTLEMENT_NOTIFICATION_TYPE, "in_app")) {
        continue;
      }
      NotificationEntity notification = notificationRepository.save(new NotificationEntity(
        recipient,
        group,
        plan,
        SETTLEMENT_NOTIFICATION_TYPE,
        plan.getTitle() + " 정산이 확정됐어요",
        "약속 정산 송금 내역을 확인해 주세요.",
        toJson(settlementEventPayload(group, plan, settlement)),
        "queued",
        null,
        Instant.now()
      ));
      outboxService.record("notification.requested", "notification", notification.getId(), Map.of(
        "groupId", group.getPublicId(),
        "planId", plan.getPublicId(),
        "settlementId", settlement.getPublicId(),
        "notificationId", notification.getId().toString(),
        "notificationType", notification.getNotificationType(),
        "channels", List.of("push")
      ));
    }
  }

  private Optional<SettlementEntity> findFinalSettlement(PlanEntity plan) {
    return settlementRepository.findFirstByPlanAndStatusInOrderByCreatedAtDesc(
      plan,
      List.of(STATUS_FINALIZED, STATUS_COMPLETED)
    );
  }

  private void createSettlementCompletedActivity(
    GroupEntity group,
    PlanEntity plan,
    SettlementEntity settlement,
    UserEntity actor
  ) {
    Map<String, Object> activityPayload = new LinkedHashMap<>();
    activityPayload.put("senderName", "ONMU");
    activityPayload.put("message", plan.getTitle() + " 정산이 완료됐어요.");
    activityPayload.put("messageType", "system");
    activityPayload.put("cardType", "system");
    activityPayload.put("planId", plan.getPublicId());
    activityPayload.put("settlementId", settlement.getPublicId());
    activityPayload.put("settlementStatus", settlement.getStatus());
    activityPayload.put("source", "spring_api");
    chatActivityEventRepository.save(new ChatActivityEventEntity(
      group,
      plan,
      actor,
      "settlement.completed",
      toJson(activityPayload),
      Instant.now()
    ));
  }

  private Map<String, Object> settlementDraftCard(SettlementDraftEntity draft, boolean persisted, UserEntity currentUser) {
    List<SectionView> sections = sectionViewsForDraft(draft);
    List<ItemView> items = itemViews(sections);
    Map<String, Object> value = new LinkedHashMap<>();
    value.put("id", draft.getPublicId());
    value.put("groupId", draft.getGroup().getPublicId());
    value.put("planId", draft.getPlan().getPublicId());
    value.put("status", STATUS_DRAFT);
    value.put("version", draft.getVersion());
    value.put("persisted", persisted);
    value.put("targetPatchAvailable", persisted && !items.isEmpty());
    value.put("sections", sections.stream().map(this::sectionCard).toList());
    value.put("items", items.stream().map(this::draftItemCard).toList());
    value.put("preview", settlementSummaryCard("preview", STATUS_DRAFT, draft.getPlan(), sections, calculateTransfers(items), true, currentUser));
    return value;
  }

  private Map<String, Object> settlementCard(SettlementEntity settlement, boolean preview, UserEntity currentUser) {
    List<SectionView> sections = sectionViewsForSettlement(settlement);
    List<ItemView> items = itemViews(sections);
    return settlementSummaryCard(
      settlement.getPublicId(),
      settlement.getStatus(),
      settlement.getPlan(),
      sections,
      persistedOrCalculatedTransfers(settlement, items),
      preview,
      currentUser
    );
  }

  private Map<String, Object> settlementSummaryCard(
    String publicId,
    String status,
    PlanEntity plan,
    List<SectionView> sections,
    List<TransferView> transferViews,
    boolean preview,
    UserEntity currentUser
  ) {
    List<ItemView> items = itemViews(sections);
    long totalAmount = items.stream().map(ItemView::amountWon).reduce(0L, Long::sum);
    Map<String, MemberBalance> balances = memberBalances(items);
    String currentUserKey = memberKey(currentUser);

    Map<String, Object> value = new LinkedHashMap<>();
    value.put("id", publicId);
    value.put("planId", plan.getPublicId());
    value.put("planTitle", plan.getTitle());
    value.put("status", status);
    value.put("preview", preview);
    value.put("totalAmount", totalAmount);
    value.put("totalAmountWon", totalAmount);
    value.put("totalAmountLabel", amountLabel(totalAmount));
    value.put("createdDateLabel", preview ? "미리보기" : switch (status) {
      case STATUS_DRAFT -> "정산 입력 중";
      case STATUS_COMPLETED -> "정산 완료";
      default -> "정산 확정";
    });
    value.put("itemCountLabel", "결제 항목 " + items.size() + "개");
    value.put("finalSummaryLabel", transferViews.isEmpty() ? "이체할 내역이 없어요" : transferViews.size() + "건 이체 필요");
    value.put("mySummaryLabel", mySummaryLabel(balances.get(currentUserKey)));
    value.put("sections", sections.stream().map(this::sectionCard).toList());
    value.put("paymentItems", items.stream().map(this::paymentItemCard).toList());
    value.put("memberResults", balances.values().stream()
      .sorted(Comparator.comparing(MemberBalance::userPublicId))
      .map(balance -> memberResultCard(balance, currentUserKey))
      .toList());
    value.put("participantStatuses", balances.values().stream()
      .sorted(Comparator.comparing(MemberBalance::userPublicId))
      .map(balance -> participantStatusCard(balance, transferViews))
      .toList());
    value.put("transfers", transferViews.stream().map(this::transferCard).toList());
    value.put("shareMessage", plan.getTitle() + " 약속 정산입니다.");
    return value;
  }

  private Map<String, Object> sectionCard(SectionView section) {
    Map<String, Object> value = new LinkedHashMap<>();
    value.put("id", section.publicId());
    value.put("schedulePlaceId", section.schedulePlace() == null ? null : section.schedulePlace().getPublicId());
    value.put("title", section.title());
    value.put("payerUserId", userId(section.payer()));
    value.put("payerName", nickname(section.payer()));
    value.put("payerProfileImageUrl", profileImageUrl(section.payer()));
    value.put("payerPixelCharacter", userAvatarReadModelMapper.pixelCharacter(section.payer()));
    value.put("sortOrder", section.sortOrder());
    value.put("items", section.items().stream().map(this::draftItemCard).toList());
    value.put("totalAmountWon", section.items().stream().map(ItemView::amountWon).reduce(0L, Long::sum));
    return value;
  }

  private Map<String, Object> draftItemCard(ItemView item) {
    Map<String, Object> value = new LinkedHashMap<>();
    value.put("id", item.publicId());
    value.put("sectionId", item.sectionId());
    value.put("title", item.title());
    value.put("amountWon", item.amountWon());
    value.put("amountLabel", amountLabel(item.amountWon()));
    value.put("splitType", item.splitType());
    value.put("targetUserIds", item.targets().stream().map(target -> target.user().getId().toString()).toList());
    value.put("targetShares", item.targets().stream().map(target -> {
      Map<String, Object> targetShare = new LinkedHashMap<>();
      targetShare.put("userId", userId(target.user()));
      targetShare.put("amountWon", target.amountWon());
      return targetShare;
    }).toList());
    value.put("participants", item.targets().stream().map(target -> {
      Map<String, Object> participant = new LinkedHashMap<>();
      participant.put("name", target.name());
      participant.put("userId", target.user().getId().toString());
      userAvatarReadModelMapper.putAvatar(participant, target.user());
      participant.put("amountWon", target.amountWon());
      participant.put("owedAmountLabel", amountLabel(target.amountWon()));
      participant.put("included", true);
      return participant;
    }).toList());
    return value;
  }

  private Map<String, Object> paymentItemCard(ItemView item) {
    Map<String, Object> value = draftItemCard(item);
    Map<String, Object> payerShare = new LinkedHashMap<>();
    payerShare.put("userId", userId(item.payer()));
    payerShare.put("name", nickname(item.payer()));
    userAvatarReadModelMapper.putAvatar(payerShare, item.payer());
    payerShare.put("amountLabel", amountLabel(item.amountWon()));
    value.put("payerShares", List.of(payerShare));
    value.put("targetLabel", item.targets().size() + "명");
    return value;
  }

  private Map<String, Object> memberResultCard(MemberBalance balance, String currentUserKey) {
    long net = balance.netWon();
    Map<String, Object> value = new LinkedHashMap<>();
    value.put("userId", userId(balance.user()));
    value.put("name", nickname(balance.user()));
    userAvatarReadModelMapper.putAvatar(value, balance.user());
    value.put("finalShareLabel", amountLabel(balance.owedWon()));
    value.put("paidAmountLabel", amountLabel(balance.paidWon()));
    value.put("resultLabel", resultLabel(net));
    value.put("isMe", currentUserKey.equals(memberKey(balance.user())));
    value.put("willReceive", net > 0);
    return value;
  }

  private Map<String, Object> participantStatusCard(MemberBalance balance, List<TransferView> transfers) {
    UserEntity user = balance.user();
    List<TransferView> outgoing = transfers.stream()
      .filter(transfer -> sameUser(transfer.fromUser(), user))
      .toList();
    List<TransferView> incoming = transfers.stream()
      .filter(transfer -> sameUser(transfer.toUser(), user))
      .toList();
    boolean receiver = !incoming.isEmpty();
    boolean sent = !outgoing.isEmpty() && outgoing.stream().allMatch(TransferView::sentConfirmed);
    boolean received = receiver && incoming.stream().allMatch(transfer -> transfer.receivedConfirmed() || "received".equals(transfer.status()));
    boolean completed = receiver ? received : sent;
    Map<String, Object> value = new LinkedHashMap<>();
    value.put("userId", userId(user));
    value.put("name", nickname(user));
    userAvatarReadModelMapper.putAvatar(value, user);
    value.put("willReceive", receiver);
    value.put("sent", sent);
    value.put("received", received);
    value.put("completed", completed);
    return value;
  }

  private Map<String, Object> transferCard(TransferView transfer) {
    Map<String, Object> value = new LinkedHashMap<>();
    value.put("id", transfer.publicId());
    value.put("fromUserId", userId(transfer.fromUser()));
    value.put("fromName", transfer.fromName());
    userAvatarReadModelMapper.putPrefixedAvatar(value, "from", transfer.fromUser());
    value.put("toUserId", userId(transfer.toUser()));
    value.put("toName", transfer.toName());
    userAvatarReadModelMapper.putPrefixedAvatar(value, "to", transfer.toUser());
    value.put("amountWon", transfer.amountWon());
    value.put("amountLabel", amountLabel(transfer.amountWon()));
    value.put("status", transfer.status());
    return value;
  }

  private Map<String, Object> basisSectionCard(SectionView section) {
    Map<String, Object> value = sectionCard(section);
    value.put("description", section.title() + "에서 " + nickname(section.payer()) + "님이 결제한 항목을 대상자별로 나눴어요.");
    return value;
  }

  private Map<String, Object> basisParticipantCard(MemberBalance balance) {
    Map<String, Object> value = new LinkedHashMap<>();
    value.put("userId", userId(balance.user()));
    value.put("name", nickname(balance.user()));
    userAvatarReadModelMapper.putAvatar(value, balance.user());
    value.put("paidTotalLabel", amountLabel(balance.paidWon()));
    value.put("owedTotalLabel", amountLabel(balance.owedWon()));
    value.put("netLabel", resultLabel(balance.netWon()));
    return value;
  }

  private List<SectionInput> initialSections(PlanEntity plan, UserEntity defaultPayer) {
    List<SectionInput> sections = new ArrayList<>();
    int order = 0;
    for (SchedulePlaceEntity place : schedulePlaceRepository.findByPlanOrderBySortOrderAsc(plan)) {
      sections.add(new SectionInput(
        place.getPublicId(),
        place,
        place.getName(),
        defaultPayer,
        order++,
        List.of()
      ));
    }
    sections.add(new SectionInput(EXTRA_SECTION_ID, null, "기타 비용", defaultPayer, order, List.of()));
    return sections;
  }

  private List<SectionInput> sectionInputs(
    List<SettlementDraftSectionRequest> requests,
    PlanEntity plan,
    List<UserEntity> participants
  ) {
    if (requests == null || requests.isEmpty()) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "missing_settlement_sections");
    }
    Map<String, UserEntity> participantsByUserId = participantsByUserId(participants);
    int order = 0;
    List<SectionInput> sections = new ArrayList<>();
    for (SettlementDraftSectionRequest request : requests) {
      SchedulePlaceEntity schedulePlace = schedulePlace(request.schedulePlaceId(), plan);
      String sectionId = stringOrDefault(request.id(), schedulePlace == null ? EXTRA_SECTION_ID : schedulePlace.getPublicId());
      String title = stringOrDefault(request.title(), schedulePlace == null ? "기타 비용" : schedulePlace.getName());
      List<SettlementDraftItemRequest> rawItems = request.items() == null ? List.of() : request.items();
      UserEntity payer = userFromParticipant(request.payerUserId(), participantsByUserId);
      if (!rawItems.isEmpty() && payer == null) {
        throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "settlement_participant_not_found");
      }
      List<ItemView> items = new ArrayList<>();
      for (SettlementDraftItemRequest itemRequest : rawItems) {
        items.add(itemViewFromRequest(sectionId, payer, itemRequest, participants));
      }
      sections.add(new SectionInput(sectionId, schedulePlace, title, payer, order++, items));
    }
    return sections;
  }

  private ItemView itemViewFromRequest(
    String sectionId,
    UserEntity payer,
    SettlementDraftItemRequest request,
    List<UserEntity> participants
  ) {
    long amount = request.amountWon() == null ? 0 : request.amountWon();
    if (amount <= 0) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "invalid_settlement_amount");
    }
    String splitType = normalizeSplitType(request.splitType());
    List<TargetShare> targetShares = targetSharesFromRequest(
      amount,
      request.targetShares(),
      "equal".equals(splitType) ? List.of() : request.targetUserIds(),
      participants
    );
    return new ItemView(
      stringOrDefault(request.id(), "stli_" + UUID.randomUUID().toString().replace("-", "")),
      sectionId,
      stringOrDefault(request.title(), "결제 항목"),
      amount,
      splitType,
      payer,
      targetShares
    );
  }

  private List<TargetShare> targetSharesFromRequest(
    long amount,
    List<SettlementTargetShareRequest> rawShares,
    List<String> targetUserIds,
    List<UserEntity> participants
  ) {
    if (rawShares != null && !rawShares.isEmpty()) {
      return customTargetShares(amount, rawShares, participants);
    }
    List<UserEntity> targets = targetUserIds == null || targetUserIds.isEmpty()
      ? participants
      : usersByUserIds(targetUserIds, participants);
    List<Long> targetAmounts = splitAmount(amount, targets);
    List<TargetShare> targetShares = new ArrayList<>();
    for (int index = 0; index < targets.size(); index++) {
      targetShares.add(new TargetShare(targets.get(index), targetAmounts.get(index)));
    }
    return targetShares;
  }

  private List<TargetShare> customTargetShares(
    long amount,
    List<SettlementTargetShareRequest> rawShares,
    List<UserEntity> participants
  ) {
    Map<String, UserEntity> participantsByUserId = participantsByUserId(participants);
    Set<String> seenUserIds = new LinkedHashSet<>();
    List<TargetShare> targetShares = new ArrayList<>();
    long total = 0;
    for (SettlementTargetShareRequest share : rawShares) {
      String userId = share == null ? "" : stringOrDefault(share.userId(), "");
      if (userId.isBlank()) {
        throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "settlement_participant_not_found");
      }
      if (!seenUserIds.add(userId)) {
        throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "duplicate_settlement_target");
      }
      UserEntity user = userFromParticipant(userId, participantsByUserId);
      long shareAmount = share.amountWon() == null ? 0 : share.amountWon();
      if (shareAmount <= 0) {
        throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "invalid_settlement_target_amount");
      }
      total += shareAmount;
      targetShares.add(new TargetShare(user, shareAmount));
    }
    if (targetShares.isEmpty()) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "missing_settlement_targets");
    }
    if (total != amount) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "settlement_target_amount_mismatch");
    }
    return targetShares.stream()
      .sorted(Comparator.comparing(target -> target.user().getPublicId()))
      .toList();
  }

  private List<SectionView> sectionViewsForDraft(SettlementDraftEntity draft) {
    List<SettlementSectionEntity> sections = settlementSectionRepository.findBySettlementDraftOrderBySortOrderAsc(draft);
    if (!sections.isEmpty()) {
      return sections.stream().map(section -> sectionView(section, settlementItemRepository.findBySectionOrderByCreatedAtAsc(section))).toList();
    }
    List<SectionView> payloadSections = sectionViewsFromPayload(draft.getPlan(), draft.getPayload());
    if (!payloadSections.isEmpty()) {
      return payloadSections;
    }
    List<SettlementItemEntity> legacyItems = settlementItemRepository.findBySettlementDraftOrderByCreatedAtAsc(draft);
    if (!legacyItems.isEmpty()) {
      return List.of(sectionView(new SectionFallback(EXTRA_SECTION_ID, "기타 비용", null, 0), legacyItems));
    }
    return List.of();
  }

  private List<SectionView> sectionViewsForSettlement(SettlementEntity settlement) {
    List<SettlementSectionEntity> sections = settlementSectionRepository.findBySettlementOrderBySortOrderAsc(settlement);
    if (!sections.isEmpty()) {
      return sections.stream().map(section -> sectionView(section, settlementItemRepository.findBySectionOrderByCreatedAtAsc(section))).toList();
    }
    List<SectionView> payloadSections = sectionViewsFromPayload(settlement.getPlan(), settlement.getPayload());
    if (!payloadSections.isEmpty()) {
      return payloadSections;
    }
    List<SettlementItemEntity> legacyItems = settlementItemRepository.findBySettlementOrderByCreatedAtAsc(settlement);
    if (!legacyItems.isEmpty()) {
      return List.of(sectionView(new SectionFallback(EXTRA_SECTION_ID, "기타 비용", null, 0), legacyItems));
    }
    return List.of();
  }

  private SectionView sectionView(SettlementSectionEntity section, List<SettlementItemEntity> items) {
    return sectionView(
      new SectionFallback(section.getPublicId(), section.getTitle(), section.getPayerUser(), section.getSortOrder(), section.getSchedulePlace()),
      items
    );
  }

  private SectionView sectionView(SectionFallback section, List<SettlementItemEntity> items) {
    Map<UUID, List<SettlementItemTargetEntity>> targetsByItem = settlementItemTargetRepository.findBySettlementItemInOrderByCreatedAtAsc(items).stream()
      .collect(Collectors.groupingBy(
        target -> target.getSettlementItem().getId(),
        LinkedHashMap::new,
        Collectors.toList()
      ));
    List<ItemView> itemViews = items.stream()
      .map(item -> new ItemView(
        item.getPublicId(),
        section.publicId(),
        item.getTitle(),
        item.getAmountWon(),
        normalizeSplitType(item.getSplitType()),
        section.payer(),
        targetsByItem.getOrDefault(item.getId(), List.of()).stream()
          .map(target -> new TargetShare(target.getUser(), target.getAmountWon() == null ? 0 : target.getAmountWon()))
          .toList()
      ))
      .toList();
    return new SectionView(section.publicId(), section.schedulePlace(), section.title(), section.payer(), section.sortOrder(), itemViews);
  }

  private List<SectionView> sectionViewsFromPayload(PlanEntity plan, String payload) {
    Object rawSections = readObject(payload).get("sections");
    if (!(rawSections instanceof List<?> sectionItems)) {
      return List.of();
    }
    List<UserEntity> participants = activeParticipants(plan);
    Map<String, UserEntity> participantsByUserId = participantsByUserId(participants);
    List<SectionView> sections = new ArrayList<>();
    int order = 0;
    for (Object rawSection : sectionItems) {
      if (!(rawSection instanceof Map<?, ?> sectionMap)) {
        continue;
      }
      String sectionId = firstString(sectionMap, "id", "sectionId");
      SchedulePlaceEntity place = schedulePlace(firstString(sectionMap, "schedulePlaceId"), plan);
      UserEntity payer = nullableParticipant(firstString(sectionMap, "payerUserId"), participantsByUserId);
      List<ItemView> items = new ArrayList<>();
      Object rawItems = sectionMap.get("items");
      if (rawItems instanceof List<?> itemItems) {
        for (Object rawItem : itemItems) {
          if (rawItem instanceof Map<?, ?> itemMap) {
            UserEntity itemPayer = payer == null
              ? nullableParticipant(firstString(itemMap, "payerUserId"), participantsByUserId)
              : payer;
            long amount = longValue(itemMap.get("amountWon"), 0);
            List<TargetShare> targetShares = targetSharesFromPayload(amount, itemMap, participants);
            items.add(new ItemView(
              stringOrDefault(firstString(itemMap, "id"), "stli_" + UUID.randomUUID().toString().replace("-", "")),
              sectionId,
              stringOrDefault(firstString(itemMap, "title"), "결제 항목"),
              amount,
              normalizeSplitType(firstString(itemMap, "splitType")),
              itemPayer,
              targetShares
            ));
          }
        }
      }
      sections.add(new SectionView(
        stringOrDefault(sectionId, place == null ? EXTRA_SECTION_ID : place.getPublicId()),
        place,
        stringOrDefault(firstString(sectionMap, "title"), place == null ? "기타 비용" : place.getName()),
        payer,
        order++,
        items
      ));
    }
    return sections;
  }

  private List<TargetShare> targetSharesFromPayload(
    long amount,
    Map<?, ?> itemMap,
    List<UserEntity> participants
  ) {
    Object rawTargetShares = itemMap.get("targetShares");
    if (rawTargetShares instanceof List<?> shareItems && !shareItems.isEmpty()) {
      List<SettlementTargetShareRequest> shares = new ArrayList<>();
      for (Object rawShare : shareItems) {
        if (!(rawShare instanceof Map<?, ?> shareMap)) {
          continue;
        }
        shares.add(new SettlementTargetShareRequest(
          firstString(shareMap, "userId"),
          longValue(shareMap.get("amountWon"), 0)
        ));
      }
      return targetSharesFromRequest(amount, shares, List.of(), participants);
    }
    return targetSharesFromRequest(amount, null, stringList(itemMap.get("targetUserIds")), participants);
  }

  private List<ItemView> itemViews(List<SectionView> sections) {
    return sections.stream().map(SectionView::items).flatMap(Collection::stream).toList();
  }

  private List<TransferView> persistedOrCalculatedTransfers(SettlementEntity settlement, List<ItemView> itemViews) {
    List<TransferView> persisted = settlementTransferRepository.findBySettlementOrderByCreatedAtAsc(settlement).stream()
      .map(transfer -> new TransferView(
        transfer.getPublicId(),
        transfer.getFromUser(),
        transfer.getToUser(),
        transfer.getAmountWon(),
        transfer.getStatus(),
        settlementConfirmationRepository.existsBySettlementTransferAndConfirmationType(transfer, "sent"),
        settlementConfirmationRepository.existsBySettlementTransferAndConfirmationType(transfer, "received")
      ))
      .toList();
    return persisted.isEmpty() ? calculateTransfers(itemViews) : persisted;
  }

  private List<TransferView> calculateTransfers(List<ItemView> itemViews) {
    Map<String, MemberBalance> balances = memberBalances(itemViews);
    List<MemberBalance> debtors = balances.values().stream()
      .filter(balance -> balance.netWon() < 0)
      .map(MemberBalance::copy)
      .sorted(Comparator.comparing(MemberBalance::userPublicId))
      .toList();
    List<MemberBalance> creditors = balances.values().stream()
      .filter(balance -> balance.netWon() > 0)
      .map(MemberBalance::copy)
      .sorted(Comparator.comparing(MemberBalance::userPublicId))
      .toList();

    List<TransferView> transfers = new ArrayList<>();
    int creditorIndex = 0;
    for (MemberBalance debtor : debtors) {
      long debt = -debtor.netWon();
      while (debt > 0 && creditorIndex < creditors.size()) {
        MemberBalance creditor = creditors.get(creditorIndex);
        long amount = Math.min(debt, creditor.netWon());
        if (amount > 0) {
          transfers.add(new TransferView(
            "preview-" + debtor.userPublicId() + "-" + creditor.userPublicId(),
            debtor.user(),
            creditor.user(),
            amount,
            "pending",
            false,
            false
          ));
        }
        debt -= amount;
        creditor.reducePaid(amount);
        if (creditor.netWon() == 0) {
          creditorIndex++;
        }
      }
    }
    return transfers;
  }

  private Map<String, MemberBalance> memberBalances(List<ItemView> itemViews) {
    Map<String, MemberBalance> balances = new LinkedHashMap<>();
    for (ItemView item : itemViews) {
      balances.computeIfAbsent(memberKey(item.payer()), ignored -> MemberBalance.empty(item.payer()))
        .addPaid(item.amountWon());
      for (TargetShare target : item.targets()) {
        balances.computeIfAbsent(memberKey(target.user()), ignored -> MemberBalance.empty(target.user()))
          .addOwed(target.amountWon());
      }
    }
    return balances;
  }

  private List<Long> splitAmount(long amount, List<UserEntity> rawTargets) {
    if (rawTargets == null || rawTargets.isEmpty()) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "missing_settlement_targets");
    }
    List<UserEntity> targets = rawTargets.stream()
      .sorted(Comparator.comparing(UserEntity::getPublicId))
      .toList();
    long base = amount / targets.size();
    long remainder = amount % targets.size();
    List<Long> values = new ArrayList<>();
    for (int index = 0; index < targets.size(); index++) {
      values.add(base + (index < remainder ? 1 : 0));
    }
    return values;
  }

  private void saveConfirmation(SettlementTransferEntity transfer, UserEntity user, String type) {
    settlementConfirmationRepository.findBySettlementTransferAndUserAndConfirmationType(transfer, user, type)
      .orElseGet(() -> settlementConfirmationRepository.save(new SettlementConfirmationEntity(transfer, user, type, null)));
  }

  private boolean allReceiversConfirmed(SettlementEntity settlement) {
    return settlementTransferRepository.findBySettlementOrderByCreatedAtAsc(settlement).stream()
      .allMatch(transfer -> settlementConfirmationRepository.existsBySettlementTransferAndConfirmationType(transfer, "received"));
  }

  private SettlementAndTransfer settlementTransferForUpdate(PlanEntity plan, String settlementId, String transferId) {
    SettlementEntity settlement = settlementRepository.findByPlanAndPublicIdForUpdate(plan, settlementId)
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "settlement_not_found"));
    if (STATUS_COMPLETED.equals(settlement.getStatus())) {
      throw new ResponseStatusException(HttpStatus.CONFLICT, "settlement_already_completed");
    }
    SettlementTransferEntity transfer = settlementTransferRepository.findBySettlementAndPublicId(settlement, transferId)
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "settlement_transfer_not_found"));
    return new SettlementAndTransfer(settlement, transfer);
  }

  private SettlementAccess settlementAccess(String groupId, String planId, UUID userId) {
    UserEntity user = userOrThrow(userId);
    GroupEntity group = groupOrThrow(groupId);
    if (user.getId() == null || !groupRepository.isUserMember(group.getPublicId(), user.getId())) {
      throw new ResponseStatusException(HttpStatus.FORBIDDEN, "not_group_member");
    }
    PlanEntity plan = planRepository.findByGroupAndPublicId(group, planId)
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "plan_not_found"));
    requirePlanParticipant(plan, user);
    return new SettlementAccess(group, plan, user);
  }

  private void requirePlanParticipant(PlanEntity plan, UserEntity user) {
    PlanParticipantEntity participant = planParticipantRepository.findByPlanAndUser(plan, user)
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.FORBIDDEN, "settlement_participant_not_found"));
    if (!isActivePlanParticipant(participant)) {
      throw new ResponseStatusException(HttpStatus.FORBIDDEN, "settlement_participant_not_found");
    }
  }

  private List<UserEntity> activeParticipants(PlanEntity plan) {
    List<UserEntity> participants = planParticipantRepository.findByPlanOrderByCreatedAtAsc(plan).stream()
      .filter(this::isActivePlanParticipant)
      .map(PlanParticipantEntity::getUser)
      .sorted(Comparator.comparing(UserEntity::getPublicId))
      .toList();
    if (participants.isEmpty()) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "missing_settlement_targets");
    }
    return participants;
  }

  private boolean isActivePlanParticipant(PlanParticipantEntity participant) {
    String status = participant.getStatus() == null ? "" : participant.getStatus().toLowerCase(Locale.ROOT);
    String response = participant.getResponse() == null ? "" : participant.getResponse().toLowerCase(Locale.ROOT);
    return !List.of("left", "declined", "removed").contains(status)
      && !"declined".equals(response);
  }

  private void validateSettlementEligible(PlanEntity plan) {
    Instant startsAt = plan.getStartsAt();
    if (startsAt == null || Instant.now().isBefore(startsAt)) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "settlement_plan_not_eligible");
    }
  }

  private GroupEntity groupOrThrow(String groupId) {
    return groupRepository.findByPublicId(groupId)
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "group_not_found"));
  }

  private UserEntity userOrThrow(UUID userId) {
    return userRepository.findByIdAndDeletedAtIsNull(userId)
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "user_not_found"));
  }

  private UserEntity userFromParticipant(String userId, Map<String, UserEntity> participantsByUserId) {
    if (userId == null || userId.isBlank()) {
      return null;
    }
    UserEntity user = participantsByUserId.get(userId.trim());
    if (user == null) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "settlement_participant_not_found");
    }
    return user;
  }

  private UserEntity nullableParticipant(String userId, Map<String, UserEntity> participantsByUserId) {
    if (userId == null || userId.isBlank()) {
      return null;
    }
    return participantsByUserId.get(userId.trim());
  }

  private List<UserEntity> usersByUserIds(List<String> userIds, List<UserEntity> participants) {
    if (userIds == null || userIds.isEmpty()) {
      return participants;
    }
    Map<String, UserEntity> participantsByUserId = participantsByUserId(participants);
    return userIds.stream()
      .map(userId -> userFromParticipant(userId, participantsByUserId))
      .distinct()
      .sorted(Comparator.comparing(UserEntity::getPublicId))
      .toList();
  }

  private Map<String, UserEntity> participantsByUserId(List<UserEntity> participants) {
    return participants.stream().collect(Collectors.toMap(
      user -> user.getId().toString(),
      user -> user,
      (first, ignored) -> first,
      LinkedHashMap::new
    ));
  }

  private SchedulePlaceEntity schedulePlace(String schedulePlaceId, PlanEntity plan) {
    if (schedulePlaceId == null || schedulePlaceId.isBlank()) {
      return null;
    }
    return schedulePlaceRepository.findByPlanAndPublicId(plan, schedulePlaceId)
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.BAD_REQUEST, "settlement_schedule_place_not_found"));
  }

  private Set<UserEntity> settlementRecipients(List<SectionView> sections) {
    Set<UserEntity> recipients = new LinkedHashSet<>();
    for (ItemView item : itemViews(sections)) {
      recipients.add(item.payer());
      item.targets().forEach(target -> recipients.add(target.user()));
    }
    return recipients;
  }

  private Map<String, Object> settlementEventPayload(GroupEntity group, PlanEntity plan, SettlementEntity settlement) {
    return Map.of(
      "groupId", group.getPublicId(),
      "planId", plan.getPublicId(),
      "settlementId", settlement.getPublicId(),
      "settlementStatus", settlement.getStatus()
    );
  }

  private Map<String, Object> payloadFromSections(PlanEntity plan, List<SectionInput> sections, String memo) {
    return payloadFromSectionViews(
      plan,
      sections.stream()
        .map(section -> new SectionView(section.publicId(), section.schedulePlace(), section.title(), section.payer(), section.sortOrder(), section.items()))
        .toList(),
      memo
    );
  }

  private Map<String, Object> payloadFromSectionViews(PlanEntity plan, List<SectionView> sections, String memo) {
    Map<String, Object> payload = new LinkedHashMap<>();
    payload.put("sections", sections.stream().map(this::sectionCard).toList());
    payload.put("memo", memo);
    payload.put("shareMessage", plan.getTitle() + " 약속 정산입니다.");
    return payload;
  }

  private String normalizeSplitType(String value) {
    String normalized = stringOrDefault(value, "equal").toLowerCase(Locale.ROOT);
    return switch (normalized) {
      case "menu", "custom" -> "menu";
      default -> "equal";
    };
  }

  private String mySummaryLabel(MemberBalance balance) {
    if (balance == null) {
      return "내 정산 없음";
    }
    return "나는 " + resultLabel(balance.netWon());
  }

  private String resultLabel(long netWon) {
    if (netWon > 0) {
      return amountLabel(netWon) + " 받을 예정";
    }
    if (netWon < 0) {
      return amountLabel(-netWon) + " 송금";
    }
    return "정산 완료";
  }

  private String amountLabel(long amount) {
    return String.format(Locale.KOREA, "%,d원", amount);
  }

  private String profileImageUrl(UserEntity user) {
    return userAvatarReadModelMapper.profileImageUrl(user);
  }

  private String userId(UserEntity user) {
    return user == null || user.getId() == null ? "" : user.getId().toString();
  }

  private String nickname(UserEntity user) {
    return user == null ? "사용자" : stringOrDefault(user.getNickname(), "사용자");
  }

  private String memberKey(UserEntity user) {
    return user == null ? "unknown" : user.getPublicId();
  }

  private boolean sameUser(UserEntity first, UserEntity second) {
    return first != null && second != null && first.getId().equals(second.getId());
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

  private long longValue(Object value, long fallback) {
    if (value instanceof Number number) {
      return number.longValue();
    }
    if (value instanceof String string) {
      try {
        return Long.parseLong(string);
      } catch (NumberFormatException ignored) {
        return fallback;
      }
    }
    return fallback;
  }

  private String stringOrDefault(String value, String fallback) {
    return value == null || value.isBlank() ? fallback : value.trim();
  }

  private String firstString(Map<?, ?> map, String... keys) {
    for (String key : keys) {
      String value = stringOrDefault(map.get(key) == null ? null : String.valueOf(map.get(key)), null);
      if (value != null) {
        return value;
      }
    }
    return null;
  }

  private List<String> stringList(Object value) {
    if (value instanceof List<?> list) {
      return list.stream().map(String::valueOf).toList();
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

  private String toJson(Map<String, Object> payload) {
    try {
      return objectMapper.writeValueAsString(payload);
    } catch (JsonProcessingException exception) {
      throw new IllegalStateException("Could not serialize settlement payload", exception);
    }
  }

  private record SettlementAccess(GroupEntity group, PlanEntity plan, UserEntity user) {
  }

  private record SettlementAndTransfer(SettlementEntity settlement, SettlementTransferEntity transfer) {
  }

  private record SectionInput(
    String publicId,
    SchedulePlaceEntity schedulePlace,
    String title,
    UserEntity payer,
    int sortOrder,
    List<ItemView> items
  ) {
  }

  private record SectionView(
    String publicId,
    SchedulePlaceEntity schedulePlace,
    String title,
    UserEntity payer,
    int sortOrder,
    List<ItemView> items
  ) {
  }

  private record SectionFallback(
    String publicId,
    String title,
    UserEntity payer,
    int sortOrder,
    SchedulePlaceEntity schedulePlace
  ) {
    private SectionFallback(String publicId, String title, UserEntity payer, int sortOrder) {
      this(publicId, title, payer, sortOrder, null);
    }
  }

  private record ItemView(
    String publicId,
    String sectionId,
    String title,
    long amountWon,
    String splitType,
    UserEntity payer,
    List<TargetShare> targets
  ) {
  }

  private record TargetShare(UserEntity user, long amountWon) {
    private String name() {
      return user == null ? "사용자" : user.getNickname();
    }
  }

  private record TransferView(
    String publicId,
    UserEntity fromUser,
    UserEntity toUser,
    long amountWon,
    String status,
    boolean sentConfirmed,
    boolean receivedConfirmed
  ) {
    private String fromName() {
      return fromUser == null ? "사용자" : fromUser.getNickname();
    }

    private String toName() {
      return toUser == null ? "사용자" : toUser.getNickname();
    }
  }

  private static final class MemberBalance {
    private final UserEntity user;
    private long owedWon;
    private long paidWon;

    private MemberBalance(UserEntity user) {
      this.user = user;
    }

    private static MemberBalance empty(UserEntity user) {
      return new MemberBalance(user);
    }

    private MemberBalance copy() {
      MemberBalance copy = new MemberBalance(user);
      copy.owedWon = owedWon;
      copy.paidWon = paidWon;
      return copy;
    }

    private void addOwed(long amount) {
      owedWon += amount;
    }

    private void addPaid(long amount) {
      paidWon += amount;
    }

    private void reducePaid(long amount) {
      paidWon -= amount;
    }

    private UserEntity user() {
      return user;
    }

    private String userPublicId() {
      return user == null ? "" : user.getPublicId();
    }

    private long owedWon() {
      return owedWon;
    }

    private long paidWon() {
      return paidWon;
    }

    private long netWon() {
      return paidWon - owedWon;
    }
  }
}
