import 'package:onmu_mobile/shared/models/group_models.dart';
import 'package:onmu_mobile/shared/models/place_models.dart';
import 'package:onmu_mobile/shared/models/plan_models.dart';
import 'package:onmu_mobile/shared/models/settlement_models.dart';
import 'package:onmu_mobile/shared/models/vote_models.dart';

class InMemoryOnmuStore {
  InMemoryOnmuStore.seeded() {
    _seedGroups();
    _seedPlans();
    _seedPlaces();
    _seedVotes();
    _seedSettlement();
  }

  final _groups = <GroupSummary>[];
  final _pinnedPlansByGroupId = <int, GroupPinnedPlan>{};
  final _plansByGroupId = <int, List<GroupPlanSummary>>{};
  final _membersByGroupId = <int, List<GroupMemberProfile>>{};
  final _messagesByGroupId = <int, List<GroupMessage>>{};
  final _memoriesByGroupId = <int, List<GroupMemoryRecord>>{};
  final _plansById = <int, Plan>{};
  final _visitPlansByPlanId = <int, List<List<VisitPlan>>>{};
  final _candidatesByPlanId = <int, List<PlaceCandidate>>{};
  final _risksByPlanId = <int, List<PlaceRisk>>{};
  final _voteResultsByPlanId = <int, PlaceVoteResult>{};
  final _votesByGroupId = <int, List<VoteSummary>>{};
  final _voteCardsByVoteId = <int, VoteCard>{};
  final _voteVotersByVoteId = <int, Map<int, List<String>>>{};
  final _settlementsByPlanId = <int, SettlementSummary>{};

  var _nextGroupId = 4;
  var _nextPlanId = 106;
  var _nextVoteId = 505;
  var _nextMessageId = 1;

  List<GroupSummary> fetchGroups() => List.unmodifiable(_groups);

  GroupSummary fetchGroup(Object groupId) {
    final parsedId = _parseId(groupId);
    return _groups.firstWhere(
      (group) => group.id == parsedId,
      orElse: () => _groups.first,
    );
  }

  GroupSummary createGroup(GroupCreateInput input) {
    final memberNames = input.memberNames.isEmpty
        ? ['나']
        : input.memberNames.toList(growable: false);
    final group = GroupSummary(
      id: _nextGroupId++,
      name: input.name.trim(),
      description: input.description.trim(),
      members: memberNames,
      lastMessage: '새 온모임이 만들어졌어요.',
      unreadCount: 0,
      pinnedPlanTitle: '첫 약속을 만들어 보세요',
    );

    _groups.insert(0, group);
    _membersByGroupId[group.id] = [
      for (final name in memberNames)
        GroupMemberProfile(
          name: name,
          note: '함께할 멤버로 추가됐어요.',
          statusLabel: '참여 중',
        ),
    ];
    _messagesByGroupId[group.id] = [
      GroupMessage(
        sender: 'ONMU',
        message: '${group.name} 온모임이 시작됐어요.',
        timeLabel: '방금',
        isMine: false,
      ),
    ];
    _plansByGroupId[group.id] = [];
    _memoriesByGroupId[group.id] = [];
    _votesByGroupId[group.id] = [];

    return group;
  }

  GroupPinnedPlan? fetchPinnedPlan(Object groupId) {
    return _pinnedPlansByGroupId[_parseId(groupId)];
  }

  List<GroupPlanSummary> fetchGroupPlans(Object groupId) {
    return List.unmodifiable(_plansByGroupId[_parseId(groupId)] ?? []);
  }

  List<GroupMemberProfile> fetchMembers(Object groupId) {
    return List.unmodifiable(_membersByGroupId[_parseId(groupId)] ?? []);
  }

  List<GroupMemoryRecord> fetchMemories(Object groupId) {
    return List.unmodifiable(_memoriesByGroupId[_parseId(groupId)] ?? []);
  }

  GroupMemoryRecord fetchMemory({
    required Object groupId,
    required Object memoryId,
  }) {
    final memories = _memoriesByGroupId[_parseId(groupId)] ?? [];
    final parsedMemoryId = _parseId(memoryId);
    return memories.firstWhere(
      (memory) => memory.id == parsedMemoryId,
      orElse: () => memories.first,
    );
  }

  List<GroupMessage> fetchMessages(Object groupId) {
    final parsedGroupId = _parseId(groupId);
    return List.unmodifiable(
      _withMessageIds(parsedGroupId, _messagesByGroupId[parsedGroupId] ?? []),
    );
  }

  GroupMessagePage fetchMessagePage(
    Object groupId, {
    String? beforeCursor,
    int? limit,
  }) {
    final messages = fetchMessages(groupId);
    final cursor = beforeCursor?.trim();
    final source = cursor == null || cursor.isEmpty
        ? messages
        : messages
              .takeWhile((message) {
                return message.cursor != cursor && message.id != cursor;
              })
              .toList(growable: false);
    final effectiveLimit = limit ?? 50;
    final hasMore = source.length > effectiveLimit;
    final pageMessages = hasMore
        ? source.sublist(source.length - effectiveLimit)
        : source;

    return GroupMessagePage(
      messages: List.unmodifiable(pageMessages),
      nextCursor: hasMore && pageMessages.isNotEmpty
          ? pageMessages.first.cursor
          : null,
      hasMore: hasMore,
      unreadCount: 0,
    );
  }

  int markMessagesRead({required Object groupId, String? lastReadMessageId}) {
    return 0;
  }

