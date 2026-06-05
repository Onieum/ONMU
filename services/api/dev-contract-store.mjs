function parseId(value) {
  return Number.parseInt(String(value), 10) || 0;
}

function firstOrThrow(items, message) {
  if (!items.length) {
    throw new Error(message);
  }
  return items[0];
}

function planMembers() {
  return [
    { name: "연우", message: "가고싶다 했어요!", badge: "방문지 제안", selected: false },
    { name: "지영", message: "카페 투어 좋아해요", badge: "선택됨", selected: true },
    { name: "민수", message: "이번엔 내가 추천할게!", badge: "시간 제안", selected: true },
    { name: "준호", message: "매운 음식은 피하고 싶어요", badge: "초대", selected: false },
    { name: "하린", message: "좋아요 좋아요", badge: "선택됨", selected: true },
    { name: "서준", message: "이번엔 시간이 될지...", badge: "초대", selected: false },
  ];
}

function timeCandidates() {
  return [
    {
      time: "12:00",
      range: "~ 14:00",
      status: "모두 가능",
      description: "점심부터 여유롭게 시작할 수 있어요.",
      countLabel: "4/4",
      recommended: false,
    },
    {
      time: "13:00",
      range: "~ 15:00",
      status: "모두 가능",
      description: "가장 많은 친구들이 가능한 시간이에요!",
      countLabel: "4/4",
      recommended: true,
    },
    {
      time: "15:00",
      range: "~ 17:00",
      status: "일부만 가능",
      description: "2명의 친구가 일정이 있어요.",
      countLabel: "2/4",
      recommended: false,
    },
  ];
}

function visitPlan() {
  return [
    { time: "13:00", endTime: "14:30", place: "다운타우너 성수", kind: "카페", duration: "1시간 30분" },
    { time: "14:45", endTime: "16:15", place: "연무장길 카페거리", kind: "카페", duration: "1시간 30분" },
    { time: "16:30", endTime: "17:30", place: "성수연방", kind: "음식점", duration: "1시간" },
  ];
}

function secondDayVisitPlan() {
  return [
    { time: "10:30", endTime: "12:00", place: "협재 해수욕장", kind: "관광", duration: "1시간 30분" },
    { time: "12:20", endTime: "13:40", place: "한림 흑돼지 식당", kind: "식사", duration: "1시간 20분" },
    { time: "14:10", endTime: "16:00", place: "카페 오션뷰", kind: "카페", duration: "1시간 50분" },
  ];
}

function thirdDayVisitPlan() {
  return [
    { time: "09:30", endTime: "11:00", place: "오름 산책로", kind: "산책", duration: "1시간 30분" },
    { time: "11:30", endTime: "13:00", place: "동문시장", kind: "식사", duration: "1시간 30분" },
  ];
}

function placeCandidates() {
  return [
    {
      id: 201,
      name: "온무식당",
      category: "한식",
      summary: "영업중 · 브레이크타임 없음",
      distanceLabel: "홍대입구역 도보 7분",
      travelTimeLabel: "도보 7분",
      priceLabel: "1인 16,000원대",
      isOpen: true,
      address: "서울 마포구 와우산로 24",
      openingLabel: "오늘 11:30-21:00 · LO 20:30",
      addedBy: "지민",
      candidateStatusLabel: "후보",
      heartCount: 4,
      likedByMe: true,
      preferenceNotes: [
        { memberLabel: "A", note: "조용한, 담백한" },
        { memberLabel: "B", note: "한식, 웨이팅 짧음" },
      ],
      tags: ["조용한", "한식", "단체가능"],
      notes: ["함께 이야기해 볼 만한 한식 후보예요.", "약속 시간대에 방문하기 쉬운 편이에요."],
    },
    {
      id: 202,
      name: "무드카페",
      category: "카페",
      summary: "라스트오더 19:30 임박",
      distanceLabel: "합정역 도보 5분",
      travelTimeLabel: "도보 5분",
      priceLabel: "1인 12,000원대",
      isOpen: true,
      address: "서울 마포구 독막로 17",
      openingLabel: "오늘 12:00-20:00 · LO 19:30",
      addedBy: "민수",
      candidateStatusLabel: "후보",
      heartCount: 2,
      likedByMe: false,
      preferenceNotes: [
        { memberLabel: "A", note: "디저트" },
        { memberLabel: "B", note: "역 가까움" },
      ],
      tags: ["디저트", "뷰좋은", "웨이팅"],
      notes: ["합정역에서 가까운 카페 후보예요.", "디저트를 같이 먹기 좋은 선택지예요."],
    },
    {
      id: 203,
      name: "하루정원",
      category: "카페",
      summary: "마지막 동기화 12일 전",
      distanceLabel: "홍대입구역 도보 11분",
      travelTimeLabel: "도보 11분",
      priceLabel: "1인 14,000원대",
      isOpen: false,
      address: "서울 마포구 양화로 8",
      openingLabel: "영업시간 확인 필요",
      addedBy: "하린",
      candidateStatusLabel: "후보",
      heartCount: 1,
      likedByMe: false,
      preferenceNotes: [
        { memberLabel: "A", note: "디저트" },
        { memberLabel: "B", note: "조용한" },
      ],
      tags: ["확인 필요", "뷰좋은", "디저트"],
      notes: ["사진 기록과 잘 어울리는 공간이에요.", "방문 전 함께 확인해 볼 후보예요."],
    },
  ];
}

