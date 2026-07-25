import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onmu_mobile/features/auth/data/auth_token_store.dart';
import 'package:onmu_mobile/features/auth/data/social_auth_service.dart';
import 'package:onmu_mobile/features/auth/domain/auth_session.dart';
import 'package:onmu_mobile/features/auth/domain/auth_user.dart';
import 'package:onmu_mobile/features/auth/domain/oauth_provider_credential.dart';
import 'package:onmu_mobile/features/auth/providers/auth_providers.dart';
import 'package:onmu_mobile/features/auth/repository/auth_repository.dart';
import 'package:onmu_mobile/features/character/repository/character_repository.dart';
import 'package:onmu_mobile/features/group/repository/group_repository.dart';
import 'package:onmu_mobile/features/home/repository/home_repository.dart';
import 'package:onmu_mobile/features/home/repository/notification_repository.dart';
import 'package:onmu_mobile/features/my/domain/my_profile.dart';
import 'package:onmu_mobile/features/my/repository/friend_repository.dart';
import 'package:onmu_mobile/features/my/repository/my_repository.dart';
import 'package:onmu_mobile/features/ootd/repository/record_repository.dart';
import 'package:onmu_mobile/features/place/repository/place_repository.dart';
import 'package:onmu_mobile/features/plan/repository/plan_repository.dart';
import 'package:onmu_mobile/features/settlement/repository/settlement_repository.dart';
import 'package:onmu_mobile/shared/models/group_models.dart';
import 'package:onmu_mobile/shared/models/notification_models.dart';
import 'package:onmu_mobile/shared/models/ootd_model.dart';
import 'package:onmu_mobile/shared/models/place_models.dart';
import 'package:onmu_mobile/shared/models/plan_models.dart';
import 'package:onmu_mobile/shared/models/preference_profile.dart';
import 'package:onmu_mobile/shared/models/settlement_models.dart';
import 'package:onmu_mobile/shared/models/vote_models.dart';
import 'package:onmu_mobile/shared/models/character_model.dart';
import 'package:onmu_mobile/shared/providers/state_providers.dart';

import 'in_memory_onmu_store.dart';

ProviderContainer createOnmuTestContainer() {
  final store = InMemoryOnmuStore.seeded();
  final groupRepository = TestGroupRepository(store);
  return ProviderContainer(
    overrides: [
      authTokenStoreProvider.overrideWithValue(InMemoryAuthTokenStore()),
      authRepositoryProvider.overrideWithValue(const TestAuthRepository()),
      socialAuthServiceProvider.overrideWithValue(testSocialAuthService()),
      groupRepositoryProvider.overrideWithValue(groupRepository),
      homeRepositoryProvider.overrideWithValue(
        TestHomeRepository(groupRepository),
      ),
      planRepositoryProvider.overrideWithValue(TestPlanRepository(store)),
      placeRepositoryProvider.overrideWithValue(TestPlaceRepository(store)),
      settlementRepositoryProvider.overrideWithValue(
        TestSettlementRepository(store),
      ),
      notificationRepositoryProvider.overrideWithValue(
        TestNotificationRepository(store),
      ),
      recordRepositoryProvider.overrideWithValue(TestRecordRepository()),
      friendRepositoryProvider.overrideWithValue(TestFriendRepository()),
      myRepositoryProvider.overrideWithValue(TestMyRepository()),
      characterRepositoryProvider.overrideWithValue(TestCharacterRepository()),
    ],
  );
}