  GroupMessage sendMessage({required Object groupId, required String message}) {
    final groupMessages = _messagesByGroupId.putIfAbsent(
      _parseId(groupId),
      () => [],
    );
    final messageId = 'store-message-${_nextMessageId++}';
    final created = GroupMessage(
      id: messageId,
      cursor: messageId,
      sender: '나',
      message: message.trim(),
      timeLabel: '방금',
      isMine: true,
    );
    groupMessages.add(created);
    return created;
  }

  List<GroupMessage> _withMessageIds(int groupId, List<GroupMessage> messages) {
    return [
      for (var index = 0; index < messages.length; index += 1)
        messages[index].id.isEmpty || messages[index].cursor.isEmpty
            ? messages[index].copyWith(
                id: messages[index].id.isEmpty
                    ? 'group-$groupId-message-$index'
                    : messages[index].id,
                cursor: messages[index].cursor.isEmpty
                    ? 'group-$groupId-message-$index'
                    : messages[index].cursor,
              )
            : messages[index],
    ];
  }

  Plan fetchPlan({required Object groupId, required Object planId}) {
    final parsedPlanId = _parseId(planId);
    return _plansById[parsedPlanId] ?? _plansById.values.first;
  }

  Plan createPlan(PlanCreateInput input) {
    final groupId = _parseId(input.groupId);
    final plan = Plan(
      id: _nextPlanId++,
      title: input.title.trim(),
      dateTime: input.dateTime.trim(),
      location: input.location.trim(),
      status: '이행 전',
      memo: input.memo.trim(),
      members: List.unmodifiable(input.members),
      timeCandidates: _seedTimeCandidates(),
      visitPlan: _seedVisitPlan(),
      startsAt: _parsePlanDateTime(input.dateTime),
    );

    _plansById[plan.id] = plan;
    _visitPlansByPlanId[plan.id] = [
      List.unmodifiable(plan.visitPlan),
      List.unmodifiable(_seedSecondDayVisitPlan()),
      List.unmodifiable(_seedThirdDayVisitPlan()),
    ];
    _plansByGroupId
        .putIfAbsent(groupId, () => [])
        .insert(
          0,
          GroupPlanSummary(
            id: plan.id,
            title: plan.title,
            dateLabel: plan.dateTime,
            startsAt: _parsePlanDateTime(plan.dateTime),
            placeName: plan.location,
            statusLabel: 'D-day',
            statusType: '예정',
            memberCount: plan.members.where((member) => member.selected).length,
            extraMemberCount: 0,
            iconKind: 'coffee',
            isPast: false,
          ),
        );
    _candidatesByPlanId[plan.id] = _createPlaceCandidates();
    _risksByPlanId[plan.id] = _createPlaceRisks();
    _voteResultsByPlanId[plan.id] = _createPlaceVoteResult();
    if (_settlementsByPlanId.isNotEmpty) {
      _settlementsByPlanId[plan.id] = _settlementsByPlanId.values.first;
    }
    _pinnedPlansByGroupId.putIfAbsent(
      groupId,
      () => GroupPinnedPlan(
        id: plan.id,
        title: plan.title,
        dateLabel: plan.dateTime,
        placeName: plan.location,
        statusLabel: '예정',
        voteSummary: '투표 준비 전',
      ),
    );

    return plan;
  }

  Plan updatePlan({required Object planId, required PlanCreateInput input}) {
    final parsedPlanId = _parseId(planId);
    final previous = fetchPlan(groupId: input.groupId, planId: parsedPlanId);
    final updated = Plan(
      id: previous.id,
      title: input.title.trim(),
      dateTime: input.dateTime.trim(),
      location: input.location.trim(),
      status: previous.status,
      memo: input.memo.trim(),
      members: List.unmodifiable(input.members),
      timeCandidates: previous.timeCandidates,
      visitPlan: previous.visitPlan,
      startsAt: _parsePlanDateTime(input.dateTime),
    );
    _plansById[parsedPlanId] = updated;
    _replaceGroupPlanSummary(input.groupId, updated);
    return updated;
  }

  List<List<VisitPlan>> fetchVisitPlansByDate({
    required Object groupId,
    required Object planId,
  }) {
    return List.unmodifiable(
      (_visitPlansByPlanId[_parseId(planId)] ?? []).map(
        List<VisitPlan>.unmodifiable,
      ),
    );
  }

  List<PlaceCandidate> fetchPlaceCandidates({
    required Object groupId,
    required Object planId,
  }) {
    return List.unmodifiable(_candidatesByPlanId[_parseId(planId)] ?? []);
  }

  PlaceCandidate fetchPlaceCandidate({
    required Object groupId,
    required Object planId,
    required Object candidateId,
  }) {
    final candidates = _candidatesByPlanId[_parseId(planId)] ?? [];
    final parsedCandidateId = _parseId(candidateId);
    return candidates.firstWhere(
      (candidate) => candidate.id == parsedCandidateId,
      orElse: () => candidates.first,
    );
  }

  List<PlaceRisk> fetchPlaceRisks({
    required Object groupId,
    required Object planId,
  }) {
    return List.unmodifiable(_risksByPlanId[_parseId(planId)] ?? []);
  }

  PlaceVoteResult fetchPlaceVoteResult({
    required Object groupId,
    required Object planId,
  }) {
    return _voteResultsByPlanId[_parseId(planId)] ??
        PlaceVoteResult(
          title: '투표 결과',
          selectedPlaceName: '아직 선택된 장소가 없어요',
          voters: [],
          note: '투표가 만들어지면 결과가 여기에 표시돼요.',
        );
  }

