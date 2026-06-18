package com.onmu.api.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.onmu.api.domain.ChatActivityEventEntity;
import com.onmu.api.domain.ChatActivityEventRepository;
import com.onmu.api.domain.GroupEntity;
import com.onmu.api.domain.GroupMemberEntity;
import com.onmu.api.domain.GroupMemberRepository;
import com.onmu.api.domain.GroupRepository;
import com.onmu.api.domain.NotificationEntity;
import com.onmu.api.domain.NotificationRepository;
import com.onmu.api.domain.PlanEntity;
import com.onmu.api.domain.PlanRepository;
import com.onmu.api.domain.SettlementDraftEntity;
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
import com.onmu.api.web.dto.UpdateSettlementDraftRequest;
import com.onmu.api.web.dto.UpdateSettlementItemTargetsRequest;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
public class SettlementApiService {
  private final GroupRepository groupRepository;
  private final PlanRepository planRepository;
  private final UserRepository userRepository;
  private final SettlementDraftRepository settlementDraftRepository;
  private final SettlementRepository settlementRepository;
  private final SettlementItemRepository settlementItemRepository;
  private final SettlementItemTargetRepository settlementItemTargetRepository;
  private final SettlementTransferRepository settlementTransferRepository;
  private final ChatActivityEventRepository chatActivityEventRepository;
  private final GroupMemberRepository groupMemberRepository;
  private final NotificationRepository notificationRepository;
  private final OutboxService outboxService;
  private final ObjectMapper objectMapper;

  public SettlementApiService(
    GroupRepository groupRepository,
    PlanRepository planRepository,
    UserRepository userRepository,
    SettlementDraftRepository settlementDraftRepository,
    SettlementRepository settlementRepository,
    SettlementItemRepository settlementItemRepository,
    SettlementItemTargetRepository settlementItemTargetRepository,
    SettlementTransferRepository settlementTransferRepository,
    ChatActivityEventRepository chatActivityEventRepository,
    GroupMemberRepository groupMemberRepository,
    NotificationRepository notificationRepository,
    OutboxService outboxService,
    ObjectMapper objectMapper
  ) {
    this.groupRepository = groupRepository;
    this.planRepository = planRepository;
    this.userRepository = userRepository;
    this.settlementDraftRepository = settlementDraftRepository;
    this.settlementRepository = settlementRepository;
    this.settlementItemRepository = settlementItemRepository;
    this.settlementItemTargetRepository = settlementItemTargetRepository;
    this.settlementTransferRepository = settlementTransferRepository;
    this.chatActivityEventRepository = chatActivityEventRepository;
    this.groupMemberRepository = groupMemberRepository;
    this.notificationRepository = notificationRepository;
    this.outboxService = outboxService;
    this.objectMapper = objectMapper;
  }

  @Transactional(readOnly = true)
  public Map<String, Object> settlementDraft(String groupId, String planId, UUID userId) {
    GroupAccess access = memberGroup(groupId, userId);
    PlanEntity plan = planOrThrow(access.group(), planId);
    return settlementDraftRepository.findByPlan(plan)
      .map(draft -> settlementDraftCard(draft, true, access.user()))
      .orElseGet(() -> settlementDraftCard(
        new SettlementDraftEntity("draft", plan.getGroup(), plan, defaultDraftPayload(plan)),
        false,
        access.user()
      ));
  }

  @Transactional
  public Map<String, Object> updateSettlementDraft(
    String groupId,
    String planId,
    UUID userId,
    UpdateSettlementDraftRequest request
  ) {
    GroupAccess access = memberGroup(groupId, userId);
    GroupEntity group = access.group();
    PlanEntity plan = planOrThrow(group, planId);
    List<SettlementDraftItemRequest> items = requireItems(request.items());
    SettlementDraftEntity draft = settlementDraftRepository.findByPlan(plan)
      .orElseGet(() -> new SettlementDraftEntity(
        nextPublicId(settlementDraftRepository.findAll().stream()
          .map(SettlementDraftEntity::getPublicId)
          .toList(), 301),
        group,
        plan,
        defaultDraftPayload(plan)
      ));

    List<ItemInput> itemInputs = itemInputs(items, access.user());
    List<SettlementItemEntity> previousItems = settlementItemRepository.findBySettlementDraft(draft);
    Set<String> reusableIds = previousItems.stream()
      .map(SettlementItemEntity::getPublicId)
      .collect(Collectors.toSet());
    List<ItemView> itemViews = allocateItemViews(itemInputs, settlementItemRepository.findAll().stream()
      .map(SettlementItemEntity::getPublicId)
      .toList(), reusableIds);
    draft.setPayload(toJson(payloadFromItemViews(plan, itemViews, stringOrDefault(request.memo(), "Spring settlement draft"))));
    SettlementDraftEntity savedDraft = settlementDraftRepository.save(draft);
    replaceDraftItems(savedDraft, previousItems, itemViews);
    return settlementDraftCard(savedDraft, true, access.user());
  }