ProviderScope onmuTestProviderScope({
  required Widget child,
  AuthUser? user,
  GroupRepository? groupRepository,
  SettlementRepository? settlementRepository,
  FriendRepository? friendRepository,
  MyRepository? myRepository,
  RecordRepository? recordRepository,
  PreferenceProfile? preferenceProfile,
  InMemoryOnmuStore? store,
}) {
  final testStore = store ?? InMemoryOnmuStore.seeded();
  final resolvedGroupRepository =
      groupRepository ?? TestGroupRepository(testStore);
  return ProviderScope(
    overrides: [
      authTokenStoreProvider.overrideWithValue(InMemoryAuthTokenStore()),
      authRepositoryProvider.overrideWithValue(TestAuthRepository(user)),
      if (user != null) authUserProvider.overrideWith((ref) => user),
      socialAuthServiceProvider.overrideWithValue(testSocialAuthService()),
      groupRepositoryProvider.overrideWithValue(resolvedGroupRepository),
      homeRepositoryProvider.overrideWithValue(
        TestHomeRepository(resolvedGroupRepository),
      ),
      planRepositoryProvider.overrideWithValue(TestPlanRepository(testStore)),
      placeRepositoryProvider.overrideWithValue(TestPlaceRepository(testStore)),
      settlementRepositoryProvider.overrideWithValue(
        settlementRepository ?? TestSettlementRepository(testStore),
      ),
      notificationRepositoryProvider.overrideWithValue(
        TestNotificationRepository(testStore),
      ),
      recordRepositoryProvider.overrideWithValue(
        recordRepository ?? TestRecordRepository(),
      ),
      friendRepositoryProvider.overrideWithValue(
        friendRepository ?? TestFriendRepository(),
      ),
      myRepositoryProvider.overrideWithValue(
        myRepository ?? TestMyRepository(),
      ),
      characterRepositoryProvider.overrideWithValue(TestCharacterRepository()),
      if (preferenceProfile != null)
        preferenceProfileProvider.overrideWith((ref) => preferenceProfile),
    ],
    child: child,
  );
}

class TestHomeRepository implements HomeRepository {
  TestHomeRepository(this._groupRepository);

  final GroupRepository _groupRepository;

  @override
  Future<HomeSummary> fetchSummary() async {
    final groups = await _groupRepository.fetchGroups();
    final plans = <GroupPlanSummary>[];
    for (final group in groups) {
      plans.addAll(await _groupRepository.fetchPlans(group.id));
    }
    plans.sort(GroupPlanSummary.compareUpcoming);

    final now = DateTime.now();
    GroupPlanSummary? activePlan;
    for (final plan in plans) {
      if (plan.isOngoingAt(now)) {
        activePlan = plan;
        break;
      }
    }

    return HomeSummary(
      groups: groups,
      upcomingPlans: plans,
      nextPlan: plans.isEmpty ? null : plans.first,
      activePlan: activePlan,
      settlementId: activePlan?.settlementId ?? '',
    );
  }
}

class TestMyRepository implements MyRepository {
  TestMyRepository({
    MyProfile? profile,
    this.failUpdates = false,
    this.updateProfileGate,
  }) : _profile = profile ?? _defaultProfile;

  static const _defaultProfile = MyProfile(
    realName: 'ONMU User',
    visibility: ProfileVisibility.friends,
    favoriteKeywords: [],
    dislikedKeywords: [],
    preferredTimes: [],
    availableDays: [],
    unavailableDates: [],
    favoritePlaces: [],
    wantToGoPlaces: [],
    dislikedPlaces: [],
  );

  MyProfile _profile;
  final bool failUpdates;
  final Completer<void>? updateProfileGate;
  String? lastOnboardingStatus;
  MyProfile? lastUpdatedProfile;
  var updateProfileCallCount = 0;

  @override
  Future<MyProfile> fetchMyProfile() async => _profile;

  @override
  Future<MyProfile> updateMyProfile(
    MyProfile profile, {
    String? onboardingStatus,
  }) async {
    updateProfileCallCount += 1;
    lastUpdatedProfile = profile;
    lastOnboardingStatus = onboardingStatus;
    await updateProfileGate?.future;
    if (failUpdates) {
      throw StateError('profile update failed');
    }
    _profile = profile;
    return _profile;
  }

  @override
  Future<MyProfile> updateOnboardingStatus(String onboardingStatus) async {
    lastOnboardingStatus = onboardingStatus;
    return _profile;
  }

  @override
  Future<String> uploadProfileImage(Uint8List bytes, String fileName) async {
    return 'https://example.test/$fileName';
  }
}

class TestFriendRepository implements FriendRepository {
  TestFriendRepository({List<FriendProfile>? friends})
    : _friends = friends ?? const [];

  final List<FriendProfile> _friends;