  List<VoteSummary> fetchVotes(Object groupId) {
    return List.unmodifiable(_votesByGroupId[_parseId(groupId)] ?? []);
  }

  VoteSummary createVote(VoteCreateInput input) {
    final groupId = _parseId(input.groupId);
    final plan = fetchPlan(groupId: groupId, planId: input.planId);
    final vote = VoteSummary(
      id: _nextVoteId++,
      title: input.title.trim(),
      statusLabel: '진행 중',
      description: '${input.candidateNames.join(', ')} · ${input.modeLabel}',
      planLabel: plan.title,
      planMeta: '${plan.dateTime} · ${plan.location}',
      participants: fetchGroup(groupId).members.take(4).toList(growable: false),
      options: [
        for (final name in input.candidateNames)
          VoteOptionSummary(label: name, countLabel: '0표', progress: 0),
      ],
      closed: false,
      joinedByMe: true,
      actionLabel: '투표 확인하기',
    );

    _votesByGroupId.putIfAbsent(groupId, () => []).insert(0, vote);
    _voteCardsByVoteId[vote.id] = VoteCard(
      title: vote.title,
      summary: vote.description,
      statusLabel:
          '${input.modeLabel} · ${input.deadlineDate} ${input.deadlineTime} 마감',
      actionLabel: '투표 보기',
    );
    _voteVotersByVoteId[vote.id] = {};
    return vote;
  }

  VoteCard fetchVoteCard({required Object groupId, required Object voteId}) {
    final parsedVoteId = _parseId(voteId);
    return _voteCardsByVoteId[parsedVoteId] ??
        VoteCard(
          title: '투표',
          summary: '투표 정보를 불러오지 못했어요.',
          statusLabel: '확인 필요',
          actionLabel: '목록으로',
        );
  }

  Map<int, List<String>> fetchVoteVoters({
    required Object groupId,
    required Object voteId,
  }) {
    final votersByCandidate =
        _voteVotersByVoteId[_parseId(voteId)] ?? <int, List<String>>{};

    return Map.unmodifiable(
      votersByCandidate.map(
        (candidateId, voters) =>
            MapEntry(candidateId, List<String>.unmodifiable(voters)),
      ),
    );
  }

  SettlementSummary fetchSettlement({
    required Object groupId,
    required Object planId,
  }) {
    return _settlementsByPlanId[_parseId(planId)] ??
        _settlementsByPlanId.values.first;
  }

  int _parseId(Object value) => int.tryParse(value.toString()) ?? 0;

  DateTime? _parsePlanDateTime(String value) {
    final now = DateTime.now();
    final match = RegExp(r'(\d{1,2})\.(\d{1,2})').firstMatch(value);
    if (match == null) {
      return null;
    }
    final month = int.tryParse(match.group(1) ?? '');
    final day = int.tryParse(match.group(2) ?? '');
    if (month == null || day == null) {
      return null;
    }
    final timeMatch = RegExp(r'(오전|오후)\s*(\d{1,2}):(\d{2})').firstMatch(value);
    if (timeMatch == null) {
      return DateTime(now.year, month, day);
    }

    final meridiem = timeMatch.group(1);
    final hourValue = int.tryParse(timeMatch.group(2) ?? '');
    final minute = int.tryParse(timeMatch.group(3) ?? '');
    if (hourValue == null || minute == null) {
      return DateTime(now.year, month, day);
    }

    final hour = switch (meridiem) {
      '오후' when hourValue < 12 => hourValue + 12,
      '오전' when hourValue == 12 => 0,
      _ => hourValue,
    };

    return DateTime(now.year, month, day, hour, minute);
  }

  DateTime _relativeSeedPlanDateTime({
    required int daysFromToday,
    required int hour,
    int minute = 0,
  }) {
    final now = DateTime.now().toLocal();
    final today = DateTime(now.year, now.month, now.day);
    return today.add(
      Duration(days: daysFromToday, hours: hour, minutes: minute),
    );
  }

  void _replaceGroupPlanSummary(Object groupId, Plan plan) {
    final summaries = _plansByGroupId[_parseId(groupId)];
    if (summaries == null) {
      return;
    }
    final index = summaries.indexWhere((summary) => summary.id == plan.id);
    if (index == -1) {
      return;
    }
    final previous = summaries[index];
    summaries[index] = GroupPlanSummary(
      id: previous.id,
      title: plan.title,
      dateLabel: plan.dateTime,
      startsAt: _parsePlanDateTime(plan.dateTime),
      placeName: plan.location,
      statusLabel: previous.statusLabel,
      statusType: previous.statusType,
      memberCount: previous.memberCount,
      extraMemberCount: previous.extraMemberCount,
      iconKind: previous.iconKind,
      isPast: previous.isPast,
    );
  }