  @Transactional
  public Map<String, Object> updateSettlementDraftItemTargets(
    String groupId,
    String planId,
    String itemId,
    UUID userId,
    UpdateSettlementItemTargetsRequest request
  ) {
    GroupAccess access = memberGroup(groupId, userId);
    PlanEntity plan = planOrThrow(access.group(), planId);
    SettlementDraftEntity draft = settlementDraftRepository.findByPlan(plan)
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "settlement_draft_not_found"));
    SettlementItemEntity item = settlementItemRepository.findBySettlementDraftAndPublicId(draft, itemId)
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "settlement_item_not_found"));
    List<UserEntity> targets = usersByRefs(request.targetUserIds(), request.targetNames());
    settlementItemTargetRepository.deleteBySettlementItem(item);
    List<Long> targetAmounts = splitAmount(item.getAmountCents(), targets.size());
    for (int index = 0; index < targets.size(); index++) {
      settlementItemTargetRepository.save(new SettlementItemTargetEntity(item, targets.get(index), targetAmounts.get(index)));
    }
    draft.setPayload(toJson(payloadFromItemViews(plan, itemViewsForDraft(draft, access.user()), "Spring settlement draft")));
    return settlementDraftCard(draft, true, access.user());
  }

  @Transactional(readOnly = true)
  public Map<String, Object> previewSettlement(
    String groupId,
    String planId,
    UUID userId,
    SettlementPreviewRequest request
  ) {
    GroupAccess access = memberGroup(groupId, userId);
    PlanEntity plan = planOrThrow(access.group(), planId);
    List<ItemView> itemViews = allocateItemViews(itemInputs(requireItems(request.items()), access.user()), List.of(), Set.of());
    return settlementSummaryCard("preview", plan, itemViews, calculateTransfers(itemViews), true, access.user());
  }

  @Transactional
  public Map<String, Object> createSettlement(
    String groupId,
    String planId,
    UUID userId,
    SettlementPreviewRequest request
  ) {
    GroupAccess access = memberGroup(groupId, userId);
    GroupEntity group = access.group();
    PlanEntity plan = planOrThrow(group, planId);
    List<ItemInput> itemInputs = itemInputs(requireItems(request.items()), access.user());
    String publicId = nextPublicId(settlementRepository.findAll().stream()
      .map(SettlementEntity::getPublicId)
      .toList(), 301);
    List<ItemView> itemViews = allocateItemViews(itemInputs, settlementItemRepository.findAll().stream()
      .map(SettlementItemEntity::getPublicId)
      .toList(), Set.of());
    SettlementEntity settlement = settlementRepository.save(new SettlementEntity(
      publicId,
      group,
      plan,
      toJson(payloadFromItemViews(plan, itemViews, "Spring settlement created"))
    ));
    saveSettlementItems(settlement, itemViews);
    List<TransferView> transfers = calculateTransfers(itemViews);
    for (TransferView transfer : transfers) {
      settlementTransferRepository.save(new SettlementTransferEntity(
        settlement,
        transfer.fromUser(),
        transfer.toUser(),
        transfer.amountCents(),
        transfer.fromName() + " -> " + transfer.toName()
      ));
    }
    createSettlementSideEffects(group, plan, settlement, itemViews, transfers, access.user());
    outboxService.record("settlement.created", "settlement", settlement.getId(), Map.of(
      "groupId", group.getPublicId(),
      "planId", plan.getPublicId(),
      "settlementId", settlement.getPublicId()
    ));
    return settlementSummaryCard(settlement.getPublicId(), plan, itemViews, transfers, false, access.user());
  }

  private void createSettlementSideEffects(
    GroupEntity group,
    PlanEntity plan,
    SettlementEntity settlement,
    List<ItemView> itemViews,
    List<TransferView> transfers,
    UserEntity actor
  ) {
    Map<String, Object> activityPayload = settlementActivityPayload(plan, settlement, itemViews, transfers);
    chatActivityEventRepository.save(new ChatActivityEventEntity(
      group,
      plan,
      actor,
      "settlement.created",
      toJson(activityPayload),
      Instant.now()
    ));

    Map<UUID, UserEntity> recipients = settlementRecipients(group, itemViews);
    if (recipients.isEmpty()) {
      return;
    }

    Instant createdAt = Instant.now();
    String notificationPayload = toJson(Map.of(
      "groupId", group.getPublicId(),
      "planId", plan.getPublicId(),
      "settlementId", settlement.getPublicId(),
      "notificationType", "settlement_created"
    ));
    for (UserEntity recipient : recipients.values()) {
      NotificationEntity notification = notificationRepository.save(new NotificationEntity(
        recipient,
        group,
        plan,
        "settlement_created",
        plan.getTitle() + " 정산이 만들어졌어요",
        "약속 정산 결과를 확인해 주세요.",
        notificationPayload,
        "queued",
        null,
        createdAt
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

  private Map<String, Object> settlementActivityPayload(
    PlanEntity plan,
    SettlementEntity settlement,
    List<ItemView> itemViews,
    List<TransferView> transfers
  ) {
    Map<String, Object> payload = new LinkedHashMap<>();
    payload.put("senderName", "ONMU");
    payload.put("message", plan.getTitle() + " 정산이 만들어졌어요.");
    payload.put("messageType", "settlement_card");
    payload.put("cardType", "settlement");
    payload.put("planId", plan.getPublicId());
    payload.put("settlementId", settlement.getPublicId());
    payload.put("itemCount", itemViews.size());
    payload.put("transferCount", transfers.size());
    payload.put("totalAmountLabel", amountLabel(itemViews.stream().map(ItemView::amountCents).reduce(0L, Long::sum)));
    payload.put("source", "spring_api");
    return payload;
  }

  private Map<UUID, UserEntity> settlementRecipients(GroupEntity group, List<ItemView> itemViews) {
    Map<UUID, UserEntity> recipients = new LinkedHashMap<>();
    for (ItemView itemView : itemViews) {
      for (PayerShare payerShare : itemView.payerShares()) {
        putRecipient(recipients, payerShare.user());
      }
      for (TargetShare targetShare : itemView.targets()) {
        putRecipient(recipients, targetShare.user());
      }
    }
    if (!recipients.isEmpty()) {
      return recipients;
    }
    for (GroupMemberEntity member : groupMemberRepository.findByGroupOrderByJoinedAtAsc(group)) {
      if (member.getLeftAt() == null && !"left".equals(member.getStatus())) {
        putRecipient(recipients, member.getUser());
      }
    }
    putRecipient(recipients, group.getOwnerUser());
    return recipients;
  }

  private void putRecipient(Map<UUID, UserEntity> recipients, UserEntity user) {
    if (user == null || user.getId() == null) {
      return;
    }
    recipients.putIfAbsent(user.getId(), user);
  }

  @Transactional(readOnly = true)
  public Map<String, Object> settlement(String groupId, String planId, UUID userId) {
    GroupAccess access = memberGroup(groupId, userId);
    PlanEntity plan = planOrThrow(access.group(), planId);
    return settlementRepository.findFirstByPlanOrderByCreatedAtDesc(plan)
      .map(settlement -> settlementCard(settlement, false, access.user()))
      .orElseGet(() -> {
        SettlementDraftEntity draft = settlementDraftRepository.findByPlan(plan)
          .orElseGet(() -> new SettlementDraftEntity("draft", plan.getGroup(), plan, defaultDraftPayload(plan)));
        return settlementSummaryCard("draft", plan, itemViewsForDraft(draft, access.user()), List.of(), true, access.user());
      });
  }

  @Transactional(readOnly = true)
  public Map<String, Object> settlementById(String groupId, String planId, String settlementId, UUID userId) {
    GroupAccess access = memberGroup(groupId, userId);
    PlanEntity plan = planOrThrow(access.group(), planId);
    SettlementEntity settlement = settlementRepository.findByPlanAndPublicId(plan, settlementId)
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "settlement_not_found"));
    return settlementCard(settlement, false, access.user());
  }

  private Map<String, Object> settlementCard(SettlementEntity settlement, boolean preview, UserEntity currentUser) {
    List<ItemView> itemViews = itemViewsForSettlement(settlement, currentUser);
    List<TransferView> transfers = transferViews(settlement);
    if (transfers.isEmpty()) {
      transfers = calculateTransfers(itemViews);
    }
    return settlementSummaryCard(settlement.getPublicId(), settlement.getPlan(), itemViews, transfers, preview, currentUser);
  }

  private Map<String, Object> settlementDraftCard(
    SettlementDraftEntity draft,
    boolean persisted,
    UserEntity currentUser
  ) {
    List<ItemView> itemViews = itemViewsForDraft(draft, currentUser);
    Map<String, Object> payload = readObject(draft.getPayload());
    Map<String, Object> value = new LinkedHashMap<>();
    value.put("id", draft.getPublicId());
    value.put("groupId", draft.getGroup().getPublicId());
    value.put("planId", draft.getPlan().getPublicId());
    value.put("persisted", persisted);
    value.put("targetPatchAvailable", persisted && !itemViews.isEmpty());
    value.put("items", itemViews.stream().map(this::draftItemCard).toList());
    value.put("memo", stringOrDefault(asString(payload.get("memo")), ""));
    value.put(
      "preview",
      settlementSummaryCard("preview", draft.getPlan(), itemViews, calculateTransfers(itemViews), true, currentUser)
    );
    return value;
  }

  private Map<String, Object> settlementSummaryCard(
    String publicId,
    PlanEntity plan,
    List<ItemView> itemViews,
    List<TransferView> transferViews,
    boolean preview,
    UserEntity currentUser
  ) {
    long totalAmount = itemViews.stream().map(ItemView::amountCents).reduce(0L, Long::sum);
    Map<String, MemberBalance> balances = memberBalances(itemViews);
    Set<String> memberKeys = new LinkedHashSet<>(balances.keySet());
    transferViews.forEach(transfer -> {
      memberKeys.add(memberKey(transfer.fromUser(), transfer.fromName()));
      memberKeys.add(memberKey(transfer.toUser(), transfer.toName()));
    });
    int targetCount = memberKeys.isEmpty() ? 1 : memberKeys.size();
    long averageAmount = targetCount == 0 ? 0 : Math.round((double) totalAmount / targetCount);

    Map<String, Object> value = new LinkedHashMap<>();
    value.put("id", publicId);
    value.put("planId", plan.getPublicId());
    value.put("planTitle", plan.getTitle());
    value.put("preview", preview);
    value.put("totalAmount", totalAmount);
    value.put("totalAmountLabel", amountLabel(totalAmount));
    value.put("createdDateLabel", preview ? "미리보기" : "정산 생성됨");
    value.put("itemCountLabel", "결제 항목 " + itemViews.size() + "개");
    value.put("finalSummaryLabel", targetCount + "명 기준 " + amountLabel(averageAmount));
    String currentUserKey = memberKey(currentUser, currentUser.getDisplayName());
    value.put("mySummaryLabel", mySummaryLabel(balances.get(currentUserKey)));
    value.put("paymentItems", itemViews.stream().map(this::paymentItemCard).toList());
    value.put("memberResults", memberKeys.stream()
      .map(key -> memberResultCard(balances.getOrDefault(key, MemberBalance.empty(key, key)), currentUserKey))
      .toList());
    value.put("transfers", transferViews.stream().map(this::transferCard).toList());
    value.put("shareMessage", plan.getTitle() + " 약속 정산입니다.");
    return value;
  }

  private Map<String, Object> draftItemCard(ItemView item) {
    Map<String, Object> value = new LinkedHashMap<>();
    value.put("id", item.publicId());
    value.put("title", item.title());
    value.put("amount", item.amountCents());
    value.put("amountWon", item.amountCents());
    value.put("amountLabel", amountLabel(item.amountCents()));
    value.put("payerUserId", item.payerShares().isEmpty() ? null : item.payerShares().get(0).userId());
    value.put("payerName", item.payerShares().isEmpty() ? "결제자" : item.payerShares().get(0).name());
    value.put("payerShares", item.payerShares().stream().map(this::payerShareCard).toList());
    value.put("splitType", item.splitType());
    value.put("targetUserIds", item.targets().stream().map(TargetShare::userId).toList());
    value.put("targetNames", item.targets().stream().map(TargetShare::name).toList());
    value.put("participants", item.targets().stream().map(target -> Map.of(
      "name", target.name(),
      "userId", target.userId(),
      "amount", target.amountCents(),
      "owedAmountLabel", amountLabel(target.amountCents()),
      "included", true
    )).toList());
    return value;
  }

  private Map<String, Object> paymentItemCard(ItemView item) {
    Map<String, Object> value = new LinkedHashMap<>();
    value.put("id", item.publicId());
    value.put("title", item.title());
    value.put("amount", item.amountCents());
    value.put("amountWon", item.amountCents());
    value.put("amountLabel", amountLabel(item.amountCents()));
    value.put("payerShares", item.payerShares().stream().map(this::payerShareCard).toList());
    value.put("targetLabel", item.targets().size() + "명");
    value.put("splitType", item.splitType());
    value.put("participants", item.targets().stream().map(target -> Map.of(
      "name", target.name(),
      "userId", target.userId(),
      "owedAmountLabel", amountLabel(target.amountCents()),
      "included", true
    )).toList());
    return value;
  }

  private Map<String, Object> payerShareCard(PayerShare payerShare) {
    return Map.of(
      "userId", payerShare.userId(),
      "name", payerShare.name(),
      "amountLabel", amountLabel(payerShare.amountCents())
    );
  }

  private Map<String, Object> memberResultCard(MemberBalance balance, String currentUserKey) {
    long net = balance.paidCents() - balance.owedCents();
    Map<String, Object> value = new LinkedHashMap<>();
    value.put("userId", balance.userId());
    value.put("name", balance.name());
    value.put("finalShareLabel", amountLabel(balance.owedCents()));
    value.put("paidAmountLabel", balance.paidCents() == 0 ? "0원" : amountLabel(balance.paidCents()));
    value.put("resultLabel", resultLabel(net));
    value.put("isMe", currentUserKey.equals(balance.memberKey()));
    value.put("willReceive", net > 0);
    return value;
  }

  private Map<String, Object> transferCard(TransferView transfer) {
    return Map.of(
      "fromName", transfer.fromName(),
      "toName", transfer.toName(),
      "amountLabel", amountLabel(transfer.amountCents())
    );
  }

  private List<ItemView> itemViewsForDraft(SettlementDraftEntity draft, UserEntity currentUser) {
    List<SettlementItemEntity> items = settlementItemRepository.findBySettlementDraftOrderByCreatedAtAsc(draft);
    if (!items.isEmpty()) {
      return itemViews(items, payerSharesByItemId(draft.getPayload()));
    }
    return itemViewsFromPayload(draft.getPlan(), draft.getPayload(), currentUser);
  }

  private List<ItemView> itemViewsForSettlement(SettlementEntity settlement, UserEntity currentUser) {
    List<SettlementItemEntity> items = settlementItemRepository.findBySettlementOrderByCreatedAtAsc(settlement);
    if (!items.isEmpty()) {
      return itemViews(items, payerSharesByItemId(settlement.getPayload()));
    }
    return itemViewsFromPayload(settlement.getPlan(), settlement.getPayload(), currentUser);
  }

  private List<ItemView> itemViews(
    List<SettlementItemEntity> items,
    Map<String, List<PayerShare>> payerSharesByItemId
  ) {
    Map<UUID, List<SettlementItemTargetEntity>> targetsByItem =
      settlementItemTargetRepository.findBySettlementItemInOrderByCreatedAtAsc(items).stream()
        .collect(Collectors.groupingBy(
          target -> target.getSettlementItem().getId(),
          LinkedHashMap::new,
          Collectors.toList()
        ));
    return items.stream()
      .map(item -> itemView(
        item,
        targetsByItem.getOrDefault(item.getId(), List.of()),
        payerSharesByItemId.getOrDefault(item.getPublicId(), List.of())
      ))
      .toList();
  }

  private ItemView itemView(
    SettlementItemEntity item,
    List<SettlementItemTargetEntity> targets,
    List<PayerShare> payerShares
  ) {
    List<TargetShare> targetShares = targets.stream()
      .map(target -> new TargetShare(
        target.getUser(),
        target.getUser().getDisplayName(),
        target.getAmountCents() == null ? 0 : target.getAmountCents()
      ))
      .toList();
    return new ItemView(
      item.getPublicId(),
      item.getTitle(),
      item.getAmountCents(),
      item.getSplitType(),
      payerShares,
      targetShares
    );
  }

  private List<ItemView> itemViewsFromPayload(PlanEntity plan, String payload, UserEntity currentUser) {
    Object rawItems = readObject(payload).get("items");
    if (!(rawItems instanceof List<?> items) || items.isEmpty()) {
      return defaultItemViews(plan);
    }
    List<SettlementDraftItemRequest> requests = new ArrayList<>();
    for (Object item : items) {
      if (item instanceof Map<?, ?> map) {
        requests.add(new SettlementDraftItemRequest(
          stringOrDefault(asString(map.get("id")), null),
          stringOrDefault(asString(map.get("title")), "결제 항목"),
          intValue(map.get("amount"), 0),
          intValue(map.get("amountWon"), intValue(map.get("amount"), 0)),
          stringOrDefault(asString(map.get("payerUserId")), null),
          stringOrDefault(asString(map.get("payerName")), currentUser.getDisplayName()),
          stringOrDefault(asString(map.get("splitType")), "equal"),
          stringList(map.get("targetUserIds")),
          stringList(map.get("targetNames"))
        ));
      }
    }
    return itemInputs(requests, currentUser).stream().map(input -> input.toView(input.publicId())).toList();
  }

  private List<ItemView> defaultItemViews(PlanEntity plan) {
    return List.of();
  }

  private void saveSettlementItems(SettlementEntity settlement, List<ItemView> itemViews) {
    for (ItemView itemView : itemViews) {
      SettlementItemEntity item = settlementItemRepository.save(new SettlementItemEntity(
        null,
        settlement,
        itemView.publicId(),
        itemView.title(),
        itemView.amountCents(),
        itemView.splitType(),
        null
      ));
      saveTargets(item, itemView.targets());
    }
  }

  private void replaceDraftItems(
    SettlementDraftEntity draft,
    List<SettlementItemEntity> previousItems,
    List<ItemView> itemViews
  ) {
    if (!previousItems.isEmpty()) {
      settlementItemTargetRepository.deleteBySettlementItemIn(previousItems);
      settlementItemRepository.deleteBySettlementDraft(draft);
    }
    for (ItemView itemView : itemViews) {
      SettlementItemEntity item = settlementItemRepository.save(new SettlementItemEntity(
        draft,
        null,
        itemView.publicId(),
        itemView.title(),
        itemView.amountCents(),
        itemView.splitType(),
        null
      ));
      saveTargets(item, itemView.targets());
    }
  }

  private void saveTargets(SettlementItemEntity item, List<TargetShare> targets) {
    for (TargetShare target : targets) {
      settlementItemTargetRepository.save(new SettlementItemTargetEntity(item, target.user(), target.amountCents()));
    }
  }

  private List<ItemView> allocateItemViews(
    List<ItemInput> itemInputs,
    List<String> usedPublicIds,
    Set<String> reusableIds
  ) {
    IdAllocator idAllocator = new IdAllocator(usedPublicIds, reusableIds, 401);
    return itemInputs.stream()
      .map(input -> input.toView(idAllocator.allocate(input.requestedId())))
      .toList();
  }

  private Map<String, List<PayerShare>> payerSharesByItemId(String payload) {
    Map<String, List<PayerShare>> payerSharesByItemId = new LinkedHashMap<>();
    Object rawItems = readObject(payload).get("items");
    if (!(rawItems instanceof List<?> items)) {
      return payerSharesByItemId;
    }
    for (Object item : items) {
      if (item instanceof Map<?, ?> map) {
        String itemId = stringOrDefault(asString(map.get("id")), null);
        if (itemId == null) {
          continue;
        }
        Object rawPayerShares = map.get("payerShares");
        if (rawPayerShares instanceof List<?> payerShareItems) {
          List<PayerShare> payerShares = payerSharesFromPayload(payerShareItems);
          if (!payerShares.isEmpty()) {
            payerSharesByItemId.put(itemId, payerShares);
          }
          continue;
        }
        String payerUserId = firstString(map, "payerUserId", "userId", "publicId", "memberId");
        String payerName = firstString(map, "payerName", "name", "displayName");
        if (payerUserId == null && payerName == null) {
          continue;
        }
        long amount = longValue(map.get("amountWon"), longValue(map.get("amount"), 0));
        UserEntity payer = userByRef(payerUserId, payerName);
        payerSharesByItemId.put(itemId, List.of(new PayerShare(payer, payer.getDisplayName(), amount)));
      }
    }
    return payerSharesByItemId;
  }

  private List<PayerShare> payerSharesFromPayload(List<?> payerShareItems) {
    List<PayerShare> payerShares = new ArrayList<>();
    for (Object item : payerShareItems) {
      if (item instanceof Map<?, ?> map) {
        String payerUserId = firstString(map, "payerUserId", "userId", "publicId", "memberId");
        String payerName = firstString(map, "payerName", "name", "displayName");
        UserEntity payer = userByRef(payerUserId, payerName);
        long amount = longValue(map.get("amountWon"), longValue(map.get("amount"), 0));
        payerShares.add(new PayerShare(payer, payer.getDisplayName(), amount));
      }
    }
    return payerShares;
  }

  private List<TransferView> transferViews(SettlementEntity settlement) {
    return settlementTransferRepository.findBySettlementOrderByCreatedAtAsc(settlement).stream()
      .map(transfer -> new TransferView(
        transfer.getFromUser(),
        transfer.getFromUser().getDisplayName(),
        transfer.getToUser(),
        transfer.getToUser().getDisplayName(),
        transfer.getAmountCents()
      ))
      .toList();
  }

  private List<TransferView> calculateTransfers(List<ItemView> itemViews) {
    Map<String, MemberBalance> balances = memberBalances(itemViews);
    List<MemberBalance> debtors = balances.values().stream()
      .filter(balance -> balance.netCents() < 0)
      .map(MemberBalance::copy)
      .sorted(Comparator.comparing(MemberBalance::name))
      .toList();
    List<MemberBalance> creditors = balances.values().stream()
      .filter(balance -> balance.netCents() > 0)
      .map(MemberBalance::copy)
      .sorted(Comparator.comparing(MemberBalance::name))
      .toList();

    List<TransferView> transfers = new ArrayList<>();
    int creditorIndex = 0;
    for (MemberBalance debtor : debtors) {
      long debt = -debtor.netCents();
      while (debt > 0 && creditorIndex < creditors.size()) {
        MemberBalance creditor = creditors.get(creditorIndex);
        long receivable = creditor.netCents();
        long amount = Math.min(debt, receivable);
        if (debtor.user() != null && creditor.user() != null && amount > 0) {
          transfers.add(new TransferView(
            debtor.user(),
            debtor.name(),
            creditor.user(),
            creditor.name(),
            amount
          ));
        }
        debt -= amount;
        creditor.reducePaid(amount);
        if (creditor.netCents() == 0) {
          creditorIndex++;
        }
      }
    }
    return transfers;
  }

  private Map<String, MemberBalance> memberBalances(List<ItemView> itemViews) {
    Map<String, MemberBalance> balances = new LinkedHashMap<>();
    for (ItemView item : itemViews) {
      for (TargetShare target : item.targets()) {
        String key = memberKey(target.user(), target.name());
        balances.computeIfAbsent(key, ignored -> MemberBalance.empty(key, target.user(), target.name()))
          .addOwed(target.amountCents());
      }
      for (PayerShare payer : item.payerShares()) {
        String key = memberKey(payer.user(), payer.name());
        balances.computeIfAbsent(key, ignored -> MemberBalance.empty(key, payer.user(), payer.name()))
          .addPaid(payer.amountCents());
      }
    }
    return balances;
  }

  private List<ItemInput> itemInputs(List<SettlementDraftItemRequest> requests, UserEntity currentUser) {
    return requests.stream().map(request -> itemInput(request, currentUser)).toList();
  }

  private ItemInput itemInput(SettlementDraftItemRequest request, UserEntity currentUser) {
    String payerName = stringOrDefault(request.payerName(), currentUser.getDisplayName());
    UserEntity payer = userByRef(request.payerUserId(), payerName);
    List<String> targetNames = request.targetNames() == null || request.targetNames().isEmpty()
      ? List.of(payer.getDisplayName())
      : request.targetNames();
    List<String> targetUserIds = request.targetUserIds() == null || request.targetUserIds().isEmpty()
      ? List.of()
      : request.targetUserIds();
    List<UserEntity> targets = usersByRefs(targetUserIds, targetNames);
    long amount = request.amountWon() == null
      ? request.amount() == null ? 0 : request.amount()
      : request.amountWon();
    if (amount < 0) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "invalid_settlement_amount");
    }
    List<Long> targetAmounts = splitAmount(amount, targets.size());
    List<TargetShare> targetShares = new ArrayList<>();
    for (int index = 0; index < targets.size(); index++) {
      UserEntity target = targets.get(index);
      targetShares.add(new TargetShare(target, target.getDisplayName(), targetAmounts.get(index)));
    }
    return new ItemInput(
      stringOrDefault(request.id(), null),
      stringOrDefault(request.title(), "결제 항목"),
      amount,
      normalizeSplitType(request.splitType()),
      List.of(new PayerShare(payer, payer.getDisplayName(), amount)),
      targetShares
    );
  }

  private List<SettlementDraftItemRequest> requireItems(List<SettlementDraftItemRequest> items) {
    if (items == null || items.isEmpty()) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "missing_settlement_items");
    }
    return items;
  }

  private UserEntity userByRef(String publicId, String displayName) {
    return usersByRefs(
      publicId == null || publicId.isBlank() ? List.of() : List.of(publicId),
      displayName == null || displayName.isBlank() ? List.of() : List.of(displayName)
    ).get(0);
  }

  private List<UserEntity> usersByRefs(List<String> publicIds, List<String> names) {
    List<String> normalizedPublicIds = publicIds == null ? List.of() : publicIds.stream()
      .map(id -> stringOrDefault(id, ""))
      .filter(id -> !id.isBlank())
      .distinct()
      .toList();
    if (!normalizedPublicIds.isEmpty()) {
      Map<String, UserEntity> usersByPublicId = new LinkedHashMap<>();
      for (UserEntity user : userRepository.findByPublicIdIn(normalizedPublicIds)) {
        usersByPublicId.put(user.getPublicId(), user);
      }
      List<UserEntity> users = new ArrayList<>();
      for (String publicId : normalizedPublicIds) {
        UserEntity user = usersByPublicId.get(publicId);
        if (user == null) {
          throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "settlement_member_not_found");
        }
        users.add(user);
      }
      return users;
    }
    return usersByNamesFallback(names);
  }

  private List<UserEntity> usersByNamesFallback(List<String> names) {
    List<String> normalizedNames = names == null ? List.of() : names.stream()
      .map(name -> stringOrDefault(name, ""))
      .filter(name -> !name.isBlank())
      .distinct()
      .toList();
    if (normalizedNames.isEmpty()) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "missing_settlement_item_targets");
    }
    Map<String, List<UserEntity>> usersByName = userRepository.findByDisplayNameIn(normalizedNames).stream()
      .collect(Collectors.groupingBy(
        UserEntity::getDisplayName,
        LinkedHashMap::new,
        Collectors.toList()
      ));
    List<UserEntity> users = new ArrayList<>();
    for (String name : normalizedNames) {
      List<UserEntity> matches = usersByName.getOrDefault(name, List.of());
      if (matches.isEmpty()) {
        throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "settlement_member_not_found");
      }
      if (matches.size() > 1) {
        throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "ambiguous_settlement_member_name");
      }
      users.add(matches.get(0));
    }
    return users;
  }

  private List<Long> splitAmount(long amount, int targetCount) {
    if (targetCount <= 0) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "missing_settlement_item_targets");
    }
    long base = amount / targetCount;
    long remainder = amount % targetCount;
    List<Long> values = new ArrayList<>();
    for (int index = 0; index < targetCount; index++) {
      values.add(base + (index < remainder ? 1 : 0));
    }
    return values;
  }

  private GroupEntity groupOrThrow(String groupId) {
    return groupRepository.findByPublicId(groupId)
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "group_not_found"));
  }

  private GroupAccess memberGroup(String groupId, UUID userId) {
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

  private UserEntity userOrThrow(UUID userId) {
    return userRepository.findByIdAndDeletedAtIsNull(userId)
      .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "user_not_found"));
  }

  private String memberKey(UserEntity user, String fallbackName) {
    if (user != null && user.getPublicId() != null && !user.getPublicId().isBlank()) {
      return user.getPublicId();
    }
    return "name:" + stringOrDefault(fallbackName, "unknown");
  }

  private String normalizeSplitType(String value) {
    String splitType = stringOrDefault(value, "equal").toLowerCase(Locale.ROOT);
    return "custom".equals(splitType) ? "custom" : "equal";
  }

  private Map<String, Object> payloadFromItemViews(PlanEntity plan, List<ItemView> itemViews, String memo) {
    Map<String, Object> payload = new LinkedHashMap<>();
    payload.put("items", itemViews.stream().map(this::draftItemCard).toList());
    payload.put("memo", memo);
    payload.put("shareMessage", plan.getTitle() + " 약속 정산입니다.");
    return payload;
  }

  private String defaultDraftPayload(PlanEntity plan) {
    return toJson(payloadFromItemViews(plan, defaultItemViews(plan), "Spring settlement draft"));
  }

  private String mySummaryLabel(MemberBalance currentUserBalance) {
    if (currentUserBalance == null) {
      return "내 정산 없음";
    }
    long net = currentUserBalance.paidCents() - currentUserBalance.owedCents();
    if (net > 0) {
      return "나는 " + amountLabel(net) + " 받을 예정";
    }
    if (net < 0) {
      return "나는 " + amountLabel(-net) + " 송금";
    }
    return "나는 정산 완료";
  }

  private String resultLabel(long netCents) {
    if (netCents > 0) {
      return "정산 받을 예정";
    }
    if (netCents < 0) {
      return amountLabel(-netCents) + " 송금";
    }
    return "정산 완료";
  }

  private String amountLabel(long amount) {
    return String.format(Locale.KOREA, "%,d원", amount);
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

  private int intValue(Object value, int fallback) {
    return (int) longValue(value, fallback);
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

  private String asString(Object value) {
    return value == null ? null : String.valueOf(value);
  }

  private String firstString(Map<?, ?> map, String... keys) {
    for (String key : keys) {
      String value = stringOrDefault(asString(map.get(key)), null);
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

  private record ItemInput(
    String requestedId,
    String title,
    long amountCents,
    String splitType,
    List<PayerShare> payerShares,
    List<TargetShare> targets
  ) {
    String publicId() {
      return requestedId == null || requestedId.isBlank() ? "draft" : requestedId;
    }

    ItemView toView(String publicId) {
      return new ItemView(publicId, title, amountCents, splitType, payerShares, targets);
    }
  }

  private record ItemView(
    String publicId,
    String title,
    long amountCents,
    String splitType,
    List<PayerShare> payerShares,
    List<TargetShare> targets
  ) {
  }

  private record PayerShare(UserEntity user, String name, long amountCents) {
    private String userId() {
      return user == null ? null : user.getPublicId();
    }
  }

  private record TargetShare(UserEntity user, String name, long amountCents) {
    private String userId() {
      return user == null ? null : user.getPublicId();
    }
  }

  private record TransferView(
    UserEntity fromUser,
    String fromName,
    UserEntity toUser,
    String toName,
    long amountCents
  ) {
  }

  private record GroupAccess(GroupEntity group, UserEntity user) {
  }

  private static final class MemberBalance {
    private final UserEntity user;
    private final String memberKey;
    private final String name;
    private long owedCents;
    private long paidCents;

    private MemberBalance(UserEntity user, String memberKey, String name, long owedCents, long paidCents) {
      this.user = user;
      this.memberKey = memberKey;
      this.name = name;
      this.owedCents = owedCents;
      this.paidCents = paidCents;
    }

    private static MemberBalance empty(String memberKey, String name) {
      return new MemberBalance(null, memberKey, name, 0, 0);
    }

    private static MemberBalance empty(String memberKey, UserEntity user, String name) {
      return new MemberBalance(user, memberKey, name, 0, 0);
    }

    private MemberBalance copy() {
      return new MemberBalance(user, memberKey, name, owedCents, paidCents);
    }

    private void addOwed(long amount) {
      owedCents += amount;
    }

    private void addPaid(long amount) {
      paidCents += amount;
    }

    private void reducePaid(long amount) {
      paidCents -= amount;
    }

    private UserEntity user() {
      return user;
    }

    private String userId() {
      return user == null ? null : user.getPublicId();
    }

    private String memberKey() {
      return memberKey;
    }

    private String name() {
      return name;
    }

    private long owedCents() {
      return owedCents;
    }

    private long paidCents() {
      return paidCents;
    }

    private long netCents() {
      return paidCents - owedCents;
    }
  }

  private final class IdAllocator {
    private final Set<String> used;
    private final Set<String> reusable;
    private int next;

    private IdAllocator(List<String> used, int fallbackStart) {
      this(used, Set.of(), fallbackStart);
    }

    private IdAllocator(List<String> used, Set<String> reusable, int fallbackStart) {
      this.used = new LinkedHashSet<>(used);
      this.reusable = reusable;
      this.next = used.stream()
        .map(SettlementApiService.this::tryParseInt)
        .flatMap(List::stream)
        .max(Comparator.naturalOrder())
        .orElse(fallbackStart - 1) + 1;
    }

    private String allocate(String requestedId) {
      if (requestedId != null && !requestedId.isBlank()) {
        String normalized = requestedId.trim();
        if (reusable.contains(normalized) || !used.contains(normalized)) {
          used.add(normalized);
          return normalized;
        }
      }
      String candidate = Integer.toString(next);
      while (used.contains(candidate)) {
        next++;
        candidate = Integer.toString(next);
      }
      used.add(candidate);
      next++;
      return candidate;
    }
  }
}