  @override
  Future<List<FriendProfile>> fetchFriends() async => _friends;

  @override
  Future<List<FriendProfile>> searchFriends(String query) async {
    final normalized = query.trim().toLowerCase();
    if (normalized.length < 2) {
      return const [];
    }
    return _friends
        .where(
          (friend) =>
              friend.name.toLowerCase().contains(normalized) ||
              friend.userCode.toLowerCase().contains(normalized) ||
              friend.publicId.toLowerCase().contains(normalized),
        )
        .toList(growable: false);
  }

  @override
  Future<MyProfile> fetchFriendProfile(FriendProfile friend) async {
    return MyProfile(
      realName: friend.name,
      introText: friend.preferenceSummary,
      visibility: ProfileVisibility.friends,
      favoriteKeywords: const [],
      dislikedKeywords: const [],
      preferredTimes: const [],
      availableDays: const [],
      unavailableDates: const [],
      favoritePlaces: const [],
      wantToGoPlaces: const [],
      dislikedPlaces: const [],
      character: friend.character,
    );
  }

  @override
  Future<FriendProfile> addFriend(String publicId, {String? memo}) async {
    return FriendProfile(
      publicId: publicId,
      userCode: publicId,
      name: publicId,
      preferenceSummary: '',
      isFriend: true,
      memo: memo ?? '',
    );
  }

  @override
  Future<FriendProfile> updateFriend(
    FriendProfile friend, {
    String? memo,
    bool? favorite,
  }) async {
    return friend.copyWith(memo: memo, isFavorite: favorite);
  }

  @override
  Future<void> deleteFriend(FriendProfile friend) async {}
}

class TestCharacterRepository implements CharacterRepository {
  CharacterDraft? _draft;

  @override
  Future<CharacterDraft?> fetchMyCharacter() async => _draft;

  @override
  Future<CharacterDraft> saveMyCharacter(CharacterDraft draft) async {
    _draft = draft;
    return draft;
  }
}

class TestRecordRepository implements RecordRepository {
  @override
  Future<List<CrewOotdAppearance>> fetchCrewOotdAppearances({
    required String groupId,
    required String planId,
    required DateTime date,
  }) async {
    return const [];
  }

  TestRecordRepository({List<OotdRecord>? records})
    : _records = List.of(records ?? defaultRecords);

  static final defaultRecords = [
    OotdRecord(
      id: 'record-hangang-picnic',
      date: DateTime(2026, 6, 10, 10),
      character: const CharacterDraft(),
      moodTags: const ['피크닉', '한강'],
      brands: const {
        'recordType': 'daily',
        'title': '한강 피크닉 기록',
        'weather': 'sunny',
        'bgColorIndex': '99',
      },
      weather: 'sunny',
      mood: 'calm',
      timeline: const [
        TimelineItem(
          time: '10:00',
          placeName: '여의도 한강공원',
          category: 'daily',
          description: '돗자리 펴고 같이 남긴 기록',
        ),
      ],
    ),
    OotdRecord(
      id: 'record-seongsu-dessert',
      date: DateTime(2026, 6, 8, 15),
      character: const CharacterDraft(topStyleIndex: 1),
      moodTags: const ['디저트', '성수'],
      brands: const {
        'recordType': 'ootd',
        'title': '성수 디저트룩',
        'weather': 'cloudy',
        'bgColorIndex': '2',
      },
      weather: 'cloudy',
      mood: 'happy',
      timeline: const [
        TimelineItem(
          time: '15:00',
          placeName: '성수동',
          category: 'ootd',
          description: '디저트 모임 착장',
        ),
      ],
    ),
  ];

  final List<OotdRecord> _records;

  @override
  Future<List<OotdRecord>> fetchMyRecords() async {
    return List.unmodifiable(_records);
  }

  @override
  Future<OotdRecord> createRecord(OotdRecord record) async {
    final saved = record.id == null || record.id!.isEmpty
        ? record.copyWith(id: 'record-${_records.length + 1}')
        : record;
    _records.insert(0, saved);
    return saved;
  }

  @override
  Future<OotdRecord> createGroupRecord({
    required Object groupId,
    required OotdRecord record,
  }) {
    return createRecord(record);
  }