  void _seedGroups() {
    _groups.addAll([
      GroupSummary(
        id: 1,
        name: '대학 동기 여행단',
        description: '우리, 또 하나의 추억을 만들자',
        members: ['지민', '민수', '소연', '현우', '준호', '혜진', '나', '지훈'],
        lastMessage: '제주도 준비물 체크리스트를 고정해뒀어요.',
        unreadCount: 3,
        pinnedPlanTitle: '제주도 여행 D-7',
      ),
      GroupSummary(
        id: 2,
        name: '퇴근 후 러닝크루',
        description: '여의도 한강공원에서 뛰고 기록을 남겨요',
        members: ['서윤', '도윤', '나', '하린', '민재'],
        lastMessage: '오늘은 19:30 출발로 맞춰둘게.',
        unreadCount: 1,
        pinnedPlanTitle: '금요일 러닝 D-2',
      ),
      GroupSummary(
        id: 3,
        name: '보드게임 모임',
        description: '홍대 보드게임카페 후보를 투표 중이에요',
        members: ['민서', '지훈', '나', '하린', '도윤', '서윤'],
        lastMessage: '온무식당 쪽으로 저녁 먼저 먹고 갈까?',
        unreadCount: 2,
        pinnedPlanTitle: '일요일 보드게임 D-4',
      ),
    ]);

    _membersByGroupId[1] = [
      GroupMemberProfile(
        name: '지연',
        note: '여행 가이드 준비 중이에요',
        statusLabel: '참여 중',
      ),
      GroupMemberProfile(name: '민수', note: '맛집 리스트 정리 중!', statusLabel: '참여 중'),
      GroupMemberProfile(name: '하린', note: '렌터카 비교해봤어요', statusLabel: '참여 중'),
      GroupMemberProfile(name: '현우', note: '숙소 후보 찾아보는 중', statusLabel: '참여 중'),
      GroupMemberProfile(
        name: '소연',
        note: '카페 투어 코스 짜는 중',
        statusLabel: '참여 중',
      ),
      GroupMemberProfile(
        name: '재훈',
        note: '사진 스팟 모아두었어요',
        statusLabel: '초대됨',
        invited: true,
      ),
      GroupMemberProfile(
        name: '은지',
        note: '함께하고 싶어요!',
        statusLabel: '초대됨',
        invited: true,
      ),
      GroupMemberProfile(
        name: '태호',
        note: '이번엔 꼭 참석할게요!',
        statusLabel: '초대됨',
        invited: true,
      ),
    ];
    _membersByGroupId[2] = [
      GroupMemberProfile(name: '서윤', note: '러닝 코스 담당', statusLabel: '참여 중'),
      GroupMemberProfile(name: '도윤', note: '페이스 조절 담당', statusLabel: '참여 중'),
      GroupMemberProfile(name: '나', note: '참여 중', statusLabel: '참여 중'),
    ];
    _membersByGroupId[3] = [
      GroupMemberProfile(name: '민서', note: '보드게임 추천 중', statusLabel: '참여 중'),
      GroupMemberProfile(name: '지훈', note: '장소 후보 정리 중', statusLabel: '참여 중'),
      GroupMemberProfile(name: '나', note: '참여 중', statusLabel: '참여 중'),
    ];

    _messagesByGroupId[1] = [
      GroupMessage(
        sender: '지민',
        message: '다들 안녕! 드디어 다음 주에 제주도네 날씨도 좋아 보이더라구.',
        timeLabel: '오전 9:21',
        isMine: false,
      ),
      GroupMessage(
        sender: '나',
        message: '기대된다아 ㅎㅎ',
        timeLabel: '오전 9:22',
        isMine: true,
      ),
      GroupMessage(
        sender: '현우',
        message: '항공권 모바일 체크인 했어! 좌석도 다 같이 앉도록 해봤음 ㅎㅎ',
        timeLabel: '오전 9:24',
        isMine: false,
      ),
      GroupMessage(
        sender: 'ONMU',
        message: '장소 후보가 3개 모였어요. 필요하면 투표를 만들어 함께 정해요.',
        timeLabel: '오전 9:25',
        isMine: false,
      ),
    ];
    _messagesByGroupId[2] = [
      GroupMessage(
        sender: '서윤',
        message: '오늘은 19:30 출발로 맞춰둘게.',
        timeLabel: '오후 4:10',
        isMine: false,
      ),
    ];
    _messagesByGroupId[3] = [
      GroupMessage(
        sender: '민서',
        message: '온무식당 쪽으로 저녁 먼저 먹고 갈까?',
        timeLabel: '오후 1:18',
        isMine: false,
      ),
    ];

    _memoriesByGroupId[1] = [
      GroupMemoryRecord(
        id: 1001,
        author: '지연',
        title: '성수동 카페',
        description: '분위기 좋은 카페 발견! 디저트도 너무 맛있었어요.',
        dateLabel: '2024.05.24',
        tags: ['카페', '사진', '디저트'],
      ),
      GroupMemoryRecord(
        id: 1002,
        author: '민수',
        title: '제주 바다',
        description: '바다 색이 진짜 예뻤던 날.',
        dateLabel: '2024.05.16',
        tags: ['여행', '사진', '바다'],
      ),
      GroupMemoryRecord(
        id: 1003,
        author: '하린',
        title: '전시회 다녀왔어요',
        description: '조용히 둘러보기 좋았던 전시.',
        dateLabel: '2024.05.10',
        tags: ['기타', '기록', '전시'],
      ),
      GroupMemoryRecord(
        id: 1004,
        author: '현우',
        title: '한강 피크닉',
        description: '다음에도 같이 가자!',
        dateLabel: '2024.05.10',
        tags: ['여행', '사진', '피크닉'],
      ),
    ];
    _memoriesByGroupId[2] = [
      GroupMemoryRecord(
        id: 1005,
        author: '서윤',
        title: '여의도 러닝',
        description: '강변 코스 5km를 함께 달렸어요.',
        dateLabel: '2024.05.27',
        tags: ['운동', '기록', '러닝'],
      ),
    ];
    _memoriesByGroupId[3] = [];
  }