function settlementSummary() {
  const participants = [
    { name: "지민", owedAmountLabel: "20,667원", included: true },
    { name: "민수", owedAmountLabel: "20,667원", included: true },
    { name: "소연", owedAmountLabel: "20,667원", included: true },
    { name: "현우", owedAmountLabel: "20,667원", included: true },
    { name: "준호", owedAmountLabel: "20,666원", included: true },
    { name: "혜진", owedAmountLabel: "20,666원", included: true },
  ];

  return {
    id: 301,
    planTitle: "주말 나들이",
    totalAmountLabel: "186,000원",
    createdDateLabel: "정산일 2025.05.28",
    itemCountLabel: "결제 항목 2개",
    finalSummaryLabel: "4명이 송금 필요",
    mySummaryLabel: "나는 103,333원을 받아요",
    paymentItems: [
      {
        id: 401,
        title: "저녁",
        amountLabel: "124,000원",
        payerShares: [{ name: "지민", amountLabel: "124,000원" }],
        targetLabel: "6명",
        splitType: "equal",
        participants,
      },
      {
        id: 402,
        title: "카페",
        amountLabel: "62,000원",
        payerShares: [
          { name: "민수", amountLabel: "42,000원" },
          { name: "지민", amountLabel: "20,000원" },
        ],
        targetLabel: "4명",
        splitType: "custom",
        participants: [
          { name: "지민", owedAmountLabel: "20,000원", included: true },
          { name: "민수", owedAmountLabel: "18,000원", included: true },
          { name: "소연", owedAmountLabel: "12,000원", included: true },
          { name: "현우", owedAmountLabel: "12,000원", included: true },
          { name: "준호", owedAmountLabel: "-", included: false },
          { name: "혜진", owedAmountLabel: "-", included: false },
        ],
      },
    ],
    memberResults: [
      {
        name: "지민 (나)",
        finalShareLabel: "40,667원",
        paidAmountLabel: "144,000원",
        resultLabel: "103,333원 받음",
        isMe: true,
        willReceive: true,
      },
      {
        name: "민수",
        finalShareLabel: "38,667원",
        paidAmountLabel: "42,000원",
        resultLabel: "3,333원 받음",
        isMe: false,
        willReceive: true,
      },
      {
        name: "소연",
        finalShareLabel: "32,667원",
        paidAmountLabel: "0원",
        resultLabel: "지민에게 32,667원",
        isMe: false,
        willReceive: false,
      },
    ],
    transfers: [
      { fromName: "소연", toName: "지민", amountLabel: "32,667원" },
      { fromName: "현우", toName: "지민", amountLabel: "32,667원" },
      { fromName: "준호", toName: "지민", amountLabel: "20,666원" },
    ],
    shareMessage: "주말 나들이 약속 정산입니다. 최종 송금 금액만 확인해 주세요.",
  };
}

function settlementDraft(planId = 101) {
  const summary = settlementSummary();
  return {
    planId: parseId(planId),
    currency: "KRW",
    memo: "약속 비용을 함께 확인하는 draft입니다.",
    items: summary.paymentItems.map((item) => ({
      id: item.id,
      title: item.title,
      amountLabel: item.amountLabel,
      payerShares: item.payerShares,
      targetNames: item.participants.filter((participant) => participant.included).map((participant) => participant.name),
      targetLabel: item.targetLabel,
      splitType: item.splitType,
    })),
    updatedAtLabel: "방금",
  };
}