  @override
  Future<OotdRecord> fetchRecord(String id) async {
    return _records.firstWhere((record) => record.id == id);
  }

  @override
  Future<OotdRecord> updateRecord(String id, OotdRecord record) async {
    final index = _records.indexWhere((item) => item.id == id);
    final updated = record.copyWith(id: id);
    if (index < 0) {
      _records.insert(0, updated);
      return updated;
    }
    _records[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteRecord(String id) async {
    _records.removeWhere((record) => record.id == id);
  }

  @override
  Future<UploadedMedia> uploadMedia(Uint8List bytes, String fileName) async {
    return UploadedMedia(
      storageKey: 'records/media/$fileName',
      publicUrl: 'https://cdn.onmu.test/$fileName',
    );
  }

  @override
  Future<OotdAvatarGenerationJob> createAvatarGeneration({
    required String recordId,
    required String inputType,
    required String weather,
    required String mood,
    String? outfitPhotoMediaId,
    String? outfitPhotoStorageKey,
    String? outfitDescription,
    CharacterDraft? characterOverrides,
  }) async {
    return OotdAvatarGenerationJob(
      jobId: 'job-test',
      status: 'COMPLETED',
      recordId: recordId,
      generatedImageUrl: 'https://cdn.onmu.test/generated-ootd.png',
    );
  }

  @override
  Future<OotdAvatarGenerationJob> fetchAvatarGeneration(String jobId) async {
    return OotdAvatarGenerationJob(
      jobId: jobId,
      status: 'COMPLETED',
      recordId: 'record-test',
      generatedImageUrl: 'https://cdn.onmu.test/generated-ootd.png',
    );
  }
}

class TestNotificationRepository implements NotificationRepository {
  TestNotificationRepository(this._store);

  final InMemoryOnmuStore _store;

  @override
  Future<List<NotificationItem>> fetchNotifications({int? limit}) async {
    return _store.fetchNotifications(limit: limit);
  }

  @override
  Future<int> fetchUnreadCount() async {
    return _store.fetchUnreadNotificationCount();
  }

  @override
  Future<NotificationItem> markNotificationRead(String notificationId) async {
    return _store.markNotificationRead(notificationId);
  }

  @override
  Future<int> markAllNotificationsRead() async {
    return _store.markAllNotificationsRead();
  }

  @override
  Future<NotificationPreferences> fetchPreferences() async {
    return _store.fetchNotificationPreferences();
  }

  @override
  Future<NotificationPreferences> updatePreferences(
    List<NotificationPreferenceItem> preferences,
  ) async {
    return _store.updateNotificationPreferences(preferences);
  }

  @override
  Future<void> acceptFriendRequest(String requestId) async {}

  @override
  Future<void> declineFriendRequest(String requestId) async {}
}

SocialAuthService testSocialAuthService() {
  return SocialAuthService(
    naverCredentialLoader: () async => const OAuthProviderCredential(
      provider: 'naver',
      devVerifiedSubject: 'naver-dev-local-user',
      providerProfileName: '네이버 친구',
      email: 'naver-user@example.com',
    ),
  );
}

class TestAuthRepository implements AuthRepository {
  const TestAuthRepository([this.user]);

  final AuthUser? user;

  @override
  Future<AuthUser?> fetchCurrentUser() async => user;

  @override
  Future<OnmuAuthTokens?> refreshTokens(String refreshToken) async {
    return const OnmuAuthTokens(
      accessToken: 'test-onmu-access-jwt-refreshed',
      refreshToken: 'test-onmu-refresh-token-rotated',
    );
  }

  @override
  Future<AuthSession> exchangeOAuthLogin(
    OAuthProviderCredential credential,
  ) async {
    final provider = credential.provider.toUpperCase();
    final nickname = credential.providerProfileName?.trim().isNotEmpty == true
        ? credential.providerProfileName!.trim()
        : '테스트 사용자';
    return AuthSession(
      user: AuthUser(
        id: 'usr_test_oauth',
        publicId: 'usr_test_oauth',
        provider: provider,
        nickname: nickname,
        email: credential.email,
      ),
      tokens: const OnmuAuthTokens(
        accessToken: 'test-onmu-access-jwt',
        refreshToken: 'test-onmu-refresh-token',
      ),
    );
  }

  @override
  Future<void> logout(String? refreshToken) async {}

  @override
  Future<void> withdraw() async {}
}

class TestGroupRepository implements GroupRepository {
  TestGroupRepository(this._store);

  final InMemoryOnmuStore _store;

  @override
  Future<GroupSummary> fetchGroup(Object groupId) async {
    return _store.fetchGroup(groupId);
  }

  @override
  Future<GroupSummary> createGroup(GroupCreateInput input) async {
    return _store.createGroup(input);
  }

  @override
  Future<GroupSummary> updateGroup({
    required Object groupId,
    required String name,
    required String description,
  }) async {
    return _store.updateGroup(
      groupId: groupId,
      name: name,
      description: description,
    );
  }

  @override
  Future<void> leaveGroup(Object groupId) async {}

  @override
  Future<List<GroupSummary>> fetchGroups() async {
    return _store.fetchGroups();
  }

  @override
  Future<List<GroupPlanSummary>> fetchPlans(Object groupId) async {
    return _store.fetchGroupPlans(groupId);
  }

  @override
  Future<List<GroupMemoryRecord>> fetchMemories(Object groupId) async {
    return _store.fetchMemories(groupId);
  }

  @override
  Future<GroupMemoryRecord> createGroupMemory({
    required Object groupId,
    required GroupMemoryKind type,
    required String title,
    required String memo,
    DateTime? date,
  }) async {
    return _store.createGroupMemory(
      groupId: groupId,
      type: type,
      title: title,
      memo: memo,
      date: date,
    );
  }

  @override
  Future<GroupMemoryRecord> updateGroupMemory({
    required Object groupId,
    required Object memoryId,
    required GroupMemoryKind type,
    required String title,
    required String memo,
    DateTime? date,
  }) async {
    return GroupMemoryRecord(
      id: int.tryParse(memoryId.toString()) ?? 1,
      author: '테스트 사용자',
      title: title,
      description: memo,
      dateLabel: '2026.06.24',
      tags: [type.recordType],
      kind: type,
    );
  }

  @override
  Future<void> deleteGroupMemory({
    required Object groupId,
    required Object memoryId,
  }) async {}

  @override
  Future<List<GroupMemberProfile>> fetchMembers(Object groupId) async {
    return _store.fetchMembers(groupId);
  }

  @override
  Future<List<GroupMemberProfile>> fetchPlanParticipantCandidates({
    required Object groupId,
    required List<String> userIds,
  }) async {
    final normalizedUserIds = userIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    return _store
        .fetchMembers(groupId)
        .where((member) => normalizedUserIds.contains(member.userId.trim()))
        .toList(growable: false);
  }

  @override
  Future<GroupMemberProfile> addMember({
    required Object groupId,
    required String userId,
  }) async {
    return GroupMemberProfile(
      userId: userId,
      name: '초대 친구',
      note: '멤버',
      statusLabel: '참여 중',
    );
  }

  @override
  Future<List<GroupMessage>> fetchMessages(Object groupId) async {
    return _store.fetchMessages(groupId);
  }

  @override
  Future<GroupMessagePage> fetchMessagePage(
    Object groupId, {
    String? beforeCursor,
    int? limit,
  }) async {
    return _store.fetchMessagePage(
      groupId,
      beforeCursor: beforeCursor,
      limit: limit,
    );
  }

  @override
  Future<GroupMessage> sendMessage({
    required Object groupId,
    required String message,
    List<GroupMessageAttachment> attachments = const [],
  }) async {
    return _store.sendMessage(
      groupId: groupId,
      message: message,
      attachments: attachments,
    );
  }

  @override
  Future<int> markMessagesRead({
    required Object groupId,
    String? lastReadMessageId,
  }) async {
    return _store.markMessagesRead(
      groupId: groupId,
      lastReadMessageId: lastReadMessageId,
    );
  }

  @override
  Stream<GroupMessage> watchMessages(Object groupId, {String? afterCursor}) {
    return Stream<GroupMessage>.multi((_) {});
  }

  @override
  Future<GroupMemoryRecord> fetchMemory({
    required Object groupId,
    required Object memoryId,
  }) async {
    return _store.fetchMemory(groupId: groupId, memoryId: memoryId);
  }

  @override
  Future<GroupPinnedPlan?> fetchPinnedPlan(Object groupId) async {
    return _store.fetchPinnedPlan(groupId);
  }

  @override
  Future<List<VoteSummary>> fetchVotes(
    Object groupId, {
    String? targetType,
    Object? targetId,
  }) async {
    return _store.fetchVotes(
      groupId,
      targetType: targetType,
      targetId: targetId,
    );
  }

  @override
  Future<VoteSummary> createVote(VoteCreateInput input) async {
    return _store.createVote(input);
  }

  @override
  Future<VoteCard> fetchVoteCard({
    required Object groupId,
    required Object voteId,
  }) async {
    return _store.fetchVoteCard(groupId: groupId, voteId: voteId);
  }

  @override
  Future<VoteCard> submitVote({
    required Object groupId,
    required Object voteId,
    required Object optionId,
  }) async {
    return _store.fetchVoteCard(groupId: groupId, voteId: voteId);
  }

  @override
  Future<Map<int, List<String>>> fetchVoteVoters({
    required Object groupId,
    required Object voteId,
  }) async {
    return _store.fetchVoteVoters(groupId: groupId, voteId: voteId);
  }
}

class TestPlanRepository implements PlanRepository {
  TestPlanRepository(this._store);

  final InMemoryOnmuStore _store;

  @override
  Future<Plan> fetchPlan({
    required Object groupId,
    required Object planId,
  }) async {
    return _store.fetchPlan(groupId: groupId, planId: planId);
  }

  @override
  Future<Plan> createPlan(PlanCreateInput input) async {
    return _store.createPlan(input);
  }

  @override
  Future<Plan> updatePlan({
    required Object planId,
    required PlanCreateInput input,
  }) async {
    return _store.updatePlan(planId: planId, input: input);
  }

  @override
  Future<List<List<VisitPlan>>> fetchVisitPlansByDate({
    required Object groupId,
    required Object planId,
  }) async {
    return _store.fetchVisitPlansByDate(groupId: groupId, planId: planId);
  }

  @override
  Future<List<PlanParticipantArrival>> fetchPlanParticipants({
    required Object groupId,
    required Object planId,
  }) async {
    return const [];
  }

  @override
  Future<PlanParticipantArrival> updateMyArrivalStatus({
    required Object groupId,
    required Object planId,
    required PlanArrivalStatus status,
  }) async {
    return PlanParticipantArrival(
      id: 'current-user',
      nickname: '나',
      participantStatus: 'joined',
      arrivalStatus: status,
      isFallback: false,
    );
  }

  @override
  Future<PlanParticipantArrival> leaveAsCurrentUser({
    required Object groupId,
    required Object planId,
  }) async {
    return const PlanParticipantArrival(
      id: 'current-user',
      nickname: '나',
      participantStatus: 'left',
      arrivalStatus: PlanArrivalStatus.none,
      isFallback: false,
    );
  }

  @override
  Future<PlanParticipantArrival> addParticipant({
    required Object groupId,
    required Object planId,
    required String userId,
  }) async {
    return PlanParticipantArrival(
      id: userId,
      userId: userId,
      nickname: userId,
      participantStatus: 'joined',
      arrivalStatus: PlanArrivalStatus.none,
      isFallback: false,
    );
  }
}

class TestPlaceRepository implements PlaceRepository {
  TestPlaceRepository(this._store);

  final InMemoryOnmuStore _store;

  static const _searchOnlyCandidate = PlaceCandidate(
    id: 204,
    name: '온무분식',
    category: '분식',
    summary: '영업중 · 즉시 방문 가능',
    score: 86,
    matchPercent: 81,
    distanceLabel: '홍대입구역 도보 6분',
    travelTimeLabel: '도보 6분',
    priceLabel: '1인 10,000원대',
    isOpen: true,
    address: '서울 마포구 잔다리로 12',
    openingLabel: '오늘 11:00-21:00',
    sourceLabel: '테스트 검색 결과',
    riskLabel: '안정',
    riskTone: 'none',
    memberFits: [
      MemberFit(label: 'A', score: 88, note: '가벼운 식사'),
      MemberFit(label: 'B', score: 82, note: '역 가까움'),
    ],
    tags: ['분식', '가벼운식사'],
    reasons: ['후보 리스트에 아직 없는 검색 결과예요.'],
    risks: ['운영 리스크 없음'],
    provider: 'test',
    providerPlaceId: 'search-only-204',
  );

  @override
  Future<PlaceCandidate> fetchCandidate({
    required Object groupId,
    required Object planId,
    required Object candidateId,
  }) async {
    return _store.fetchPlaceCandidate(
      groupId: groupId,
      planId: planId,
      candidateId: candidateId,
    );
  }

  @override
  Future<PlaceCandidate> createCandidate({
    required Object groupId,
    required Object planId,
    required PlaceCandidate candidate,
  }) async {
    return _store.createPlaceCandidate(
      groupId: groupId,
      planId: planId,
      candidate: candidate,
    );
  }

  @override
  Future<SchedulePlace> createSchedulePlace({
    required Object groupId,
    required Object planId,
    required Object candidateId,
    required String name,
    DateTime? startsAt,
    DateTime? endsAt,
    String note = '',
  }) async {
    return SchedulePlace(
      id: '701',
      groupId: groupId.toString(),
      planId: planId.toString(),
      candidateId: candidateId.toString(),
      name: name,
      startsAt: startsAt,
      endsAt: endsAt,
      note: note,
      sortOrder: 1,
    );
  }

  @override
  Future<SchedulePlace> updateSchedulePlace({
    required Object groupId,
    required Object planId,
    required Object schedulePlaceId,
    DateTime? startsAt,
    DateTime? endsAt,
    String note = '',
  }) async {
    return SchedulePlace(
      id: schedulePlaceId.toString(),
      groupId: groupId.toString(),
      planId: planId.toString(),
      candidateId: '',
      name: '수정 장소',
      startsAt: startsAt,
      endsAt: endsAt,
      note: note,
      sortOrder: 1,
    );
  }

  @override
  Future<PlaceCandidate> setCandidateHeart({
    required Object groupId,
    required Object planId,
    required Object candidateId,
    required bool hearted,
  }) async {
    final candidate = await fetchCandidate(
      groupId: groupId,
      planId: planId,
      candidateId: candidateId,
    );
    return candidate.copyWith(
      heartedByMe: hearted,
      heartCount: hearted ? 1 : 0,
    );
  }

  @override
  Future<void> deleteSchedulePlace({
    required Object groupId,
    required Object planId,
    required Object schedulePlaceId,
  }) async {}

  @override
  Future<List<PlaceCandidate>> fetchCandidates({
    required Object groupId,
    required Object planId,
  }) async {
    return _store.fetchPlaceCandidates(groupId: groupId, planId: planId);
  }

  @override
  Future<List<PlaceCandidate>> searchPlaces({
    required Object groupId,
    required Object planId,
    required String query,
    String? category,
    double? lat,
    double? lng,
    int? radius,
  }) async {
    final candidates = _store.fetchPlaceCandidates(
      groupId: groupId,
      planId: planId,
    );
    return [
      ...candidates.where((candidate) => _matchesCategory(candidate, category)),
      if (_matchesSearchOnlyCategory(category)) _searchOnlyCandidate,
    ];
  }

  bool _matchesCategory(PlaceCandidate candidate, String? category) {
    final normalized = category?.trim();
    if (normalized == null || normalized.isEmpty) {
      return true;
    }
    final values = [
      candidate.category.trim(),
      ...candidate.tags.map((tag) => tag.trim()),
    ];
    if (normalized == '음식점') {
      return values.any(
        const {'음식점', '한식', '양식', '중식', '일식', '아시안식', '분식'}.contains,
      );
    }
    return values.contains(normalized);
  }

  bool _matchesSearchOnlyCategory(String? category) {
    if (category == null || category.trim().isEmpty) {
      return true;
    }
    if (category == _searchOnlyCandidate.category) {
      return true;
    }
    if (category == '음식점') {
      return const [
        '분식',
        '한식',
        '양식',
        '중식',
        '일식',
        '아시안식',
      ].contains(_searchOnlyCandidate.category);
    }
    return false;
  }

  @override
  Future<List<PlaceRisk>> fetchRisks({
    required Object groupId,
    required Object planId,
  }) async {
    return _store.fetchPlaceRisks(groupId: groupId, planId: planId);
  }

  @override
  Future<PlaceVoteResult> fetchVoteResult({
    required Object groupId,
    required Object planId,
  }) async {
    return _store.fetchPlaceVoteResult(groupId: groupId, planId: planId);
  }
}

class TestSettlementRepository implements SettlementRepository {
  TestSettlementRepository(this._store);

  final InMemoryOnmuStore _store;

  @override
  Future<SettlementSummary> fetchSettlementDraft({
    required Object groupId,
    required Object planId,
  }) async {
    final settlement = await fetchSettlement(groupId: groupId, planId: planId);
    return settlement.copyWith(status: 'draft', preview: true);
  }

  @override
  Future<SettlementSummary> updateSettlementDraft({
    required Object groupId,
    required Object planId,
    required List<SettlementDraftItemInput> items,
    String? memo,
  }) async {
    return fetchSettlement(groupId: groupId, planId: planId);
  }

  @override
  Future<SettlementSummary> updateSettlementDraftSections({
    required Object groupId,
    required Object planId,
    required List<SettlementDraftSectionInput> sections,
    String? memo,
  }) async {
    return fetchSettlement(groupId: groupId, planId: planId);
  }

  @override
  Future<SettlementSummary> updateSettlementDraftItemTargets({
    required Object groupId,
    required Object planId,
    required Object itemId,
    List<String> targetUserIds = const [],
    List<SettlementTargetShareInput> targetShares = const [],
  }) async {
    return fetchSettlement(groupId: groupId, planId: planId);
  }

  @override
  Future<SettlementSummary> previewSettlement({
    required Object groupId,
    required Object planId,
    required List<SettlementDraftItemInput> items,
  }) async {
    return fetchSettlement(groupId: groupId, planId: planId);
  }

  @override
  Future<SettlementSummary> createSettlement({
    required Object groupId,
    required Object planId,
    required List<SettlementDraftItemInput> items,
  }) async {
    final settlement = await fetchSettlement(groupId: groupId, planId: planId);
    return settlement.copyWith(status: 'finalized', preview: false);
  }

  @override
  Future<SettlementSummary> fetchSettlement({
    required Object groupId,
    required Object planId,
  }) async {
    return _store
        .fetchSettlement(groupId: groupId, planId: planId)
        .copyWith(status: 'finalized');
  }

  @override
  Future<SettlementSummary> fetchSettlementById({
    required Object groupId,
    required Object planId,
    required Object settlementId,
  }) async {
    return fetchSettlement(groupId: groupId, planId: planId);
  }

  @override
  Future<SettlementBasis> fetchSettlementBasis({
    required Object groupId,
    required Object planId,
    required Object settlementId,
  }) async {
    final settlement = await fetchSettlement(groupId: groupId, planId: planId);
    return SettlementBasis(
      settlementId: settlement.id,
      planTitle: settlement.planTitle,
      totalAmountLabel: settlement.totalAmountLabel,
      sections: settlement.sections,
      participants: settlement.memberResults,
      transfers: settlement.transfers,
      summary: settlement.shareMessage,
    );
  }

  @override
  Future<SettlementSummary> markTransferSent({
    required Object groupId,
    required Object planId,
    required Object settlementId,
    required Object transferId,
  }) async {
    return fetchSettlement(groupId: groupId, planId: planId);
  }

  @override
  Future<SettlementSummary> markTransferReceived({
    required Object groupId,
    required Object planId,
    required Object settlementId,
    required Object transferId,
  }) async {
    return fetchSettlement(groupId: groupId, planId: planId);
  }
}