  void _seedPlans() {
    _pinnedPlansByGroupId[1] = GroupPinnedPlan(
      id: 101,
      title: '제주도 여행',
      dateLabel: '6.7(토) - 6.9(월)',
      placeName: '제주도 일대',
      statusLabel: 'D-12',
      voteSummary: '4명 참여',
    );

    _plansByGroupId[1] = [
      GroupPlanSummary(
        id: 101,
        title: '제주도 여행',
        dateLabel: '6.7 (금) - 6.9 (일)',
        startsAt: _relativeSeedPlanDateTime(daysFromToday: -5, hour: 10),
        placeName: '제주도 일대',
        statusLabel: 'D-12',
        statusType: '진행중',
        memberCount: 6,
        extraMemberCount: 2,
        iconKind: 'water',
        isPast: false,
      ),
      GroupPlanSummary(
        id: 102,
        title: '한남 카페 투어',
        dateLabel: '6.5 (수) 오후 2:00',
        startsAt: _relativeSeedPlanDateTime(daysFromToday: -3, hour: 14),
        placeName: '한남동 일대',
        statusLabel: 'D-2',
        statusType: '예정',
        memberCount: 5,
        extraMemberCount: 1,
        iconKind: 'coffee',
        isPast: false,
      ),
      GroupPlanSummary(
        id: 104,
        title: '홍대 전시회 구경',
        dateLabel: '6.12 (수) 오후 2:00',
        startsAt: _relativeSeedPlanDateTime(daysFromToday: 1, hour: 14),
        placeName: '홍대 일대',
        statusLabel: 'D-4',
        statusType: '예정',
        memberCount: 3,
        extraMemberCount: 0,
        iconKind: 'gallery',
        isPast: false,
      ),
      GroupPlanSummary(
        id: 105,
        title: '성수 디저트 모임',
        dateLabel: '6.17 (월) 오후 7:00',
        startsAt: _relativeSeedPlanDateTime(daysFromToday: 6, hour: 19),
        placeName: '성수동',
        statusLabel: 'D-17',
        statusType: '예정',
        memberCount: 3,
        extraMemberCount: 0,
        iconKind: 'coffee',
        isPast: false,
      ),
      GroupPlanSummary(
        id: 103,
        title: '한강 피크닉',
        dateLabel: '5.10 (금) 오후 1:00',
        startsAt: _relativeSeedPlanDateTime(daysFromToday: -30, hour: 13),
        placeName: '여의도 한강공원',
        statusLabel: '완료',
        statusType: '완료',
        memberCount: 4,
        extraMemberCount: 0,
        iconKind: 'park',
        isPast: true,
      ),
    ];
    _plansByGroupId[2] = [];
    _plansByGroupId[3] = [];

    for (final summary in _plansByGroupId[1]!) {
      _plansById[summary.id] = Plan(
        id: summary.id,
        title: summary.title,
        dateTime: summary.dateLabel,
        location: summary.placeName,
        status: summary.statusType,
        memo: '편한 복장으로 오기! 돗자리 챙기면 좋을 것 같아요.',
        members: _seedPlanMembers(),
        timeCandidates: _seedTimeCandidates(),
        visitPlan: _seedVisitPlan(),
        startsAt: summary.startsAt,
      );
      _visitPlansByPlanId[summary.id] = [
        List.unmodifiable(_seedVisitPlan()),
        List.unmodifiable(_seedSecondDayVisitPlan()),
        List.unmodifiable(_seedThirdDayVisitPlan()),
      ];
    }
  }

  void _seedPlaces() {
    final candidates = _createPlaceCandidates();

    for (final planId in [101, 102, 103, 104, 105]) {
      _candidatesByPlanId[planId] = candidates;
      _voteResultsByPlanId[planId] = _createPlaceVoteResult();
      _risksByPlanId[planId] = _createPlaceRisks();
    }
  }

