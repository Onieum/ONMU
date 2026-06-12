import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onmu_mobile/features/auth/data/auth_token_store.dart';
import 'package:onmu_mobile/features/auth/data/social_auth_service.dart';
import 'package:onmu_mobile/features/auth/domain/auth_session.dart';
import 'package:onmu_mobile/features/auth/domain/auth_user.dart';
import 'package:onmu_mobile/features/auth/domain/oauth_provider_credential.dart';
import 'package:onmu_mobile/features/auth/providers/auth_providers.dart';
import 'package:onmu_mobile/features/auth/repository/auth_repository.dart';
import 'package:onmu_mobile/features/group/repository/group_repository.dart';
import 'package:onmu_mobile/features/home/repository/notification_repository.dart';
import 'package:onmu_mobile/features/place/repository/place_repository.dart';
import 'package:onmu_mobile/features/plan/repository/plan_repository.dart';
import 'package:onmu_mobile/features/settlement/repository/settlement_repository.dart';
import 'package:onmu_mobile/shared/models/group_models.dart';
import 'package:onmu_mobile/shared/models/notification_models.dart';
import 'package:onmu_mobile/shared/models/place_models.dart';
import 'package:onmu_mobile/shared/models/plan_models.dart';
import 'package:onmu_mobile/shared/models/settlement_models.dart';
import 'package:onmu_mobile/shared/models/vote_models.dart';

import 'in_memory_onmu_store.dart';

ProviderContainer createOnmuTestContainer() {
  final store = InMemoryOnmuStore.seeded();
  return ProviderContainer(
    overrides: [
      authTokenStoreProvider.overrideWithValue(InMemoryAuthTokenStore()),
      authRepositoryProvider.overrideWithValue(const TestAuthRepository()),
      socialAuthServiceProvider.overrideWithValue(testSocialAuthService()),
      groupRepositoryProvider.overrideWithValue(TestGroupRepository(store)),
      planRepositoryProvider.overrideWithValue(TestPlanRepository(store)),
      placeRepositoryProvider.overrideWithValue(TestPlaceRepository(store)),
      settlementRepositoryProvider.overrideWithValue(
        TestSettlementRepository(store),
      ),
      notificationRepositoryProvider.overrideWithValue(
        TestNotificationRepository(store),
      ),
    ],
  );
}

ProviderScope onmuTestProviderScope({required Widget child, AuthUser? user}) {
  final store = InMemoryOnmuStore.seeded();
  return ProviderScope(
    overrides: [
      authTokenStoreProvider.overrideWithValue(InMemoryAuthTokenStore()),
      authRepositoryProvider.overrideWithValue(TestAuthRepository(user)),
      socialAuthServiceProvider.overrideWithValue(testSocialAuthService()),
      groupRepositoryProvider.overrideWithValue(TestGroupRepository(store)),
      planRepositoryProvider.overrideWithValue(TestPlanRepository(store)),
      placeRepositoryProvider.overrideWithValue(TestPlaceRepository(store)),
      settlementRepositoryProvider.overrideWithValue(
        TestSettlementRepository(store),
      ),
      notificationRepositoryProvider.overrideWithValue(
        TestNotificationRepository(store),
      ),
    ],
    child: child,
  );
}

class TestNotificationRepository implements NotificationRepository {
  TestNotificationRepository(this._store);

  final InMemoryOnmuStore _store;

  @override
  Future<List<NotificationItem>> fetchNotifications({int? limit}) async {
    return _store.fetchNotifications(limit: limit);
  }
}

SocialAuthService testSocialAuthService() {
  return SocialAuthService(
    naverCredentialLoader: () async => const OAuthProviderCredential(
      provider: 'naver',
      devVerifiedSubject: 'naver-dev-local-user',
      displayName: '네이버 친구',
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
  Future<AuthSession> exchangeOAuthLogin(
    OAuthProviderCredential credential,
  ) async {
    final provider = credential.provider.toUpperCase();
    final displayName = credential.displayName?.trim().isNotEmpty == true
        ? credential.displayName!.trim()
        : '테스트 사용자';
    return AuthSession(
      user: AuthUser(
        id: 'usr_test_oauth',
        publicId: 'usr_test_oauth',
        provider: provider,
        displayName: displayName,
        email: credential.email,
      ),
      tokens: const OnmuAuthTokens(
        accessToken: 'test-onmu-access-jwt',
        refreshToken: 'test-onmu-refresh-token',
      ),
    );
  }
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
  Future<List<GroupMemberProfile>> fetchMembers(Object groupId) async {
    return _store.fetchMembers(groupId);
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
  Future<List<VoteSummary>> fetchVotes(Object groupId) async {
    return _store.fetchVotes(groupId);
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
      displayName: '나',
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
      displayName: '나',
      participantStatus: 'left',
      arrivalStatus: PlanArrivalStatus.none,
      isFallback: false,
    );
  }
}

class TestPlaceRepository implements PlaceRepository {
  TestPlaceRepository(this._store);

  final InMemoryOnmuStore _store;

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
  }) async {
    return _store.fetchPlaceCandidates(groupId: groupId, planId: planId);
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
    return fetchSettlement(groupId: groupId, planId: planId);
  }

  @override
  Future<SettlementSummary> fetchSettlement({
    required Object groupId,
    required Object planId,
  }) async {
    return _store.fetchSettlement(groupId: groupId, planId: planId);
  }

  @override
  Future<SettlementSummary> fetchSettlementById({
    required Object groupId,
    required Object planId,
    required Object settlementId,
  }) async {
    return fetchSettlement(groupId: groupId, planId: planId);
  }
}