function placeCandidateFromInput(input = {}, id) {
  return {
    id,
    name: String(input.name || "새 후보 장소").trim(),
    category: String(input.category || "장소").trim(),
    summary: String(input.summary || "팀원이 추가한 후보").trim(),
    distanceLabel: String(input.distanceLabel || "거리 미정").trim(),
    travelTimeLabel: String(input.travelTimeLabel || "이동 시간 미정").trim(),
    priceLabel: String(input.priceLabel || "가격대 미정").trim(),
    isOpen: input.isOpen ?? true,
    address: String(input.address || "주소 미정").trim(),
    openingLabel: String(input.openingLabel || "영업시간 미정").trim(),
    addedBy: String(input.addedBy || "나").trim(),
    candidateStatusLabel: String(input.candidateStatusLabel || "후보").trim(),
    heartCount: Number.parseInt(String(input.heartCount ?? 0), 10) || 0,
    likedByMe: Boolean(input.likedByMe ?? false),
    preferenceNotes: Array.isArray(input.preferenceNotes) ? input.preferenceNotes : [],
    tags: Array.isArray(input.tags) ? input.tags : [],
    notes: Array.isArray(input.notes) ? input.notes : [],
  };
}

export function createDevContractStore() {
  const groups = [
    {
      id: 1,
      name: "대학 동기 여행단",
      description: "우리, 또 하나의 추억을 만들자",
      members: ["지민", "민수", "소연", "현우", "준호", "혜진", "나", "지훈"],
      lastMessage: "제주도 준비물 체크리스트를 고정해뒀어요.",
      unreadCount: 3,
      pinnedPlanTitle: "제주도 여행 D-7",
    },
    {
      id: 2,
      name: "퇴근 후 러닝크루",
      description: "여의도 한강공원에서 뛰고 기록을 남겨요",
      members: ["서윤", "도윤", "나", "하린", "민재"],
      lastMessage: "오늘은 19:30 출발로 맞춰둘게.",
      unreadCount: 1,
      pinnedPlanTitle: "금요일 러닝 D-2",
    },
    {
      id: 3,
      name: "보드게임 모임",
      description: "홍대 보드게임카페 후보를 투표 중이에요",
      members: ["민서", "지훈", "나", "하린", "도윤", "서윤"],
      lastMessage: "온무식당 쪽으로 저녁 먼저 먹고 갈까?",
      unreadCount: 2,
      pinnedPlanTitle: "일요일 보드게임 D-4",
    },
  ];

  const pinnedPlansByGroupId = new Map([
    [
      1,
      {
        id: 101,
        title: "제주도 여행",
        dateLabel: "6.7(토) - 6.9(월)",
        placeName: "제주도 일대",
        statusLabel: "D-12",
        voteSummary: "4명 참여",
      },
    ],
  ]);

  const plansByGroupId = new Map([
    [
      1,
      [
        {
          id: 101,
          title: "제주도 여행",
          dateLabel: "6.7 (금) - 6.9 (일)",
          placeName: "제주도 일대",
          statusLabel: "D-12",
          statusType: "진행중",
          memberCount: 6,
          extraMemberCount: 2,
          iconKind: "water",
          isPast: false,
        },
        {
          id: 102,
          title: "한남 카페 투어",
          dateLabel: "6.5 (수) 오후 2:00",
          placeName: "한남동 일대",
          statusLabel: "D-2",
          statusType: "예정",
          memberCount: 5,
          extraMemberCount: 1,
          iconKind: "coffee",
          isPast: false,
        },
        {
          id: 103,
          title: "한강 피크닉",
          dateLabel: "5.10 (금) 오후 1:00",
          placeName: "여의도 한강공원",
          statusLabel: "완료",
          statusType: "완료",
          memberCount: 4,
          extraMemberCount: 0,
          iconKind: "park",
          isPast: true,
        },
      ],
    ],
    [2, []],
    [3, []],
  ]);

  const membersByGroupId = new Map([
    [
      1,
      [
        { name: "지연", note: "여행 가이드 준비 중이에요", statusLabel: "참여 중", invited: false },
        { name: "민수", note: "맛집 리스트 정리 중!", statusLabel: "참여 중", invited: false },
        { name: "하린", note: "렌터카 비교해봤어요", statusLabel: "참여 중", invited: false },
        { name: "현우", note: "숙소 후보 찾아보는 중", statusLabel: "참여 중", invited: false },
      ],
    ],
    [2, [{ name: "서윤", note: "러닝 코스 담당", statusLabel: "참여 중", invited: false }]],
    [3, [{ name: "민서", note: "보드게임 추천 중", statusLabel: "참여 중", invited: false }]],
  ]);

  const messagesByGroupId = new Map([
    [
      1,
      [
        { sender: "지민", message: "다들 안녕! 드디어 다음 주에 제주도네.", timeLabel: "오전 9:21", isMine: false },
        { sender: "나", message: "기대된다아 ㅎㅎ", timeLabel: "오전 9:22", isMine: true },
        {
          sender: "ONMU",
          message: "장소 후보가 3개 모였어요. 필요하면 투표를 만들어 함께 정해요.",
          timeLabel: "오전 9:25",
          isMine: false,
        },
      ],
    ],
    [2, [{ sender: "서윤", message: "오늘은 19:30 출발로 맞춰둘게.", timeLabel: "오후 4:10", isMine: false }]],
    [3, [{ sender: "민서", message: "온무식당 쪽으로 저녁 먼저 먹고 갈까?", timeLabel: "오후 1:18", isMine: false }]],
  ]);

  const memoriesByGroupId = new Map([
    [
      1,
      [
        {
          id: 1001,
          author: "지연",
          title: "성수동 카페",
          description: "분위기 좋은 카페 발견! 디저트도 너무 맛있었어요.",
          dateLabel: "2024.05.24",
          tags: ["카페", "사진", "디저트"],
        },
        {
          id: 1002,
          author: "민수",
          title: "한강 피크닉",
          description: "노을 보면서 먹은 김밥이 최고였어요.",
          dateLabel: "2024.05.10",
          tags: ["피크닉", "노을"],
        },
      ],
    ],
    [
      2,
      [
        {
          id: 1005,
          author: "서윤",
          title: "여의도 러닝",
          description: "강변 코스 5km를 함께 달렸어요.",
          dateLabel: "2024.05.27",
          tags: ["운동", "기록", "러닝"],
        },
      ],
    ],
    [3, []],
  ]);

  const plansById = new Map();
  const visitPlansByPlanId = new Map();
  for (const plans of plansByGroupId.values()) {
    for (const summary of plans) {
      plansById.set(summary.id, {
        id: summary.id,
        title: summary.title,
        dateTime: summary.dateLabel,
        location: summary.placeName,
        status: summary.statusType,
        memo: "편한 복장으로 오기! 돗자리 챙기면 좋을 것 같아요.",
        members: planMembers(),
        timeCandidates: timeCandidates(),
        visitPlan: visitPlan(),
      });
      visitPlansByPlanId.set(summary.id, [visitPlan(), secondDayVisitPlan(), thirdDayVisitPlan()]);
    }
  }

  const candidatesByPlanId = new Map();
  const scheduledPlacesByPlanId = new Map();
  for (const planId of [101, 102, 103, 104, 105]) {
    candidatesByPlanId.set(planId, placeCandidates());
    scheduledPlacesByPlanId.set(planId, []);
  }

  const votesByGroupId = new Map([
    [
      1,
      [
        {
          id: 501,
          title: "제주도 여행 장소 투표",
          statusLabel: "진행 중",
          description: "카페 오션뷰 외 2곳 · 4명 참여",
          planLabel: "제주도 여행",
          planMeta: "6.7 - 6.9 · 제주도 일대",
          participants: ["지민", "민수", "하린", "현우"],
          options: [
            { label: "카페 오션뷰", countLabel: "3표", progress: 0.78 },
            { label: "흑돼지 맛집 돈사돈", countLabel: "2표", progress: 0.56 },
            { label: "협재 해수욕장", countLabel: "1표", progress: 0.32 },
          ],
          closed: false,
          joinedByMe: true,
          actionLabel: "투표 확인하기",
        },
      ],
    ],
    [2, []],
    [3, []],
  ]);

  const voteCardsByVoteId = new Map([
    [
      501,
      {
        title: "제주도 여행 장소 투표",
        summary: "카페 오션뷰, 흑돼지 맛집 돈사돈, 협재 해수욕장 후보를 비교 중이에요.",
        statusLabel: "수동 투표 · 진행 중",
        actionLabel: "투표 보기",
      },
    ],
  ]);
  const voteVotersByVoteId = new Map([[501, { 201: ["민서", "하린"], 202: ["지훈"] }]]);
  const settlementsByPlanId = new Map([[101, settlementSummary()], [102, settlementSummary()], [103, settlementSummary()]]);
  const settlementDraftsByPlanId = new Map([[101, settlementDraft(101)], [102, settlementDraft(102)], [103, settlementDraft(103)]]);

  let nextGroupId = 4;
  let nextPlanId = 106;
  let nextPlaceCandidateId = 204;
  let nextScheduledPlaceId = 701;
  let nextVoteId = 505;
  let nextSettlementId = 302;

  const groupById = (groupId) => groups.find((group) => group.id === parseId(groupId)) || firstOrThrow(groups, "No groups seeded");
  const planById = (planId) => plansById.get(parseId(planId)) || firstOrThrow([...plansById.values()], "No plans seeded");
  const groupPlans = (groupId) => plansByGroupId.get(parseId(groupId)) || [];
  const groupMembers = (groupId) => membersByGroupId.get(parseId(groupId)) || [];
  const groupMemories = (groupId) => memoriesByGroupId.get(parseId(groupId)) || [];
  const groupVotes = (groupId) => votesByGroupId.get(parseId(groupId)) || [];

  function replaceGroupPlanSummary(groupId, plan) {
    const summaries = plansByGroupId.get(parseId(groupId));
    if (!summaries) {
      return;
    }
    const index = summaries.findIndex((summary) => summary.id === plan.id);
    if (index === -1) {
      return;
    }
    summaries[index] = {
      ...summaries[index],
      title: plan.title,
      dateLabel: plan.dateTime,
      placeName: plan.location,
    };
  }

  return {
    fetchGroups: () => groups,
    fetchGroup: groupById,
    createGroup(input = {}) {
      const memberNames = Array.isArray(input.memberNames) && input.memberNames.length ? input.memberNames : ["나"];
      const group = {
        id: nextGroupId++,
        name: String(input.name || "새 온모임").trim(),
        description: String(input.description || "함께할 온모임").trim(),
        members: memberNames,
        lastMessage: "새 온모임이 만들어졌어요.",
        unreadCount: 0,
        pinnedPlanTitle: "첫 약속을 만들어 보세요",
      };
      groups.unshift(group);
      membersByGroupId.set(group.id, memberNames.map((name) => ({ name, note: "함께할 멤버로 추가됐어요.", statusLabel: "참여 중", invited: false })));
      messagesByGroupId.set(group.id, [{ sender: "ONMU", message: `${group.name} 온모임이 시작됐어요.`, timeLabel: "방금", isMine: false }]);
      plansByGroupId.set(group.id, []);
      memoriesByGroupId.set(group.id, []);
      votesByGroupId.set(group.id, []);
      return group;
    },
    fetchPinnedPlan: (groupId) => pinnedPlansByGroupId.get(parseId(groupId)) || null,
    fetchGroupPlans: groupPlans,
    fetchMembers: groupMembers,
    fetchMessages: (groupId) => messagesByGroupId.get(parseId(groupId)) || [],
    fetchMemories: groupMemories,
    fetchMemory({ groupId, memoryId }) {
      const memories = groupMemories(groupId);
      return memories.find((memory) => memory.id === parseId(memoryId)) || firstOrThrow(memories, "No memories seeded");
    },
    fetchPlan: ({ planId }) => planById(planId),
    createPlan(input = {}) {
      const groupId = parseId(input.groupId);
      const plan = {
        id: nextPlanId++,
        title: String(input.title || "새 약속").trim(),
        dateTime: String(input.dateTime || "일정 미정").trim(),
        location: String(input.location || "장소 미정").trim(),
        status: "이행 전",
        memo: String(input.memo || "").trim(),
        members: Array.isArray(input.members) ? input.members : planMembers(),
        timeCandidates: timeCandidates(),
        visitPlan: visitPlan(),
      };
      plansById.set(plan.id, plan);
      visitPlansByPlanId.set(plan.id, [visitPlan(), secondDayVisitPlan(), thirdDayVisitPlan()]);
      plansByGroupId.set(groupId, [
        {
          id: plan.id,
          title: plan.title,
          dateLabel: plan.dateTime,
          placeName: plan.location,
          statusLabel: "D-day",
          statusType: "예정",
          memberCount: plan.members.filter((member) => member.selected).length,
          extraMemberCount: 0,
          iconKind: "coffee",
          isPast: false,
        },
        ...groupPlans(groupId),
      ]);
      candidatesByPlanId.set(plan.id, placeCandidates());
      scheduledPlacesByPlanId.set(plan.id, []);
      settlementsByPlanId.set(plan.id, settlementSummary());
      settlementDraftsByPlanId.set(plan.id, settlementDraft(plan.id));
      if (!pinnedPlansByGroupId.has(groupId)) {
        pinnedPlansByGroupId.set(groupId, {
          id: plan.id,
          title: plan.title,
          dateLabel: plan.dateTime,
          placeName: plan.location,
          statusLabel: "예정",
          voteSummary: "투표 준비 전",
        });
      }
      return plan;
    },
    updatePlan({ groupId, planId, input = {} }) {
      const previous = planById(planId);
      const updated = {
        ...previous,
        title: String(input.title || previous.title).trim(),
        dateTime: String(input.dateTime || previous.dateTime).trim(),
        location: String(input.location || previous.location).trim(),
        memo: String(input.memo || previous.memo).trim(),
        members: Array.isArray(input.members) ? input.members : previous.members,
      };
      plansById.set(previous.id, updated);
      replaceGroupPlanSummary(groupId, updated);
      return updated;
    },
    fetchVisitPlansByDate: ({ planId }) => visitPlansByPlanId.get(parseId(planId)) || [],
    fetchPlaceCandidates: ({ planId }) => candidatesByPlanId.get(parseId(planId)) || [],
    fetchPlaceCandidate({ planId, candidateId }) {
      const candidates = candidatesByPlanId.get(parseId(planId)) || [];
      return candidates.find((candidate) => candidate.id === parseId(candidateId)) || firstOrThrow(candidates, "No place candidates seeded");
    },
    addPlaceCandidate({ planId, input = {} }) {
      const planKey = parseId(planId);
      const candidate = placeCandidateFromInput(input, nextPlaceCandidateId++);
      candidatesByPlanId.set(planKey, [candidate, ...(candidatesByPlanId.get(planKey) || [])]);
      return candidate;
    },
    addSchedulePlace({ planId, input = {} }) {
      const planKey = parseId(planId);
      const candidates = candidatesByPlanId.get(planKey) || [];
      const candidateId = parseId(input.candidateId);
      const candidate = candidates.find((item) => item.id === candidateId) || null;
      const schedulePlace = {
        id: nextScheduledPlaceId++,
        candidateId: candidate?.id ?? (candidateId || null),
        name: String(input.name || candidate?.name || "일정 장소").trim(),
        category: String(input.category || candidate?.category || "장소").trim(),
        startTime: String(input.startTime || "시간 미정").trim(),
        endTime: String(input.endTime || "").trim(),
        order: Number.parseInt(String(input.order ?? (scheduledPlacesByPlanId.get(planKey)?.length || 0) + 1), 10) || 1,
        note: String(input.note || "").trim(),
      };
      scheduledPlacesByPlanId.set(planKey, [...(scheduledPlacesByPlanId.get(planKey) || []), schedulePlace]);
      return {
        schedulePlace,
        schedulePlaces: scheduledPlacesByPlanId.get(planKey) || [],
      };
    },
    searchPlaces(query = "") {
      const keyword = String(query).trim();
      const candidates = placeCandidates();
      if (!keyword) {
        return candidates;
      }
      return candidates.filter((candidate) => candidate.name.includes(keyword) || candidate.category.includes(keyword));
    },
    fetchVotes: groupVotes,
    createVote(input = {}) {
      const groupId = parseId(input.groupId);
      const plan = planById(input.planId);
      const candidateNames = Array.isArray(input.candidateNames) ? input.candidateNames : [];
      const vote = {
        id: nextVoteId++,
        title: String(input.title || "새 투표").trim(),
        statusLabel: "진행 중",
        description: `${candidateNames.join(", ")} · ${input.modeLabel || "단일 선택"}`,
        planLabel: plan.title,
        planMeta: `${plan.dateTime} · ${plan.location}`,
        participants: groupById(groupId).members.slice(0, 4),
        options: candidateNames.map((label) => ({ label, countLabel: "0표", progress: 0 })),
        closed: false,
        joinedByMe: true,
        actionLabel: "투표 확인하기",
      };
      votesByGroupId.set(groupId, [vote, ...groupVotes(groupId)]);
      voteCardsByVoteId.set(vote.id, {
        title: vote.title,
        summary: vote.description,
        statusLabel: `${input.modeLabel || "단일 선택"} · ${input.deadlineDate || "날짜 미정"} ${input.deadlineTime || ""} 마감`.trim(),
        actionLabel: "투표 보기",
      });
      voteVotersByVoteId.set(vote.id, {});
      return vote;
    },
    fetchVoteCard: ({ voteId }) =>
      voteCardsByVoteId.get(parseId(voteId)) || {
        title: "투표",
        summary: "투표 정보를 불러오지 못했어요.",
        statusLabel: "확인 필요",
        actionLabel: "목록으로",
      },
    fetchVoteVoters: ({ voteId }) => voteVotersByVoteId.get(parseId(voteId)) || {},
    fetchSettlement: ({ planId }) => settlementsByPlanId.get(parseId(planId)) || firstOrThrow([...settlementsByPlanId.values()], "No settlements seeded"),
    fetchSettlementDraft({ planId }) {
      const planKey = parseId(planId);
      if (!settlementDraftsByPlanId.has(planKey)) {
        settlementDraftsByPlanId.set(planKey, settlementDraft(planKey));
      }
      return settlementDraftsByPlanId.get(planKey);
    },
    updateSettlementDraft({ planId, input = {} }) {
      const planKey = parseId(planId);
      const previous = this.fetchSettlementDraft({ planId: planKey });
      const draft = {
        ...previous,
        ...input,
        planId: planKey,
        items: Array.isArray(input.items) ? input.items : previous.items,
        updatedAtLabel: "방금",
      };
      settlementDraftsByPlanId.set(planKey, draft);
      return draft;
    },
    updateSettlementDraftTargets({ planId, itemId, input = {} }) {
      const planKey = parseId(planId);
      const draft = this.fetchSettlementDraft({ planId: planKey });
      const targetNames = Array.isArray(input.targetNames) ? input.targetNames : [];
      const items = draft.items.map((item) =>
        item.id === parseId(itemId)
          ? {
              ...item,
              targetNames,
              targetLabel: `${targetNames.length}명`,
            }
          : item,
      );
      const updated = { ...draft, items, updatedAtLabel: "방금" };
      settlementDraftsByPlanId.set(planKey, updated);
      return updated;
    },
    previewSettlement({ planId, input = {} }) {
      const draft = input.items || input.memo ? this.updateSettlementDraft({ planId, input }) : this.fetchSettlementDraft({ planId });
      return {
        draft,
        preview: settlementsByPlanId.get(parseId(planId)) || settlementSummary(),
      };
    },
    createSettlement({ planId, input = {} }) {
      const planKey = parseId(planId);
      if (input.items || input.memo) {
        this.updateSettlementDraft({ planId: planKey, input });
      }
      const summary = {
        ...(settlementsByPlanId.get(planKey) || settlementSummary()),
        id: nextSettlementId++,
        createdDateLabel: "정산일 방금",
      };
      settlementsByPlanId.set(planKey, summary);
      return summary;
    },
    fetchHomeSummary() {
      let group = groups[0];
      let pinnedPlan = pinnedPlansByGroupId.get(group.id);
      let plans = groupPlans(group.id);
      for (const candidate of groups) {
        const candidatePinnedPlan = pinnedPlansByGroupId.get(candidate.id);
        const candidatePlans = groupPlans(candidate.id);
        if (candidatePinnedPlan || candidatePlans.length) {
          group = candidate;
          pinnedPlan = candidatePinnedPlan;
          plans = candidatePlans;
          break;
        }
      }
      const activePlanId = pinnedPlan?.id ?? plans[0]?.id;
      const activePlan = planById(activePlanId);
      const settlement = settlementsByPlanId.get(activePlan.id) || settlementSummary();
      return {
        groupId: group.id,
        group,
        activePlan,
        upcomingPlans: plans.filter((plan) => !plan.isPast),
        settlementId: settlement.id,
        settlement,
      };
    },
  };
}