  List<PlaceCandidate> _createPlaceCandidates() {
    return [
      PlaceCandidate(
        id: 201,
        name: '온무식당',
        category: '한식',
        summary: '영업중 · 브레이크타임 없음',
        score: 92,
        matchPercent: 88,
        distanceLabel: '홍대입구역 도보 7분',
        travelTimeLabel: '도보 7분',
        priceLabel: '1인 16,000원대',
        isOpen: true,
        address: '서울 마포구 와우산로 24',
        openingLabel: '오늘 11:30-21:00 · LO 20:30',
        sourceLabel: 'Kakao Places · 2시간 전 동기화',
        riskLabel: '안정',
        riskTone: 'none',
        memberFits: [
          MemberFit(label: 'A', score: 95, note: '조용한, 담백한'),
          MemberFit(label: 'B', score: 88, note: '한식, 웨이팅 짧음'),
          MemberFit(label: 'C', score: 91, note: '단체 가능'),
          MemberFit(label: 'D', score: 76, note: '매운 메뉴 적음'),
        ],
        tags: ['조용한', '한식', '단체가능'],
        reasons: [
          '평균 점수와 운영 안정성이 가장 높아요.',
          '약속 시간과 영업시간 충돌이 없어요.',
          '참여자 네 명 모두 76점 이상이에요.',
        ],
        risks: ['운영 리스크 없음'],
      ),
      PlaceCandidate(
        id: 202,
        name: '무드카페',
        category: '카페',
        summary: '라스트오더 19:30 임박',
        score: 84,
        matchPercent: 82,
        distanceLabel: '합정역 도보 5분',
        travelTimeLabel: '도보 5분',
        priceLabel: '1인 12,000원대',
        isOpen: true,
        address: '서울 마포구 독막로 17',
        openingLabel: '오늘 12:00-20:00 · LO 19:30',
        sourceLabel: 'Naver Places · 12일 전 동기화',
        riskLabel: '주의',
        riskTone: 'medium',
        memberFits: [
          MemberFit(label: 'A', score: 82, note: '디저트'),
          MemberFit(label: 'B', score: 91, note: '역 가까움'),
          MemberFit(label: 'C', score: 77, note: '뷰 좋은'),
          MemberFit(label: 'D', score: 70, note: '웨이팅 있음'),
        ],
        tags: ['디저트', '뷰좋은', '웨이팅'],
        reasons: [
          '합정역에서 가장 가까워요.',
          '디저트 취향 멤버에게 잘 맞아요.',
          '라스트오더까지 여유가 짧아 확인이 필요해요.',
        ],
        risks: ['라스트오더 충돌 가능성', '운영시간 정보 오래됨'],
      ),
      PlaceCandidate(
        id: 203,
        name: '하루정원',
        category: '카페',
        summary: '마지막 동기화 12일 전',
        score: 79,
        matchPercent: 74,
        distanceLabel: '홍대입구역 도보 11분',
        travelTimeLabel: '도보 11분',
        priceLabel: '1인 14,000원대',
        isOpen: false,
        address: '서울 마포구 양화로 8',
        openingLabel: '영업시간 확인 필요',
        sourceLabel: 'Google Places · 12일 전 동기화',
        riskLabel: '확인필요',
        riskTone: 'unknown',
        memberFits: [
          MemberFit(label: 'A', score: 78, note: '디저트'),
          MemberFit(label: 'B', score: 73, note: '조용한'),
          MemberFit(label: 'C', score: 70, note: '사진맛집'),
          MemberFit(label: 'D', score: 66, note: '확인 필요'),
        ],
        tags: ['확인 필요', '뷰좋은', '디저트'],
        reasons: [
          '사진 기록과 잘 어울리는 공간이에요.',
          '디저트 선택지는 많지만 정보가 오래됐어요.',
          '방문 전 직접 확인이 필요해요.',
        ],
        risks: ['운영시간 정보 오래됨', '휴무일 가능성'],
      ),
    ];
  }

  PlaceVoteResult _createPlaceVoteResult() {
    return PlaceVoteResult(
      title: '온모임 투표 결과',
      selectedPlaceName: '온무식당',
      voters: ['민서', '지훈', '하린'],
      note: '온모임에서 3명이 안정적인 한식 장소에 투표했어요. 후보 상단에 이어서 보여줍니다.',
    );
  }

  List<PlaceRisk> _createPlaceRisks() {
    return [
      PlaceRisk(
        title: '라스트오더 충돌 가능성',
        description: '예상 도착 19:20, 라스트오더 19:30이라 여유 시간이 10분뿐이에요.',
        level: PlaceRiskLevel.blocker,
        actionLabel: '그래도 후보 추가',
        evidence: '지도 API · 2026.05.19 갱신',
      ),
      PlaceRisk(
        title: '운영시간 정보 오래됨',
        description: '마지막 동기화 12일 전이라 방문 전 직접 확인을 권장합니다.',
        level: PlaceRiskLevel.warning,
        actionLabel: '전화 확인',
        evidence: '장소 공지 링크 있음 · 신뢰도 0.72',
      ),
      PlaceRisk(
        title: '비선호 키워드 확인',
        description: '참여자 비선호 키워드인 견과류 메뉴가 일부 리뷰에 반복 등장했어요.',
        level: PlaceRiskLevel.notice,
        actionLabel: '메뉴 보기',
        evidence: '사용자 리뷰 · 최근 30일',
      ),
    ];
  }

  void _seedVotes() {
    _votesByGroupId[1] = [
      VoteSummary(
        id: 501,
        title: '제주도 여행 장소 투표',
        statusLabel: '진행 중',
        description: '카페 오션뷰 외 2곳 · 4명 참여',
        planLabel: '제주도 여행',
        planMeta: '6.7 - 6.9 · 제주도 일대',
        participants: ['지민', '민수', '하린', '현우'],
        options: [
          VoteOptionSummary(label: '카페 오션뷰', countLabel: '3표', progress: 0.78),
          VoteOptionSummary(
            label: '흑돼지 맛집 돈사돈',
            countLabel: '2표',
            progress: 0.56,
          ),
          VoteOptionSummary(label: '협재 해수욕장', countLabel: '1표', progress: 0.32),
        ],
        closed: false,
        joinedByMe: true,
        actionLabel: '투표 확인하기',
      ),
      VoteSummary(
        id: 502,
        title: '성수 카페 투어 시간 정하기',
        statusLabel: '오늘 마감',
        description: '오후 2시 / 4시 / 6시 · 5명 참여',
        planLabel: '성수 카페 투어',
        planMeta: '6.5 오후 2:00 · 성수동 일대',
        participants: ['지연', '민수', '하린'],
        options: [
          VoteOptionSummary(label: '오후 2시', countLabel: '3표', progress: 0.64),
          VoteOptionSummary(label: '오후 4시', countLabel: '2표', progress: 0.46),
        ],
        closed: false,
        joinedByMe: false,
        actionLabel: '결과 보기',
      ),
      VoteSummary(
        id: 503,
        title: '한강 피크닉 메뉴',
        statusLabel: '마감',
        description: '김밥과 샌드위치가 최종 선택됐어요',
        planLabel: '한강 피크닉',
        planMeta: '5.10 오후 1:00 · 여의도 한강공원',
        participants: ['지민', '하린', '현우'],
        options: [
          VoteOptionSummary(label: '김밥', countLabel: '4표', progress: 0.86),
          VoteOptionSummary(label: '샌드위치', countLabel: '3표', progress: 0.68),
        ],
        closed: true,
        joinedByMe: true,
        actionLabel: '결과 보기',
      ),
      VoteSummary(
        id: 504,
        title: '보드게임 모임 장소',
        statusLabel: '마감',
        description: '홍대 보드게임카페로 정했어요',
        planLabel: '보드게임 모임',
        planMeta: '5.5 오후 6:00 · 홍대 일대',
        participants: ['민서', '지훈'],
        options: [
          VoteOptionSummary(
            label: '홍대 보드게임카페',
            countLabel: '5표',
            progress: 0.92,
          ),
          VoteOptionSummary(label: '연남동 카페', countLabel: '2표', progress: 0.34),
        ],
        closed: true,
        joinedByMe: false,
        actionLabel: '결과 보기',
      ),
    ];
    _votesByGroupId[2] = [];
    _votesByGroupId[3] = [];

    _voteCardsByVoteId[501] = VoteCard(
      title: '제주도 여행 장소 투표',
      summary: '카페 오션뷰, 흑돼지 맛집 돈사돈, 협재 해수욕장 후보를 비교 중이에요.',
      statusLabel: '수동 투표 · 진행 중',
      actionLabel: '투표 보기',
    );
    _voteCardsByVoteId[502] = VoteCard(
      title: '성수 카페 투어 시간 정하기',
      summary: '오후 2시 / 4시 / 6시 중 가능한 시간을 고르고 있어요.',
      statusLabel: '진행 중',
      actionLabel: '투표 보기',
    );
    _voteCardsByVoteId[503] = VoteCard(
      title: '한강 피크닉 메뉴',
      summary: '김밥과 샌드위치가 최종 선택됐어요.',
      statusLabel: '마감',
      actionLabel: '결과 보기',
    );
    _voteCardsByVoteId[504] = VoteCard(
      title: '보드게임 모임 장소',
      summary: '홍대 보드게임카페로 정했어요.',
      statusLabel: '마감',
      actionLabel: '결과 보기',
    );
    _voteVotersByVoteId[501] = {
      201: ['민서', '하린'],
      202: ['지훈'],
    };
  }

  void _seedSettlement() {
    final allParticipants = [
      SettlementPaymentParticipant(name: '지민', owedAmountLabel: '20,667원'),
      SettlementPaymentParticipant(name: '민수', owedAmountLabel: '20,667원'),
      SettlementPaymentParticipant(name: '소연', owedAmountLabel: '20,667원'),
      SettlementPaymentParticipant(name: '현우', owedAmountLabel: '20,667원'),
      SettlementPaymentParticipant(name: '준호', owedAmountLabel: '20,666원'),
      SettlementPaymentParticipant(name: '혜진', owedAmountLabel: '20,666원'),
    ];

    final settlement = SettlementSummary(
      id: 301,
      planTitle: '주말 나들이',
      totalAmountLabel: '186,000원',
      createdDateLabel: '정산일 2025.05.28',
      itemCountLabel: '결제 항목 2개',
      finalSummaryLabel: '4명이 송금 필요',
      mySummaryLabel: '나는 103,333원을 받아요',
      paymentItems: [
        SettlementPaymentItem(
          id: 401,
          title: '저녁',
          amountLabel: '124,000원',
          payerShares: [
            SettlementPayerShare(name: '지민', amountLabel: '124,000원'),
          ],
          targetLabel: '6명',
          splitType: SettlementSplitType.equal,
          participants: allParticipants,
        ),
        SettlementPaymentItem(
          id: 402,
          title: '카페',
          amountLabel: '62,000원',
          payerShares: [
            SettlementPayerShare(name: '민수', amountLabel: '42,000원'),
            SettlementPayerShare(name: '지민', amountLabel: '20,000원'),
          ],
          targetLabel: '4명',
          splitType: SettlementSplitType.custom,
          participants: [
            SettlementPaymentParticipant(
              name: '지민',
              owedAmountLabel: '20,000원',
            ),
            SettlementPaymentParticipant(
              name: '민수',
              owedAmountLabel: '18,000원',
            ),
            SettlementPaymentParticipant(
              name: '소연',
              owedAmountLabel: '12,000원',
            ),
            SettlementPaymentParticipant(
              name: '현우',
              owedAmountLabel: '12,000원',
            ),
            SettlementPaymentParticipant(
              name: '준호',
              owedAmountLabel: '-',
              included: false,
            ),
            SettlementPaymentParticipant(
              name: '혜진',
              owedAmountLabel: '-',
              included: false,
            ),
          ],
        ),
      ],
      memberResults: [
        SettlementMemberResult(
          name: '지민 (나)',
          finalShareLabel: '40,667원',
          paidAmountLabel: '144,000원',
          resultLabel: '103,333원 받음',
          isMe: true,
          willReceive: true,
        ),
        SettlementMemberResult(
          name: '민수',
          finalShareLabel: '38,667원',
          paidAmountLabel: '42,000원',
          resultLabel: '3,333원 받음',
          willReceive: true,
        ),
        SettlementMemberResult(
          name: '소연',
          finalShareLabel: '32,667원',
          paidAmountLabel: '0원',
          resultLabel: '지민에게 32,667원',
        ),
        SettlementMemberResult(
          name: '현우',
          finalShareLabel: '32,667원',
          paidAmountLabel: '0원',
          resultLabel: '지민에게 32,667원',
        ),
        SettlementMemberResult(
          name: '준호',
          finalShareLabel: '20,666원',
          paidAmountLabel: '0원',
          resultLabel: '지민에게 20,666원',
        ),
        SettlementMemberResult(
          name: '혜진',
          finalShareLabel: '20,666원',
          paidAmountLabel: '0원',
          resultLabel: '지민에게 17,333원 · 민수에게 3,333원',
        ),
      ],
      transfers: [
        SettlementTransferSummary(
          fromName: '소연',
          toName: '지민',
          amountLabel: '32,667원',
        ),
        SettlementTransferSummary(
          fromName: '현우',
          toName: '지민',
          amountLabel: '32,667원',
        ),
        SettlementTransferSummary(
          fromName: '준호',
          toName: '지민',
          amountLabel: '20,666원',
        ),
        SettlementTransferSummary(
          fromName: '혜진',
          toName: '지민',
          amountLabel: '17,333원',
        ),
        SettlementTransferSummary(
          fromName: '혜진',
          toName: '민수',
          amountLabel: '3,333원',
        ),
      ],
      shareMessage: '주말 나들이 약속 정산입니다. 최종 송금 금액만 확인해 주세요.',
    );

    for (final planId in [101, 102, 103, 104, 105]) {
      _settlementsByPlanId[planId] = settlement;
    }
  }

  List<PlanMember> _seedPlanMembers() {
    return [
      PlanMember(
        name: '연우',
        message: '가고싶다 했어요!',
        badge: '방문지 제안',
        selected: false,
      ),
      PlanMember(
        name: '지영',
        message: '카페 투어 좋아해요',
        badge: '선택됨',
        selected: true,
      ),
      PlanMember(
        name: '민수',
        message: '이번엔 내가 추천할게!',
        badge: '시간 제안',
        selected: true,
      ),
      PlanMember(
        name: '준호',
        message: '매운 음식은 피하고 싶어요',
        badge: '초대',
        selected: false,
      ),
      PlanMember(name: '하린', message: '좋아요 좋아요', badge: '선택됨', selected: true),
      PlanMember(
        name: '서준',
        message: '이번엔 시간이 될지...',
        badge: '초대',
        selected: false,
      ),
    ];
  }

  List<TimeCandidate> _seedTimeCandidates() {
    return [
      TimeCandidate(
        time: '12:00',
        range: '~ 14:00',
        status: '모두 가능',
        description: '점심부터 여유롭게 시작할 수 있어요.',
        countLabel: '4/4',
        recommended: false,
      ),
      TimeCandidate(
        time: '13:00',
        range: '~ 15:00',
        status: '모두 가능',
        description: '가장 많은 친구들이 가능한 시간이에요!',
        countLabel: '4/4',
        recommended: true,
      ),
      TimeCandidate(
        time: '15:00',
        range: '~ 17:00',
        status: '일부만 가능',
        description: '2명의 친구가 일정이 있어요.',
        countLabel: '2/4',
        recommended: false,
      ),
      TimeCandidate(
        time: '18:00',
        range: '~ 20:00',
        status: '보통 어려워요',
        description: '3명의 친구가 일정이 있어요.',
        countLabel: '1/4',
        recommended: false,
      ),
    ];
  }

  List<VisitPlan> _seedVisitPlan() {
    return [
      VisitPlan(
        time: '13:00',
        endTime: '14:30',
        place: '다운타우너 성수',
        kind: '카페',
        duration: '1시간 30분',
      ),
      VisitPlan(
        time: '14:45',
        endTime: '16:15',
        place: '연무장길 카페거리',
        kind: '카페',
        duration: '1시간 30분',
      ),
      VisitPlan(
        time: '16:30',
        endTime: '17:30',
        place: '성수연방',
        kind: '음식점',
        duration: '1시간',
      ),
      VisitPlan(
        time: '17:40',
        endTime: '19:00',
        place: '서울숲 산책',
        kind: '볼거리',
        duration: '1시간 20분',
      ),
    ];
  }

  List<VisitPlan> _seedSecondDayVisitPlan() {
    return [
      VisitPlan(
        time: '10:30',
        endTime: '12:00',
        place: '협재 해수욕장',
        kind: '관광',
        duration: '1시간 30분',
      ),
      VisitPlan(
        time: '12:20',
        endTime: '13:40',
        place: '한림 흑돼지 식당',
        kind: '식사',
        duration: '1시간 20분',
      ),
      VisitPlan(
        time: '14:10',
        endTime: '16:00',
        place: '카페 오션뷰',
        kind: '카페',
        duration: '1시간 50분',
      ),
    ];
  }

  List<VisitPlan> _seedThirdDayVisitPlan() {
    return [
      VisitPlan(
        time: '09:30',
        endTime: '11:00',
        place: '오름 산책로',
        kind: '산책',
        duration: '1시간 30분',
      ),
      VisitPlan(
        time: '11:30',
        endTime: '13:00',
        place: '동문시장',
        kind: '식사',
        duration: '1시간 30분',
      ),
    ];
  }
}
