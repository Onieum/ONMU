import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/features/auth/domain/auth_user.dart';
import 'package:onmu_mobile/features/auth/providers/auth_providers.dart';
import 'package:onmu_mobile/features/group/repository/media_repository.dart';
import 'package:onmu_mobile/features/plan/view_model/plan_detail_view_model.dart';
import 'package:onmu_mobile/features/group/repository/group_repository.dart';
import 'package:onmu_mobile/features/group/view_model/group_chat_view_model.dart';
import 'package:onmu_mobile/features/group/view_model/group_create_view_model.dart';
import 'package:onmu_mobile/features/group/view_model/group_home_view_model.dart';
import 'package:onmu_mobile/features/group/view_model/group_list_view_model.dart';
import 'package:onmu_mobile/features/group/view_model/group_members_view_model.dart';
import 'package:onmu_mobile/features/group/view_model/group_plan_board_view_model.dart';
import 'package:onmu_mobile/features/group/view_model/group_plan_list_view_model.dart';
import 'package:onmu_mobile/features/group/view_model/vote_view_model.dart';
import 'package:onmu_mobile/features/home/view_model/home_view_model.dart';
import 'package:onmu_mobile/features/my/domain/my_profile.dart';
import 'package:onmu_mobile/features/my/repository/my_repository.dart';
import 'package:onmu_mobile/features/my/view_model/my_profile_controller.dart';
import 'package:onmu_mobile/features/my/repository/friend_repository.dart';
import 'package:onmu_mobile/features/ootd/repository/record_repository.dart';
import 'package:onmu_mobile/features/ootd/view_model/record_flow_controller.dart';
import 'package:onmu_mobile/features/place/repository/place_repository.dart';
import 'package:onmu_mobile/features/place/view_model/place_candidates_view_model.dart';
import 'package:onmu_mobile/features/plan/repository/plan_repository.dart';
import 'package:onmu_mobile/features/plan/view_model/plan_create_view_model.dart';
import 'package:onmu_mobile/features/settlement/repository/settlement_repository.dart';
import 'package:onmu_mobile/features/settlement/view_model/settlement_view_model.dart';
import 'package:onmu_mobile/shared/models/character_model.dart';
import 'package:onmu_mobile/shared/models/group_models.dart';
import 'package:onmu_mobile/shared/models/ootd_model.dart';
import 'package:onmu_mobile/shared/models/place_models.dart';
import 'package:onmu_mobile/shared/models/plan_models.dart';
import 'package:onmu_mobile/shared/models/preference_profile.dart';
import 'package:onmu_mobile/shared/models/settlement_models.dart';
import 'package:onmu_mobile/shared/models/vote_models.dart';

import 'support/test_onmu_repositories.dart';

void main() {
  test('온모임 목록 ViewModel은 repository override 데이터를 그대로 노출한다', () async {
    final container = ProviderContainer(
      overrides: [
        groupRepositoryProvider.overrideWithValue(_FakeGroupRepository()),
      ],
    );
    addTearDown(container.dispose);

    final state = await container.read(groupListViewModelProvider.future);

    expect(state.groups, hasLength(1));
    expect(state.groups.single.id, 9001);
    expect(state.groupCount, 1);
  });

  test('온모임 목록 ViewModel은 비어 있는 요약을 멤버와 약속 API로 보강한다', () async {
    final container = ProviderContainer(
      overrides: [
        groupRepositoryProvider.overrideWithValue(_SparseGroupListRepository()),
      ],
    );
    addTearDown(container.dispose);

    final state = await container.read(groupListViewModelProvider.future);
    final group = state.groups.single;

    expect(group.members, ['지우', '민수']);
    expect(group.memberAvatars.map((member) => member.name), ['지우', '민수']);
    expect(group.pinnedPlanTitle, '서버 보강 약속');
  });

  test('온모임 목록 ViewModel은 예정 약속이 없으면 명확한 빈 상태 문구를 노출한다', () async {
    final container = ProviderContainer(
      overrides: [
        groupRepositoryProvider.overrideWithValue(
          _SparseGroupListRepository(plans: const []),
        ),
      ],
    );
    addTearDown(container.dispose);

    final state = await container.read(groupListViewModelProvider.future);

    expect(state.groups.single.pinnedPlanTitle, '예정된 약속 없음');
  });

  test('온모임 목록 ViewModel은 약속 보강 실패를 빈 상태와 구분한다', () async {
    final container = ProviderContainer(
      overrides: [
        groupRepositoryProvider.overrideWithValue(
          _SparseGroupListRepository(throwOnFetchPlans: true),
        ),
      ],
    );
    addTearDown(container.dispose);

    final state = await container.read(groupListViewModelProvider.future);

    expect(state.groups.single.pinnedPlanTitle, '약속 정보를 불러오지 못했어요');
  });

  test('홈 ViewModel은 서버에 모임이 없어도 빈 상태를 반환한다', () async {
    final container = ProviderContainer(
      overrides: [
        groupRepositoryProvider.overrideWithValue(_EmptyGroupRepository()),
        planRepositoryProvider.overrideWithValue(_UnusedPlanRepository()),
        settlementRepositoryProvider.overrideWithValue(
          _UnusedSettlementRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final state = await container.read(homeViewModelProvider.future);

    expect(state.groupId, isNull);
    expect(state.activePlan, isNull);
    expect(state.upcomingPlans, isEmpty);
    expect(state.settlementId, isNull);
    expect(state.todayPlanCount, 0);
  });

  test('홈 ViewModel은 오늘 날짜 약속 수를 API 결과에서 계산한다', () async {
    final container = ProviderContainer(
      overrides: [
        groupRepositoryProvider.overrideWithValue(_TodayPlansGroupRepository()),
        planRepositoryProvider.overrideWithValue(_TodayPlansPlanRepository()),
        settlementRepositoryProvider.overrideWithValue(
          _UnusedSettlementRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final state = await container.read(homeViewModelProvider.future);

    expect(state.todayPlanCount, 2);
  });

  test('홈 ViewModel은 다가오는 약속을 오늘 이후 날짜순으로 정렬한다', () async {
    final container = ProviderContainer(
      overrides: [
        groupRepositoryProvider.overrideWithValue(_UpcomingOrderRepository()),
        planRepositoryProvider.overrideWithValue(
          _UpcomingOrderPlanRepository(),
        ),
        settlementRepositoryProvider.overrideWithValue(
          _UnusedSettlementRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final state = await container.read(homeViewModelProvider.future);

    expect(state.upcomingPlans.map((plan) => plan.title), [
      '내일 약속',
      '다음 주 약속',
      '시간 미정 약속',
    ]);
    expect(state.upcomingPlans.any((plan) => plan.title == '지난 약속'), isFalse);
  });

  test('홈 ViewModel은 캘린더 표시용 약속에 지난 약속도 유지한다', () async {
    final container = ProviderContainer(
      overrides: [
        groupRepositoryProvider.overrideWithValue(_UpcomingOrderRepository()),
        planRepositoryProvider.overrideWithValue(
          _UpcomingOrderPlanRepository(),
        ),
        settlementRepositoryProvider.overrideWithValue(
          _UnusedSettlementRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final state = await container.read(homeViewModelProvider.future);

    expect(state.calendarPlans.map((plan) => plan.title), [
      '지난 약속',
      '내일 약속',
      '다음 주 약속',
    ]);
  });

  test('홈 ViewModel은 현재 진행 중인 약속이 없으면 activePlan을 비운다', () async {
    final container = ProviderContainer(
      overrides: [
        groupRepositoryProvider.overrideWithValue(_NoActivePlanRepository()),
        planRepositoryProvider.overrideWithValue(_UnusedPlanRepository()),
        settlementRepositoryProvider.overrideWithValue(
          _UnusedSettlementRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final state = await container.read(homeViewModelProvider.future);

    expect(state.activePlan, isNull);
    expect(state.upcomingPlans.map((plan) => plan.title), ['내일 약속']);
  });

  test('온모임 생성 ViewModel은 기존 모임 멤버 추천 없이 친구 후보만 불러온다', () async {
    final container = ProviderContainer(
      overrides: [
        groupRepositoryProvider.overrideWithValue(_EmptyGroupRepository()),
        friendRepositoryProvider.overrideWithValue(
          TestFriendRepository(
            friends: const [
              FriendProfile(
                publicId: 'friend-doyun',
                userCode: 'doyun',
                name: '도윤',
                preferenceSummary: '',
                isFriend: true,
              ),
            ],
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final state = await container.read(groupCreateViewModelProvider.future);

    expect(state.friendCandidates.map((friend) => friend.name), contains('도윤'));
  });

  test('프로필 저장 컨트롤러는 인증 사용자 표시 이름도 동기화한다', () async {
    final repository = TestMyRepository();
    final container = ProviderContainer(
      overrides: [
        myRepositoryProvider.overrideWithValue(repository),
        authUserProvider.overrideWith(
          (ref) => const AuthUser(
            id: '00000000-0000-0000-0000-000000000001',
            publicId: 'usr_me',
            provider: 'KAKAO',
            nickname: 'ONMU User',
            onboardingStatus: 'COMPLETED',
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(myProfileControllerProvider)
        .saveProfile(
          const MyProfile(
            realName: '박진희',
            visibility: ProfileVisibility.friends,
            favoriteKeywords: [],
            dislikedKeywords: [],
            preferredTimes: [],
            availableDays: [],
            unavailableDates: [],
            favoritePlaces: [],
            wantToGoPlaces: [],
            dislikedPlaces: [],
          ),
        );

    expect(container.read(authUserProvider)?.nickname, '박진희');
  });

  test('온모임 멤버 ViewModel은 서버 멤버 목록만 상태로 노출한다', () async {
    final container = createOnmuTestContainer();
    addTearDown(container.dispose);

    final state = await container.read(
      groupMembersViewModelProvider('1').future,
    );

    expect(state.members.map((profile) => profile.name), contains('소연'));
    expect(
      state.members.map((profile) => profile.name),
      isNot(contains('가짜 친구')),
    );
  });

  test('온모임 홈 ViewModel은 요청한 groupId 범위의 상태를 만든다', () async {
    final container = createOnmuTestContainer();
    addTearDown(container.dispose);

    final state = await container.read(groupHomeViewModelProvider('2').future);

    expect(state.group.id, 2);
    expect(state.group.name, '퇴근 후 러닝크루');
    expect(state.recentMemories, isNotEmpty);
    expect(state.recentMessage, isNotNull);
  });

  test('온모임 홈 ViewModel은 채팅 목록의 최신 메시지를 최근 대화로 노출한다', () async {
    final container = ProviderContainer(
      overrides: [
        groupRepositoryProvider.overrideWithValue(
          _FakeGroupRepository(
            initialMessages: const [
              GroupMessage(
                id: 'old-message',
                sender: '민서',
                message: '처음 보낸 메시지',
                timeLabel: '10:00',
                isMine: false,
              ),
              GroupMessage(
                id: 'new-message',
                sender: '지우',
                message: '가장 최근 메시지',
                timeLabel: '17:37',
                isMine: false,
              ),
            ],
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final state = await container.read(
      groupHomeViewModelProvider('9001').future,
    );

    expect(state.recentMessage?.id, 'new-message');
    expect(state.recentMessage?.message, '가장 최근 메시지');
  });

  test('온모임 홈 ViewModel은 최근 기록/채팅 실패 시에도 홈을 렌더링한다', () async {
    final container = ProviderContainer(
      overrides: [
        groupRepositoryProvider.overrideWithValue(
          _FakeGroupRepository(
            throwOnFetchMemories: true,
            throwOnFetchMessages: true,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final state = await container.read(
      groupHomeViewModelProvider('9001').future,
    );

    expect(state.group.id, 9001);
    expect(state.recentMemories, isEmpty);
    expect(state.recentMessage, isNull);
  });

  test('온모임 홈 ViewModel은 미래 약속만 날짜순으로 다가오는 약속에 노출한다', () async {
    final container = ProviderContainer(
      overrides: [
        groupRepositoryProvider.overrideWithValue(_NoActivePlanRepository()),
      ],
    );
    addTearDown(container.dispose);

    final state = await container.read(groupHomeViewModelProvider('9').future);

    expect(state.upcomingPlan?.title, '내일 약속');
    expect(state.upcomingPlan?.displayStatusLabel, '예정');
  });

  test('온모임 약속 목록 ViewModel은 진행중 약속을 지난 약속과 분리한다', () async {
    final now = DateTime.now();
    final container = ProviderContainer(
      overrides: [
        groupRepositoryProvider.overrideWithValue(
          _SparseGroupListRepository(
            plans: [
              GroupPlanSummary(
                id: 501,
                title: '지금 진행 중인 약속',
                dateLabel: '오늘',
                startsAt: now.subtract(const Duration(minutes: 30)),
                endsAt: now.add(const Duration(minutes: 30)),
                placeName: '수원',
                statusLabel: 'scheduled',
                statusType: 'scheduled',
                memberCount: 1,
                extraMemberCount: 0,
                iconKind: 'coffee',
                isPast: false,
              ),
              GroupPlanSummary(
                id: 502,
                title: '다가오는 약속',
                dateLabel: '내일',
                startsAt: now.add(const Duration(days: 1)),
                placeName: '서울',
                statusLabel: 'scheduled',
                statusType: 'scheduled',
                memberCount: 1,
                extraMemberCount: 0,
                iconKind: 'coffee',
                isPast: false,
              ),
              GroupPlanSummary(
                id: 503,
                title: '지난 약속',
                dateLabel: '어제',
                startsAt: now.subtract(const Duration(days: 1)),
                placeName: '인천',
                statusLabel: 'completed',
                statusType: 'completed',
                memberCount: 1,
                extraMemberCount: 0,
                iconKind: 'coffee',
                isPast: true,
              ),
            ],
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final state = await container.read(
      groupPlanListViewModelProvider('1').future,
    );

    expect(state.ongoingPlans.map((plan) => plan.title), ['지금 진행 중인 약속']);
    expect(state.upcomingPlans.map((plan) => plan.title), ['다가오는 약속']);
    expect(state.pastPlans.map((plan) => plan.title), ['지난 약속']);
  });

  test('모임 멤버 추가 후 약속 참여자 후보 provider를 다시 불러온다', () async {
    final repository = _MutableGroupMemberRepository();
    final container = ProviderContainer(
      overrides: [groupRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final initial = await container.read(
      groupPlanMemberOptionsProvider('1').future,
    );
    expect(initial, isEmpty);

    await container.read(groupMembersViewModelProvider('1').future);
    await container
        .read(groupMembersViewModelProvider('1').notifier)
        .addMembers([
          const FriendProfile(
            userId: 'user-invited',
            name: '새 멤버',
            preferenceSummary: '친구',
            isFriend: true,
          ),
        ]);

    final options = await container.read(
      groupPlanMemberOptionsProvider('1').future,
    );
    expect(options.map((member) => member.userId), contains('user-invited'));
  });

  test('약속 참여자 후보 provider는 후보 상태를 추가 가능으로 표시한다', () async {
    final container = ProviderContainer(
      overrides: [
        groupRepositoryProvider.overrideWithValue(
          _PlanMemberOptionStatusRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final options = await container.read(
      groupPlanMemberOptionsProvider('1').future,
    );

    expect(options.single.name, '찬도치');
    expect(options.single.badge, '추가 가능');
    expect(options.single.profileImageUrl, 'https://example.test/chando.png');
  });

  test('약속 생성 controller는 선택한 후보 멤버만 선호도 정보를 보강한다', () async {
    final repository = _PlanMemberPreferenceRepository();
    final container = ProviderContainer(
      overrides: [groupRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final enriched = await container
        .read(planCreateControllerProvider)
        .enrichParticipantCandidate(
          groupId: '1',
          member: const PlanMember(
            userId: 'user-chando',
            name: '찬도치',
            badge: '추가 가능',
          ),
        );

    expect(repository.requestedUserIds, ['user-chando']);
    expect(enriched.preferenceProfile?.preferredWeekdays, ['SATURDAY']);
    expect(enriched.preferenceProfile?.preferredTimes, ['afternoon']);
  });

  test('온모임 목록 ViewModel은 다가오는 약속 기준으로 카드 약속 제목을 보강한다', () async {
    final container = ProviderContainer(
      overrides: [
        groupRepositoryProvider.overrideWithValue(_UpcomingOrderRepository()),
      ],
    );
    addTearDown(container.dispose);

    final state = await container.read(groupListViewModelProvider.future);

    expect(state.groups.single.pinnedPlanTitle, '내일 약속');
  });

  test('온모임 목록 ViewModel은 진행중 약속을 카드 요약에 우선 노출한다', () async {
    final now = DateTime.now();
    final container = ProviderContainer(
      overrides: [
        groupRepositoryProvider.overrideWithValue(
          _SparseGroupListRepository(
            plans: [
              GroupPlanSummary(
                id: 7702,
                title: '지금 진행 중인 약속',
                dateLabel: '오늘',
                startsAt: now.subtract(const Duration(hours: 1)),
                endsAt: now.add(const Duration(hours: 1)),
                placeName: '수원',
                statusLabel: 'scheduled',
                statusType: 'scheduled',
                memberCount: 2,
                extraMemberCount: 0,
                iconKind: 'coffee',
                isPast: false,
              ),
            ],
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final state = await container.read(groupListViewModelProvider.future);

    expect(state.groups.single.pinnedPlanTitle, '약속 진행 중');
  });

  test('온모임 홈 ViewModel은 최근 대화 API가 실패해도 상세 홈을 표시한다', () async {
    final container = ProviderContainer(
      overrides: [
        groupRepositoryProvider.overrideWithValue(
          _FakeGroupRepository(throwOnFetchMessages: true),
        ),
      ],
    );
    addTearDown(container.dispose);

    final state = await container.read(groupHomeViewModelProvider('1').future);

    expect(state.group.name, 'Spring API 전환 모임');
    expect(state.recentMessage, isNull);
  });

  test('약속 상세 ViewModel은 선택 멤버와 날짜별 방문 계획을 분리한다', () async {
    final container = createOnmuTestContainer();
    addTearDown(container.dispose);

    final state = await container.read(
      planDetailViewModelProvider((groupId: '1', planId: '101')).future,
    );

    expect(state.selectedMembers.every((member) => member.selected), isTrue);
    expect(state.visitPlanForDate(0).first.place, '다운타우너 성수');
    expect(state.visitPlanForDate(1).first.place, '협재 해수욕장');
  });

  test('약속 상세 ViewModel은 참가자 응답으로 멤버 프로필 이미지를 보강한다', () async {
    final container = ProviderContainer(
      overrides: [
        planRepositoryProvider.overrideWithValue(
          _PlanMemberProfileImageMergeRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final state = await container.read(
      planDetailViewModelProvider((groupId: '1', planId: '101')).future,
    );

    expect(state.selectedMembers.single.name, '박진희');
    expect(
      state.selectedMembers.single.profileImageUrl,
      'https://cdn.onmu.test/jinhee.png',
    );
  });

  test('약속 상세 ViewModel은 방문 장소가 없는 날도 약속 기간 날짜 탭을 만든다', () async {
    final container = ProviderContainer(
      overrides: [
        planRepositoryProvider.overrideWithValue(_LongRangePlanRepository()),
      ],
    );
    addTearDown(container.dispose);

    final state = await container.read(
      planDetailViewModelProvider((groupId: '1', planId: '104')).future,
    );

    expect(state.dateTabs.map((tab) => tab.tabLabel), [
      '6/19 금',
      '6/20 토',
      '6/21 일',
      '6/22 월',
      '6/23 화',
      '6/24 수',
    ]);
    expect(state.visitPlanForDate(0).single.place, '퍼스트커피랩행궁');
    expect(state.visitPlanForDate(1), isEmpty);
    expect(state.visitPlanForDate(5), isEmpty);
  });

  test('약속 상세 ViewModel은 서버 fallback 참여자를 선택 멤버로 취급하지 않는다', () async {
    final container = ProviderContainer(
      overrides: [
        groupRepositoryProvider.overrideWithValue(_FakeGroupRepository()),
        planRepositoryProvider.overrideWithValue(
          _FallbackParticipantRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final state = await container.read(
      planDetailViewModelProvider((groupId: '1', planId: '101')).future,
    );

    expect(state.participantArrivals.single.isFallback, isTrue);
    expect(state.selectedMembers, isEmpty);
  });

  test('약속 상세 상태 알리기는 현재 시간이 약속 시간 안일 때만 허용한다', () {
    final basePlan = Plan(
      id: 101,
      title: '진행 시간 검증',
      dateTime: '일정 미정',
      location: '성수동',
      status: '진행중',
      memo: '',
      members: const [],
      timeCandidates: const [],
      visitPlan: const [],
      startsAt: DateTime.parse('2026-06-10T10:00:00+09:00'),
      endsAt: DateTime.parse('2026-06-10T12:00:00+09:00'),
    );
    PlanDetailState detailAt(DateTime currentTime) => PlanDetailState(
      plan: basePlan,
      selectedMembers: const [],
      visitPlansByDate: const [],
      dateTabs: const [],
      participantArrivals: const [],
      currentTime: currentTime,
    );

    expect(
      detailAt(
        DateTime.parse('2026-06-10T11:00:00+09:00'),
      ).canShareArrivalStatus,
      isTrue,
    );
    expect(
      detailAt(
        DateTime.parse('2026-06-10T12:00:00+09:00'),
      ).canShareArrivalStatus,
      isFalse,
    );
    expect(
      detailAt(
        DateTime.parse('2026-06-10T09:59:00+09:00'),
      ).canShareArrivalStatus,
      isFalse,
    );
  });

  test('장소 후보 ViewModel은 서버 하트 상태와 count를 그대로 사용한다', () async {
    final container = ProviderContainer(
      overrides: [
        placeRepositoryProvider.overrideWithValue(_FakePlaceRepository()),
        planRepositoryProvider.overrideWithValue(_FakePlanRepository()),
      ],
    );
    addTearDown(container.dispose);
    final provider = placeCandidatesViewModelProvider((
      groupId: '1',
      planId: '101',
    ));

    final initial = await container.read(provider.future);
    expect(initial.candidates.single.id, 9901);
    expect(initial.planLocation, '서울시 테스트구');
    expect(initial.isLiked(9901), isFalse);
    expect(initial.favoriteCountFor(9901), 0);

    await container.read(provider.notifier).toggleFavorite(9901);

    final updated = container.read(provider).requireValue;
    expect(updated.isLiked(9901), isTrue);
    expect(updated.favoriteCountFor(9901), 1);
  });

  test('약속 생성 Controller는 새 약속 저장을 repository에 위임한다', () async {
    final repository = _RecordingPlanCreateRepository();
    final container = ProviderContainer(
      overrides: [planRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final input = PlanCreateInput(
      groupId: 33,
      title: '컨트롤러 경계 테스트',
      dateTime: '2026-06-18T10:00:00+09:00',
      endsAt: '2026-06-18T12:00:00+09:00',
      location: '성수',
      memo: 'repository 호출은 ViewModel 계층에서 처리한다',
      members: const [PlanMember(userId: 'user-1', name: '민서')],
    );

    final created = await container
        .read(planCreateControllerProvider)
        .createPlan(input);

    expect(repository.createdInputs.single, same(input));
    expect(created.title, '컨트롤러 경계 테스트');
    expect(created.location, '성수');
  });

  test('기록 흐름 Controller는 저장/업로드/삭제를 repository에 위임한다', () async {
    final repository = _RecordingRecordRepository();
    final container = ProviderContainer(
      overrides: [recordRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final controller = container.read(recordFlowControllerProvider);
    final draft = _recordForMutation();

    final saved = await controller.saveRecord(draft);
    final uploadedUrl = await controller.uploadMedia(
      Uint8List.fromList(const [1, 2, 3]),
      'daily.jpg',
    );
    final missingDelete = await controller.deleteRecord(draft);
    final completedDelete = await controller.deleteRecord(saved);

    expect(repository.createdRecords.single, same(draft));
    expect(repository.uploadedFiles.single, 'daily.jpg');
    expect(uploadedUrl, 'https://cdn.onmu.test/daily.jpg');
    expect(missingDelete, RecordMutationResult.missingId);
    expect(completedDelete, RecordMutationResult.completed);
    expect(repository.deletedIds, ['record-created']);
  });

  test('투표 상세 ViewModel은 voteId로 투표 카드와 후보를 조회한다', () async {
    final container = createOnmuTestContainer();
    addTearDown(container.dispose);

    final state = await container.read(
      voteDetailViewModelProvider((
        groupId: '1',
        voteId: '501',
        planId: null,
      )).future,
    );

    expect(state.vote.title, '제주도 여행 장소 투표');
    expect(state.candidates.first.name, '온무식당');
    expect(state.votersFor(201), contains('민서'));
  });

  test('투표 상세 ViewModel은 선택 옵션으로 투표하고 다시 투표할 수 있다', () async {
    final repository = _VoteSelectionGroupRepository();
    final container = ProviderContainer(
      overrides: [
        groupRepositoryProvider.overrideWithValue(repository),
        placeRepositoryProvider.overrideWithValue(_FakePlaceRepository()),
      ],
    );
    addTearDown(container.dispose);

    final provider = voteDetailViewModelProvider((
      groupId: '1',
      voteId: '501',
      planId: '101',
    ));

    await container.read(provider.notifier).submitVote('vopt-501-1');
    await container.read(provider.notifier).submitVote('vopt-501-2');

    expect(repository.selectedOptionIds, ['vopt-501-1', 'vopt-501-2']);
  });

  test('투표 상세 ViewModel은 voters projection이 없어도 option count를 유지한다', () async {
    final container = ProviderContainer(
      overrides: [
        groupRepositoryProvider.overrideWithValue(
          _VoteCountOnlyGroupRepository(),
        ),
        placeRepositoryProvider.overrideWithValue(_FakePlaceRepository()),
      ],
    );
    addTearDown(container.dispose);

    final state = await container.read(
      voteDetailViewModelProvider((
        groupId: '1',
        voteId: '501',
        planId: '101',
      )).future,
    );

    expect(state.votersFor(9901), isEmpty);
    expect(state.voteCountFor(9901), 3);
  });

  test('투표 상세 ViewModel은 장소 후보가 없어도 vote option으로 후보 행을 만든다', () async {
    final container = ProviderContainer(
      overrides: [
        groupRepositoryProvider.overrideWithValue(
          _VoteCountOnlyGroupRepository(),
        ),
        placeRepositoryProvider.overrideWithValue(
          _NoPlaceCandidatesRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final state = await container.read(
      voteDetailViewModelProvider((
        groupId: '1',
        voteId: '501',
        planId: '101',
      )).future,
    );

    expect(state.candidates.map((candidate) => candidate.name), ['목업 카페']);
    expect(state.voteCountFor(9901), 3);
  });

  test('투표 상세 ViewModel은 투표 옵션에 포함된 장소 후보만 노출한다', () async {
    final container = ProviderContainer(
      overrides: [
        groupRepositoryProvider.overrideWithValue(
          _VoteCountOnlyGroupRepository(),
        ),
        placeRepositoryProvider.overrideWithValue(
          _MultiCandidatePlaceRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final state = await container.read(
      voteDetailViewModelProvider((
        groupId: '1',
        voteId: '501',
        planId: '101',
      )).future,
    );

    expect(state.candidates.map((candidate) => candidate.id), [9901]);
    expect(state.candidates.map((candidate) => candidate.name), ['목업 카페']);
  });

  test('약속 보드 ViewModel은 현재 약속에 연결된 투표와 후보 집계를 사용한다', () async {
    final groupRepository = _PlanBoardGroupRepository();
    final container = ProviderContainer(
      overrides: [
        groupRepositoryProvider.overrideWithValue(groupRepository),
        placeRepositoryProvider.overrideWithValue(_PlanBoardPlaceRepository()),
        planRepositoryProvider.overrideWithValue(_PlanBoardPlanRepository()),
      ],
    );
    addTearDown(container.dispose);

    final state = await container.read(
      groupPlanBoardViewModelProvider((groupId: '1', planId: '103')).future,
    );

    expect(groupRepository.fetchedVoteTargetTypes, ['PLAN']);
    expect(groupRepository.fetchedVoteTargetIds, ['103']);
    expect(state.currentPlan?.title, '한강 피크닉');
    expect(state.voteId, 703);
    expect(state.candidateResults.map((row) => row.candidate.id), [9902, 9901]);
    expect(state.candidateResults.map((row) => row.voteCount), [4, 1]);
    expect(state.candidateResults.map((row) => row.progress), [0.8, 0.2]);
    expect(state.participantResponses.map((response) => response.count), [
      2,
      1,
      1,
    ]);
  });

  test('약속 보드 ViewModel은 다른 약속의 투표를 현재 약속 투표로 쓰지 않는다', () async {
    final container = ProviderContainer(
      overrides: [
        groupRepositoryProvider.overrideWithValue(
          _PlanBoardMismatchedVoteRepository(),
        ),
        placeRepositoryProvider.overrideWithValue(_PlanBoardPlaceRepository()),
        planRepositoryProvider.overrideWithValue(_PlanBoardPlanRepository()),
      ],
    );
    addTearDown(container.dispose);

    final state = await container.read(
      groupPlanBoardViewModelProvider((groupId: '1', planId: '103')).future,
    );

    expect(state.voteId, 0);
    expect(state.voteActionLabel, '연결된 투표 없음');
    expect(state.candidateResults.map((row) => row.voteCount), [0, 0]);
  });

  test(
    '투표 상세 ViewModel은 route planId가 투표 대상과 다르면 투표 대상 약속의 후보를 조회한다',
    () async {
      final placeRepository = _PlanScopedPlaceRepository();
      final container = ProviderContainer(
        overrides: [
          groupRepositoryProvider.overrideWithValue(
            _MismatchedVoteGroupRepository(),
          ),
          placeRepositoryProvider.overrideWithValue(placeRepository),
        ],
      );
      addTearDown(container.dispose);

      final state = await container.read(
        voteDetailViewModelProvider((
          groupId: '1',
          voteId: '501',
          planId: '103',
        )).future,
      );

      expect(placeRepository.fetchedPlanIds, ['101']);
      expect(state.candidates.map((candidate) => candidate.id), [9901]);
    },
  );

  test('약속 보드 상태는 후보 없는 투표를 명확한 empty state로 설명한다', () {
    final state = GroupPlanBoardState(
      group: const GroupSummary(
        id: 1,
        name: '온모임',
        description: '',
        members: [],
        lastMessage: '',
        unreadCount: 0,
        pinnedPlanTitle: '',
      ),
      currentPlan: null,
      candidateResults: const [],
      vote: VoteSummary(
        id: 501,
        title: '장소 투표',
        statusLabel: '진행 중',
        description: '',
        planLabel: '약속',
        planMeta: 'PLACE',
        participants: const [],
        participantCount: 0,
        options: const [],
        closed: false,
        joinedByMe: false,
        actionLabel: '투표 확인하기',
        targetType: 'PLAN',
        targetId: '101',
      ),
      participantResponses: const [],
    );

    expect(state.voteDescription, '등록된 투표 후보가 없어요');
  });

  test('정산 ViewModel은 settlementId가 있으면 특정 정산을 조회한다', () async {
    final repository = _TrackingSettlementRepository();
    final container = ProviderContainer(
      overrides: [settlementRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final settlement = await container.read(
      settlementByIdViewModelProvider((
        groupId: '1',
        planId: '101',
        settlementId: '301',
      )).future,
    );

    expect(settlement.id, '301');
    expect(repository.fetchLatestCalls, isZero);
    expect(repository.fetchByIdCalls, ['1/101/301']);
  });

  test('채팅 ViewModel은 메시지 작성 성공 시 서버 응답을 상태에 반영한다', () async {
    final repository = _FakeGroupRepository(
      sentMessage: const GroupMessage(
        sender: '나',
        message: '서버 응답 메시지',
        timeLabel: '방금',
        isMine: true,
      ),
    );
    final container = ProviderContainer(
      overrides: [
        groupRepositoryProvider.overrideWithValue(repository),
        settlementRepositoryProvider.overrideWithValue(
          _ChatSettlementRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    final provider = groupChatViewModelProvider('1');

    final initial = await container.read(provider.future);
    final sent = await container
        .read(provider.notifier)
        .sendMessage('  전송 요청  ');
    final updated = container.read(provider).requireValue;

    expect(initial.messages, isEmpty);
    expect(sent, isTrue);
    expect(repository.sentMessages, ['전송 요청']);
    expect(updated.messages.single.message, '서버 응답 메시지');
    expect(updated.sendErrorMessage, isNull);
  });

  test('채팅 ViewModel은 보조 카드 API가 늦어도 메시지를 먼저 반환한다', () async {
    final pinnedPlanCompleter = Completer<GroupPinnedPlan?>();
    final plansCompleter = Completer<List<GroupPlanSummary>>();
    final votesCompleter = Completer<List<VoteSummary>>();
    final repository = _FakeGroupRepository(
      initialMessages: const [
        GroupMessage(
          id: 'message-fast',
          sender: '민서',
          message: '먼저 보여야 하는 메시지',
          timeLabel: '10:00',
          isMine: false,
        ),
      ],
      fetchPinnedPlanCompleter: pinnedPlanCompleter,
      fetchPlansCompleter: plansCompleter,
      fetchVotesCompleter: votesCompleter,
    );
    final container = ProviderContainer(
      overrides: [
        groupRepositoryProvider.overrideWithValue(repository),
        settlementRepositoryProvider.overrideWithValue(
          _ChatSettlementRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final state = await container
        .read(groupChatViewModelProvider('1').future)
        .timeout(const Duration(seconds: 1));

    expect(state.messages.single.message, '먼저 보여야 하는 메시지');
    expect(state.vote, isNull);
    expect(state.settlement, isNull);
    expect(repository.watchedAfterCursors, [null]);

    pinnedPlanCompleter.complete(null);
    plansCompleter.complete(const []);
    votesCompleter.complete(const []);
    await pumpEventQueue();
  });

  test('채팅 ViewModel은 정산 카드 메시지 메타데이터를 유지한다', () async {
    final repository = _FakeGroupRepository(
      initialMessages: const [
        GroupMessage(
          id: 'settlement-card-1',
          sender: 'ONMU',
          message: '성수 브런치 정산이 만들어졌어요.',
          timeLabel: '14:03',
          messageType: 'settlement_card',
          cardType: 'settlement',
          planId: '101',
          settlementId: '301',
          isMine: false,
        ),
      ],
    );
    final container = ProviderContainer(
      overrides: [
        groupRepositoryProvider.overrideWithValue(repository),
        settlementRepositoryProvider.overrideWithValue(
          _ChatSettlementRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final state = await container.read(groupChatViewModelProvider('1').future);

    expect(state.messages.single.sender, 'ONMU');
    expect(state.messages.single.isSettlementCard, isTrue);
    expect(state.messages.single.planId, '101');
    expect(state.messages.single.settlementId, '301');
    expect(state.messages.single.hasSettlementRoute, isTrue);
  });

  test('채팅 ViewModel은 draft 정산 미리보기를 보조 카드로 노출하지 않는다', () async {
    final repository = _FakeGroupRepository(
      fetchPlansCompleter: Completer<List<GroupPlanSummary>>()
        ..complete([
          GroupPlanSummary(
            id: 101,
            title: '오늘 약속 테스트',
            dateLabel: '6월 19일',
            startsAt: DateTime.utc(2099, 6, 19, 5),
            placeName: '수원',
            statusLabel: 'scheduled',
            statusType: 'scheduled',
            memberCount: 1,
            extraMemberCount: 0,
            iconKind: 'calendar',
            isPast: false,
          ),
        ]),
    );
    final container = ProviderContainer(
      overrides: [
        groupRepositoryProvider.overrideWithValue(repository),
        settlementRepositoryProvider.overrideWithValue(
          const _DraftChatSettlementRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    final provider = groupChatViewModelProvider('1');

    await container.read(provider.future);
    await pumpEventQueue();

    expect(container.read(provider).requireValue.settlement, isNull);
  });

  test('채팅 ViewModel은 현재 약속의 진행 중 투표가 없으면 투표 카드를 숨긴다', () async {
    final repository = _ChatNoCurrentVoteRepository();
    final container = ProviderContainer(
      overrides: [
        groupRepositoryProvider.overrideWithValue(repository),
        settlementRepositoryProvider.overrideWithValue(
          _ChatSettlementRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    final provider = groupChatViewModelProvider('1');

    await container.read(provider.future);
    await pumpEventQueue();

    final state = container.read(provider).requireValue;
    expect(repository.fetchedVoteTargetIds, ['101']);
    expect(state.planId, 101);
    expect(state.vote, isNull);
    expect(state.voteId, 0);
  });

  test('채팅 ViewModel은 보조 투표 deadline이 지나면 투표 카드를 숨긴다', () async {
    final now = DateTime.now();
    final repository = _FakeGroupRepository(
      fetchPlansCompleter: Completer<List<GroupPlanSummary>>()
        ..complete([
          GroupPlanSummary(
            id: 301,
            title: 'deadline 확인 약속',
            dateLabel: '오늘',
            startsAt: now.add(const Duration(hours: 1)),
            endsAt: now.add(const Duration(hours: 3)),
            placeName: '성수동',
            statusLabel: 'scheduled',
            statusType: 'scheduled',
            memberCount: 3,
            extraMemberCount: 0,
            iconKind: 'calendar',
            isPast: false,
          ),
        ]),
      fetchVotesCompleter: Completer<List<VoteSummary>>()
        ..complete([
          VoteSummary(
            id: 601,
            title: '곧 마감되는 장소 투표',
            statusLabel: '진행 중',
            description: '후보 2개',
            planLabel: 'deadline 확인 약속',
            planMeta: '오늘',
            participants: const [],
            participantCount: 0,
            options: const [],
            closed: false,
            joinedByMe: false,
            actionLabel: '투표 확인하기',
            targetType: 'PLAN',
            targetId: '301',
            deadlineAt: DateTime.now().add(const Duration(milliseconds: 80)),
          ),
        ]),
    );
    final container = ProviderContainer(
      overrides: [
        groupRepositoryProvider.overrideWithValue(repository),
        settlementRepositoryProvider.overrideWithValue(
          _ChatSettlementRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    final provider = groupChatViewModelProvider('1');

    await container.read(provider.future);
    await pumpEventQueue();

    expect(container.read(provider).requireValue.voteId, 601);
    expect(container.read(provider).requireValue.vote, isNotNull);

    await Future<void>.delayed(const Duration(milliseconds: 140));
    await pumpEventQueue();

    final state = container.read(provider).requireValue;
    expect(state.voteId, 0);
    expect(state.vote, isNull);
  });

  test('채팅 ViewModel은 지나지 않은 약속 중 가장 가까운 약속을 보조 카드로 선택한다', () async {
    final now = DateTime.now();
    final repository = _FakeGroupRepository(
      fetchPinnedPlanCompleter: Completer<GroupPinnedPlan?>()
        ..complete(
          const GroupPinnedPlan(
            id: 101,
            title: '지난 약속',
            dateLabel: '6월 18일',
            placeName: '수원',
            statusLabel: 'scheduled',
            voteSummary: '',
          ),
        ),
      fetchPlansCompleter: Completer<List<GroupPlanSummary>>()
        ..complete([
          GroupPlanSummary(
            id: 101,
            title: '지난 약속',
            dateLabel: '6월 18일',
            startsAt: now.subtract(const Duration(days: 1)),
            placeName: '수원',
            statusLabel: 'scheduled',
            statusType: 'scheduled',
            memberCount: 1,
            extraMemberCount: 0,
            iconKind: 'calendar',
            isPast: true,
          ),
          GroupPlanSummary(
            id: 102,
            title: '가장 가까운 미래 약속',
            dateLabel: '6월 20일',
            startsAt: now.add(const Duration(hours: 2)),
            placeName: '행궁동',
            statusLabel: 'scheduled',
            statusType: 'scheduled',
            memberCount: 1,
            extraMemberCount: 0,
            iconKind: 'calendar',
            isPast: false,
          ),
          GroupPlanSummary(
            id: 103,
            title: '더 먼 미래 약속',
            dateLabel: '6월 21일',
            startsAt: now.add(const Duration(days: 1)),
            placeName: '서울',
            statusLabel: 'scheduled',
            statusType: 'scheduled',
            memberCount: 1,
            extraMemberCount: 0,
            iconKind: 'calendar',
            isPast: false,
          ),
        ]),
    );
    final container = ProviderContainer(
      overrides: [
        groupRepositoryProvider.overrideWithValue(repository),
        settlementRepositoryProvider.overrideWithValue(
          _ChatSettlementRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    final provider = groupChatViewModelProvider('1');

    await container.read(provider.future);
    await pumpEventQueue();

    final state = container.read(provider).requireValue;
    expect(state.planId, 102);
    expect(state.pinnedPlan?.id, 102);
    expect(state.pinnedPlan?.title, '가장 가까운 미래 약속');
  });

  test('채팅 ViewModel은 진행 중인 약속을 미래 약속보다 먼저 보조 카드로 선택한다', () async {
    final now = DateTime.now();
    final repository = _FakeGroupRepository(
      fetchPlansCompleter: Completer<List<GroupPlanSummary>>()
        ..complete([
          GroupPlanSummary(
            id: 201,
            title: '지금 진행 중인 약속',
            dateLabel: '오늘',
            startsAt: now.subtract(const Duration(minutes: 30)),
            endsAt: now.add(const Duration(minutes: 90)),
            placeName: '성수동',
            statusLabel: 'scheduled',
            statusType: 'scheduled',
            memberCount: 3,
            extraMemberCount: 0,
            iconKind: 'calendar',
            isPast: false,
          ),
          GroupPlanSummary(
            id: 202,
            title: '가장 가까운 미래 약속',
            dateLabel: '곧',
            startsAt: now.add(const Duration(minutes: 10)),
            endsAt: now.add(const Duration(hours: 2)),
            placeName: '행궁동',
            statusLabel: 'scheduled',
            statusType: 'scheduled',
            memberCount: 3,
            extraMemberCount: 0,
            iconKind: 'calendar',
            isPast: false,
          ),
        ]),
    );
    final container = ProviderContainer(
      overrides: [
        groupRepositoryProvider.overrideWithValue(repository),
        settlementRepositoryProvider.overrideWithValue(
          _ChatSettlementRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    final provider = groupChatViewModelProvider('1');

    await container.read(provider.future);
    await pumpEventQueue();

    final state = container.read(provider).requireValue;
    expect(state.planId, 201);
    expect(state.pinnedPlan?.title, '지금 진행 중인 약속');
  });

  test('채팅 ViewModel은 지나지 않은 약속이 없으면 보조 약속 카드를 숨긴다', () async {
    final now = DateTime.now();
    final repository = _FakeGroupRepository(
      fetchPinnedPlanCompleter: Completer<GroupPinnedPlan?>()
        ..complete(
          const GroupPinnedPlan(
            id: 101,
            title: '지난 약속',
            dateLabel: '6월 18일',
            placeName: '수원',
            statusLabel: 'scheduled',
            voteSummary: '',
          ),
        ),
      fetchPlansCompleter: Completer<List<GroupPlanSummary>>()
        ..complete([
          GroupPlanSummary(
            id: 101,
            title: '지난 약속',
            dateLabel: '6월 18일',
            startsAt: now.subtract(const Duration(hours: 1)),
            placeName: '수원',
            statusLabel: 'scheduled',
            statusType: 'scheduled',
            memberCount: 1,
            extraMemberCount: 0,
            iconKind: 'calendar',
            isPast: true,
          ),
        ]),
    );
    final container = ProviderContainer(
      overrides: [
        groupRepositoryProvider.overrideWithValue(repository),
        settlementRepositoryProvider.overrideWithValue(
          _ChatSettlementRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    final provider = groupChatViewModelProvider('1');

    await container.read(provider.future);
    await pumpEventQueue();

    final state = container.read(provider).requireValue;
    expect(state.planId, 0);
    expect(state.pinnedPlan, isNull);
  });

  test('채팅 ViewModel은 서버 응답 전에도 pending 말풍선을 즉시 추가한다', () async {
    final sendCompleter = Completer<GroupMessage>();
    final repository = _FakeGroupRepository(
      sendMessageCompleter: sendCompleter,
    );
    final container = ProviderContainer(
      overrides: [
        groupRepositoryProvider.overrideWithValue(repository),
        settlementRepositoryProvider.overrideWithValue(
          _ChatSettlementRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    final provider = groupChatViewModelProvider('1');

    await container.read(provider.future);
    final sendFuture = container.read(provider.notifier).sendMessage('느린 전송');
    await pumpEventQueue();

    final pending = container.read(provider).requireValue.messages.single;
    expect(pending.message, '느린 전송');
    expect(pending.sendStatus, GroupMessageSendStatus.sending);
    expect(repository.sentMessages, ['느린 전송']);

    sendCompleter.complete(
      const GroupMessage(
        id: 'server-message-delayed',
        sender: '나',
        message: '느린 전송',
        timeLabel: '방금',
        isMine: true,
      ),
    );
    expect(await sendFuture, isTrue);

    final sent = container.read(provider).requireValue.messages.single;
    expect(sent.id, 'server-message-delayed');
    expect(sent.sendStatus, GroupMessageSendStatus.sent);
  });

  test('채팅 ViewModel은 사진 업로드 후 첨부 메시지를 전송한다', () async {
    final repository = _FakeGroupRepository();
    final mediaRepository = _FakeMediaRepository(
      uploaded: const GroupMessageAttachment(
        type: 'image',
        publicUrl:
            'https://dev-api.onmu.cloud/api/v1/media/public?key=records%2Fmedia%2Fphoto.jpg',
        storageKey: 'records/media/photo.jpg',
        contentType: 'image/jpeg',
        fileName: 'photo.jpg',
      ),
    );
    final container = ProviderContainer(
      overrides: [
        groupRepositoryProvider.overrideWithValue(repository),
        mediaRepositoryProvider.overrideWithValue(mediaRepository),
        settlementRepositoryProvider.overrideWithValue(
          _ChatSettlementRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    final provider = groupChatViewModelProvider('1');

    await container.read(provider.future);
    final sent = await container
        .read(provider.notifier)
        .sendImageMessage(
          const PickedChatImage(path: '/tmp/photo.jpg', fileName: 'photo.jpg'),
          text: '사진 공유해요',
        );
    final updated = container.read(provider).requireValue;

    expect(sent, isTrue);
    expect(mediaRepository.uploadedPaths, ['/tmp/photo.jpg']);
    expect(repository.sentMessages, ['사진 공유해요']);
    expect(
      repository.sentAttachments.single.single.storageKey,
      'records/media/photo.jpg',
    );
    expect(updated.messages.single.attachments.single.type, 'image');
    expect(updated.messages.single.sendStatus, GroupMessageSendStatus.sent);
  });

  test('채팅 ViewModel은 입장 시 새 메시지 구분선 수를 읽음 동기화와 분리해 보존한다', () async {
    final repository = _FakeGroupRepository(
      initialMessages: const [
        GroupMessage(
          id: 'message-1',
          sender: '민서',
          message: '새 메시지 확인해줘',
          timeLabel: '09:01',
          isMine: false,
        ),
      ],
      initialUnreadCount: 3,
    );
    final container = ProviderContainer(
      overrides: [
        groupRepositoryProvider.overrideWithValue(repository),
        settlementRepositoryProvider.overrideWithValue(
          _ChatSettlementRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    final provider = groupChatViewModelProvider('1');

    final state = await container.read(provider.future);

    expect(repository.markedReadMessages, ['message-1']);
    expect(state.unreadCount, 3);
  });

  test('채팅 ViewModel은 메시지 작성 실패 시 실패 말풍선과 오류를 남긴다', () async {
    final repository = _FakeGroupRepository(throwOnSend: true);
    final container = ProviderContainer(
      overrides: [
        groupRepositoryProvider.overrideWithValue(repository),
        settlementRepositoryProvider.overrideWithValue(
          _ChatSettlementRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    final provider = groupChatViewModelProvider('1');

    final initial = await container.read(provider.future);
    final sent = await container.read(provider.notifier).sendMessage('실패 요청');
    final updated = container.read(provider).requireValue;

    expect(initial.messages, isEmpty);
    expect(sent, isTrue);
    expect(updated.messages.single.message, '실패 요청');
    expect(updated.messages.single.sendStatus, GroupMessageSendStatus.failed);
    expect(updated.sendErrorMessage, '메시지를 보내지 못했어요.');
  });

  test('채팅 ViewModel은 실패한 메시지를 재시도해 서버 응답으로 교체한다', () async {
    final repository = _FakeGroupRepository(
      sendFailuresBeforeSuccess: 1,
      sentMessage: const GroupMessage(
        id: 'server-message-2',
        sender: '나',
        message: '재시도 성공',
        timeLabel: '방금',
        isMine: true,
      ),
    );
    final container = ProviderContainer(
      overrides: [
        groupRepositoryProvider.overrideWithValue(repository),
        settlementRepositoryProvider.overrideWithValue(
          _ChatSettlementRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    final provider = groupChatViewModelProvider('1');

    await container.read(provider.future);
    await container.read(provider.notifier).sendMessage('재시도 요청');
    final failed = container.read(provider).requireValue.messages.single;
    final retried = await container
        .read(provider.notifier)
        .retryMessage(failed.id);
    final updated = container.read(provider).requireValue;

    expect(failed.sendStatus, GroupMessageSendStatus.failed);
    expect(retried, isTrue);
    expect(repository.sentMessages, ['재시도 요청', '재시도 요청']);
    expect(updated.messages.single.id, 'server-message-2');
    expect(updated.messages.single.message, '재시도 성공');
    expect(updated.messages.single.sendStatus, GroupMessageSendStatus.sent);
    expect(updated.sendErrorMessage, isNull);
  });

  test('채팅 ViewModel은 realtime 메시지를 추가하고 중복 수신은 건너뛴다', () async {
    final realtime = StreamController<GroupMessage>();
    final repository = _FakeGroupRepository(
      initialMessages: const [
        GroupMessage(
          id: 'message-1',
          cursor: '2026-06-09T05:00:00Z',
          sender: '민서',
          message: '이미 본 메시지',
          timeLabel: '14:00',
          isMine: false,
        ),
      ],
      realtimeMessages: realtime.stream,
    );
    final container = ProviderContainer(
      overrides: [
        groupRepositoryProvider.overrideWithValue(repository),
        settlementRepositoryProvider.overrideWithValue(
          _ChatSettlementRepository(),
        ),
      ],
    );
    addTearDown(() async {
      await realtime.close();
      container.dispose();
    });
    final provider = groupChatViewModelProvider('1');

    await container.read(provider.future);
    realtime.add(
      const GroupMessage(
        id: 'message-1',
        cursor: '2026-06-09T05:00:00Z',
        sender: '민서',
        message: '이미 본 메시지',
        timeLabel: '14:00',
        isMine: false,
      ),
    );
    realtime.add(
      const GroupMessage(
        id: 'message-2',
        cursor: '2026-06-09T05:01:00Z',
        sender: '지우',
        message: '새로 온 메시지',
        timeLabel: '14:01',
        isMine: false,
      ),
    );
    await pumpEventQueue();

    final updated = container.read(provider).requireValue;
    expect(updated.messages.map((message) => message.id), [
      'message-1',
      'message-2',
    ]);
    expect(repository.markedReadMessages, contains('message-2'));
  });

  test(
    '채팅 ViewModel은 첨부-only realtime 수신 시 storageKey가 맞는 pending만 교체한다',
    () async {
      final realtime = StreamController<GroupMessage>();
      final repository = _FakeGroupRepository(
        initialMessages: const [
          GroupMessage(
            id: 'local-a',
            sender: '나',
            message: '',
            timeLabel: '전송 중',
            isMine: true,
            sendStatus: GroupMessageSendStatus.sending,
            attachments: [
              GroupMessageAttachment(
                type: 'image',
                publicUrl: 'https://dev-api.onmu.cloud/a.jpg',
                storageKey: 'records/media/a.jpg',
              ),
            ],
          ),
          GroupMessage(
            id: 'local-b',
            sender: '나',
            message: '',
            timeLabel: '전송 중',
            isMine: true,
            sendStatus: GroupMessageSendStatus.sending,
            attachments: [
              GroupMessageAttachment(
                type: 'image',
                publicUrl: 'https://dev-api.onmu.cloud/b.jpg',
                storageKey: 'records/media/b.jpg',
              ),
            ],
          ),
        ],
        realtimeMessages: realtime.stream,
      );
      final container = ProviderContainer(
        overrides: [
          groupRepositoryProvider.overrideWithValue(repository),
          settlementRepositoryProvider.overrideWithValue(
            _ChatSettlementRepository(),
          ),
        ],
      );
      addTearDown(() async {
        await realtime.close();
        container.dispose();
      });
      final provider = groupChatViewModelProvider('1');

      await container.read(provider.future);
      realtime.add(
        const GroupMessage(
          id: 'server-b',
          cursor: '2026-06-09T05:02:00Z',
          sender: '나',
          message: '',
          timeLabel: '14:02',
          isMine: true,
          attachments: [
            GroupMessageAttachment(
              type: 'image',
              publicUrl: 'https://dev-api.onmu.cloud/b.jpg',
              storageKey: 'records/media/b.jpg',
            ),
          ],
        ),
      );
      await pumpEventQueue();

      final updated = container.read(provider).requireValue;
      expect(updated.messages.map((message) => message.id), [
        'local-a',
        'server-b',
      ]);
      expect(updated.messages.first.sendStatus, GroupMessageSendStatus.sending);
      expect(
        updated.messages.last.attachments.single.storageKey,
        'records/media/b.jpg',
      );
      expect(repository.markedReadMessages, contains('server-b'));
    },
  );

  test('채팅 ViewModel은 realtime stream 오류가 나도 기존 메시지를 유지한다', () async {
    final realtime = StreamController<GroupMessage>();
    final repository = _FakeGroupRepository(
      initialMessages: const [
        GroupMessage(
          id: 'message-1',
          sender: '민서',
          message: '유지할 메시지',
          timeLabel: '14:00',
          isMine: false,
        ),
      ],
      realtimeMessages: realtime.stream,
    );
    final container = ProviderContainer(
      overrides: [
        groupRepositoryProvider.overrideWithValue(repository),
        settlementRepositoryProvider.overrideWithValue(
          _ChatSettlementRepository(),
        ),
      ],
    );
    addTearDown(() async {
      await realtime.close();
      container.dispose();
    });
    final provider = groupChatViewModelProvider('1');

    await container.read(provider.future);
    realtime.addError(StateError('stream failed'));
    await pumpEventQueue();

    final updated = container.read(provider).requireValue;
    expect(updated.messages.single.message, '유지할 메시지');
    expect(updated.sendErrorMessage, isNull);
  });

  test('채팅 ViewModel은 timestamp cursor가 없으면 afterCursor를 보내지 않는다', () async {
    final repository = _FakeGroupRepository(
      initialMessages: const [
        GroupMessage(
          id: 'message-id-only',
          sender: '민서',
          message: 'cursor 없는 메시지',
          timeLabel: '14:00',
          isMine: false,
        ),
      ],
    );
    final container = ProviderContainer(
      overrides: [
        groupRepositoryProvider.overrideWithValue(repository),
        settlementRepositoryProvider.overrideWithValue(
          _ChatSettlementRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    final provider = groupChatViewModelProvider('1');

    await container.read(provider.future);

    expect(repository.watchedAfterCursors.single, isNull);
  });

  test('채팅 ViewModel dispose는 realtime subscription을 정리한다', () async {
    var canceled = false;
    final realtime = StreamController<GroupMessage>(
      onCancel: () {
        canceled = true;
      },
    );
    final repository = _FakeGroupRepository(realtimeMessages: realtime.stream);
    final container = ProviderContainer(
      overrides: [
        groupRepositoryProvider.overrideWithValue(repository),
        settlementRepositoryProvider.overrideWithValue(
          _ChatSettlementRepository(),
        ),
      ],
    );
    final provider = groupChatViewModelProvider('1');

    await container.read(provider.future);
    container.dispose();
    await pumpEventQueue();

    expect(canceled, isTrue);
    await realtime.close();
  });
}

OotdRecord _recordForMutation({String? id}) {
  return OotdRecord(
    id: id,
    date: DateTime.parse('2026-06-17T10:00:00+09:00'),
    character: const CharacterDraft(),
    moodTags: const ['daily'],
    brands: const {'recordType': 'daily'},
    timeline: const [
      TimelineItem(
        time: '10:00',
        placeName: '성수',
        category: 'daily',
        description: 'ViewModel 경계 테스트',
      ),
    ],
  );
}

class _FakeGroupRepository implements GroupRepository {
  _FakeGroupRepository({
    this.sentMessage,
    this.throwOnSend = false,
    this.sendFailuresBeforeSuccess = 0,
    this.throwOnFetchMemories = false,
    this.throwOnFetchMessages = false,
    this.initialMessages = const [],
    this.initialUnreadCount = 0,
    this.fetchPinnedPlanCompleter,
    this.fetchPlansCompleter,
    this.fetchVotesCompleter,
    this.sendMessageCompleter,
    Stream<GroupMessage>? realtimeMessages,
  }) : realtimeMessages =
           realtimeMessages ?? Stream<GroupMessage>.multi((_) {}),
       _remainingSendFailures = sendFailuresBeforeSuccess;

  final GroupMessage? sentMessage;
  final bool throwOnSend;
  final int sendFailuresBeforeSuccess;
  final bool throwOnFetchMemories;
  final bool throwOnFetchMessages;
  final List<GroupMessage> initialMessages;
  final int initialUnreadCount;
  final Completer<GroupPinnedPlan?>? fetchPinnedPlanCompleter;
  final Completer<List<GroupPlanSummary>>? fetchPlansCompleter;
  final Completer<List<VoteSummary>>? fetchVotesCompleter;
  final Completer<GroupMessage>? sendMessageCompleter;
  final Stream<GroupMessage> realtimeMessages;
  final sentMessages = <String>[];
  final sentAttachments = <List<GroupMessageAttachment>>[];
  final markedReadMessages = <String?>[];
  final watchedAfterCursors = <String?>[];
  int _remainingSendFailures;

  static final _group = GroupSummary(
    id: 9001,
    name: 'Spring API 전환 모임',
    description: 'repository 교체만으로 서버 데이터를 읽는 구조',
    members: ['지우', '민수'],
    lastMessage: '서버 DTO 연결 준비 완료',
    unreadCount: 0,
    pinnedPlanTitle: 'API 계약 점검',
  );

  @override
  Future<GroupSummary> fetchGroup(Object groupId) async => _group;

  @override
  Future<GroupSummary> createGroup(GroupCreateInput input) async =>
      GroupSummary(
        id: 9002,
        name: input.name,
        description: input.description,
        members: input.memberNames,
        lastMessage: '생성됨',
        unreadCount: 0,
        pinnedPlanTitle: '첫 약속 없음',
      );

  @override
  Future<GroupSummary> updateGroup({
    required Object groupId,
    required String name,
    required String description,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<GroupSummary>> fetchGroups() async => [_group];

  @override
  Future<List<GroupPlanSummary>> fetchPlans(Object groupId) async {
    final completer = fetchPlansCompleter;
    if (completer != null) {
      return completer.future;
    }
    return [];
  }

  @override
  Future<List<GroupMemoryRecord>> fetchMemories(Object groupId) async {
    if (throwOnFetchMemories) {
      throw StateError('memories failed');
    }
    return [];
  }

  @override
  Future<List<GroupMemberProfile>> fetchMembers(Object groupId) async => [];

  @override
  Future<List<GroupMemberProfile>> fetchPlanParticipantCandidates({
    required Object groupId,
    required List<String> userIds,
  }) async {
    final normalizedUserIds = userIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    return (await fetchMembers(groupId))
        .where((member) => normalizedUserIds.contains(member.userId.trim()))
        .toList(growable: false);
  }

  @override
  Future<GroupMemberProfile> addMember({
    required Object groupId,
    required String userId,
  }) async => GroupMemberProfile(
    userId: userId,
    name: '초대 친구',
    note: '멤버',
    statusLabel: '참여 중',
  );

  @override
  Future<List<GroupMessage>> fetchMessages(Object groupId) async {
    if (throwOnFetchMessages) {
      throw StateError('messages failed');
    }
    return initialMessages;
  }

  @override
  Future<GroupMessagePage> fetchMessagePage(
    Object groupId, {
    String? beforeCursor,
    int? limit,
  }) async {
    return GroupMessagePage(
      messages: initialMessages,
      unreadCount: initialUnreadCount,
    );
  }

  @override
  Future<GroupMessage> sendMessage({
    required Object groupId,
    required String message,
    List<GroupMessageAttachment> attachments = const [],
  }) async {
    sentMessages.add(message);
    sentAttachments.add(attachments);
    if (throwOnSend || _remainingSendFailures > 0) {
      if (_remainingSendFailures > 0) {
        _remainingSendFailures -= 1;
      }
      throw StateError('send failed');
    }
    final completer = sendMessageCompleter;
    if (completer != null) {
      return completer.future;
    }
    return sentMessage ??
        GroupMessage(
          id: 'server-message-${sentMessages.length}',
          sender: '나',
          message: message,
          timeLabel: '방금',
          isMine: true,
          attachments: attachments,
        );
  }

  @override
  Future<int> markMessagesRead({
    required Object groupId,
    String? lastReadMessageId,
  }) async {
    markedReadMessages.add(lastReadMessageId);
    return 0;
  }

  @override
  Stream<GroupMessage> watchMessages(Object groupId, {String? afterCursor}) {
    watchedAfterCursors.add(afterCursor);
    return realtimeMessages;
  }

  @override
  Future<GroupPinnedPlan?> fetchPinnedPlan(Object groupId) async {
    final completer = fetchPinnedPlanCompleter;
    if (completer != null) {
      return completer.future;
    }
    return null;
  }

  @override
  Future<GroupMemoryRecord> fetchMemory({
    required Object groupId,
    required Object memoryId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<VoteSummary>> fetchVotes(
    Object groupId, {
    String? targetType,
    Object? targetId,
  }) async {
    final completer = fetchVotesCompleter;
    if (completer != null) {
      return completer.future;
    }
    return [];
  }

  @override
  Future<VoteSummary> createVote(VoteCreateInput input) {
    throw UnimplementedError();
  }

  @override
  Future<VoteCard> fetchVoteCard({
    required Object groupId,
    required Object voteId,
  }) async => const VoteCard(
    title: '테스트 투표',
    summary: '테스트 후보',
    statusLabel: '진행 중',
    actionLabel: '투표 보기',
  );

  @override
  Future<VoteCard> submitVote({
    required Object groupId,
    required Object voteId,
    required Object optionId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Map<int, List<String>>> fetchVoteVoters({
    required Object groupId,
    required Object voteId,
  }) {
    throw UnimplementedError();
  }
}

class _ChatNoCurrentVoteRepository extends _FakeGroupRepository {
  final fetchedVoteTargetIds = <String?>[];

  @override
  Future<GroupPinnedPlan?> fetchPinnedPlan(Object groupId) async {
    return const GroupPinnedPlan(
      id: 101,
      title: '제주도 여행',
      dateLabel: '6월 7일',
      placeName: '제주',
      statusLabel: 'scheduled',
      voteSummary: '',
    );
  }

  @override
  Future<List<GroupPlanSummary>> fetchPlans(Object groupId) async {
    return [
      GroupPlanSummary(
        id: 101,
        title: '제주도 여행',
        dateLabel: '6월 7일',
        startsAt: DateTime.now().add(const Duration(days: 1)),
        placeName: '제주',
        statusLabel: 'scheduled',
        statusType: 'scheduled',
        memberCount: 4,
        extraMemberCount: 0,
        iconKind: 'calendar',
        isPast: false,
      ),
    ];
  }

  @override
  Future<List<VoteSummary>> fetchVotes(
    Object groupId, {
    String? targetType,
    Object? targetId,
  }) async {
    fetchedVoteTargetIds.add(targetId?.toString());
    if (targetType == 'PLAN' && targetId?.toString() == '101') {
      return const [];
    }
    return [
      VoteSummary(
        id: 501,
        title: '다른 약속 투표',
        statusLabel: '진행 중',
        description: '현재 약속이 아닌 투표',
        planLabel: '다른 약속',
        planMeta: '6월 10일',
        participants: const ['민서'],
        participantCount: 1,
        options: const [],
        closed: false,
        joinedByMe: false,
        actionLabel: '투표 보기',
        targetType: 'PLAN',
        targetId: '105',
      ),
    ];
  }
}

class _FakeMediaRepository implements MediaRepository {
  _FakeMediaRepository({required this.uploaded});

  final GroupMessageAttachment uploaded;
  final uploadedPaths = <String>[];

  @override
  Future<GroupMessageAttachment> uploadChatImage(PickedChatImage image) async {
    uploadedPaths.add(image.path);
    return uploaded;
  }
}

class _EmptyGroupRepository implements GroupRepository {
  @override
  Future<GroupSummary> fetchGroup(Object groupId) {
    throw UnimplementedError();
  }

  @override
  Future<GroupSummary> createGroup(GroupCreateInput input) async =>
      GroupSummary(
        id: 1,
        name: input.name,
        description: input.description,
        members: input.memberNames,
        lastMessage: '',
        unreadCount: 0,
        pinnedPlanTitle: '첫 약속 없음',
      );

  @override
  Future<GroupSummary> updateGroup({
    required Object groupId,
    required String name,
    required String description,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<GroupSummary>> fetchGroups() async => [];

  @override
  Future<GroupPinnedPlan?> fetchPinnedPlan(Object groupId) async => null;

  @override
  Future<List<GroupPlanSummary>> fetchPlans(Object groupId) async => [];

  @override
  Future<List<GroupMemberProfile>> fetchMembers(Object groupId) async => [];

  @override
  Future<List<GroupMemberProfile>> fetchPlanParticipantCandidates({
    required Object groupId,
    required List<String> userIds,
  }) async {
    final normalizedUserIds = userIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    return (await fetchMembers(groupId))
        .where((member) => normalizedUserIds.contains(member.userId.trim()))
        .toList(growable: false);
  }

  @override
  Future<GroupMemberProfile> addMember({
    required Object groupId,
    required String userId,
  }) async => GroupMemberProfile(
    userId: userId,
    name: '초대 친구',
    note: '멤버',
    statusLabel: '참여 중',
  );

  @override
  Future<List<GroupMemoryRecord>> fetchMemories(Object groupId) async => [];

  @override
  Future<List<GroupMessage>> fetchMessages(Object groupId) async => [];

  @override
  Future<GroupMessagePage> fetchMessagePage(
    Object groupId, {
    String? beforeCursor,
    int? limit,
  }) async {
    return const GroupMessagePage(messages: []);
  }

  @override
  Future<GroupMessage> sendMessage({
    required Object groupId,
    required String message,
    List<GroupMessageAttachment> attachments = const [],
  }) {
    throw UnimplementedError();
  }

  @override
  Future<int> markMessagesRead({
    required Object groupId,
    String? lastReadMessageId,
  }) {
    throw UnimplementedError();
  }

  @override
  Stream<GroupMessage> watchMessages(Object groupId, {String? afterCursor}) {
    return Stream<GroupMessage>.multi((_) {});
  }

  @override
  Future<List<VoteSummary>> fetchVotes(
    Object groupId, {
    String? targetType,
    Object? targetId,
  }) async => [];

  @override
  Future<VoteSummary> createVote(VoteCreateInput input) {
    throw UnimplementedError();
  }

  @override
  Future<VoteCard> fetchVoteCard({
    required Object groupId,
    required Object voteId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<VoteCard> submitVote({
    required Object groupId,
    required Object voteId,
    required Object optionId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Map<int, List<String>>> fetchVoteVoters({
    required Object groupId,
    required Object voteId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<GroupMemoryRecord> fetchMemory({
    required Object groupId,
    required Object memoryId,
  }) {
    throw UnimplementedError();
  }
}

class _VoteSelectionGroupRepository extends _EmptyGroupRepository {
  final selectedOptionIds = <String>[];

  @override
  Future<GroupSummary> fetchGroup(Object groupId) async =>
      _FakeGroupRepository._group;

  @override
  Future<VoteCard> fetchVoteCard({
    required Object groupId,
    required Object voteId,
  }) async {
    return VoteCard(
      title: '테스트 투표',
      summary: '온무식당',
      statusLabel: 'open',
      actionLabel: '투표 보기',
      targetType: 'PLAN',
      targetId: '101',
      options: [
        VoteOptionSummary(
          id: 'vopt-501-1',
          label: '온무식당',
          countLabel: '0표',
          progress: 0,
          candidateId: '9901',
          targetType: 'PLACE_CANDIDATE',
          targetId: '9901',
        ),
        VoteOptionSummary(
          id: 'vopt-501-2',
          label: '다른 식당',
          countLabel: '0표',
          progress: 0,
          candidateId: '9902',
          targetType: 'PLACE_CANDIDATE',
          targetId: '9902',
        ),
      ],
    );
  }

  @override
  Future<VoteCard> submitVote({
    required Object groupId,
    required Object voteId,
    required Object optionId,
  }) async {
    selectedOptionIds.add(optionId.toString());
    return fetchVoteCard(groupId: groupId, voteId: voteId);
  }

  @override
  Future<Map<int, List<String>>> fetchVoteVoters({
    required Object groupId,
    required Object voteId,
  }) async {
    return const {};
  }
}

class _SparseGroupListRepository extends _EmptyGroupRepository {
  _SparseGroupListRepository({
    List<GroupPlanSummary>? plans,
    this.throwOnFetchPlans = false,
  }) : plans = plans ?? _defaultPlans;

  final List<GroupPlanSummary> plans;
  final bool throwOnFetchPlans;

  static const _group = GroupSummary(
    id: 77,
    name: '요약 부족 모임',
    description: '목록 응답이 일부 필드를 생략한 상태',
    members: [],
    lastMessage: '',
    unreadCount: 0,
    pinnedPlanTitle: '',
  );

  @override
  Future<List<GroupSummary>> fetchGroups() async => const [_group];

  @override
  Future<List<GroupMemberProfile>> fetchMembers(Object groupId) async {
    return const [
      GroupMemberProfile(
        userId: 'user-jiwoo',
        name: '지우',
        note: '참여 중',
        statusLabel: '참여 중',
        profileImageUrl: 'https://cdn.onmu.test/jiwoo.png',
      ),
      GroupMemberProfile(
        userId: 'user-minsu',
        name: '민수',
        note: '참여 중',
        statusLabel: '참여 중',
      ),
    ];
  }

  @override
  Future<GroupMemberProfile> addMember({
    required Object groupId,
    required String userId,
  }) async => GroupMemberProfile(
    userId: userId,
    name: '초대 친구',
    note: '멤버',
    statusLabel: '참여 중',
  );

  static final _defaultPlans = [
    GroupPlanSummary(
      id: 7701,
      title: '서버 보강 약속',
      dateLabel: '6월 18일 10:00',
      startsAt: DateTime.utc(2099, 6, 18, 1),
      placeName: '성수동',
      statusLabel: '예정',
      statusType: 'scheduled',
      memberCount: 2,
      extraMemberCount: 0,
      iconKind: 'coffee',
      isPast: false,
    ),
  ];

  @override
  Future<List<GroupPlanSummary>> fetchPlans(Object groupId) async {
    if (throwOnFetchPlans) {
      throw StateError('plans failed');
    }
    return plans;
  }
}

class _TodayPlansGroupRepository extends _EmptyGroupRepository {
  static const _group = GroupSummary(
    id: 7,
    name: '오늘 약속 모임',
    description: '',
    members: [],
    lastMessage: '',
    unreadCount: 0,
    pinnedPlanTitle: '',
  );

  @override
  Future<List<GroupSummary>> fetchGroups() async => const [_group];

  @override
  Future<GroupSummary> fetchGroup(Object groupId) async => _group;

  @override
  Future<List<GroupPlanSummary>> fetchPlans(Object groupId) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final alreadyEnded = today.add(const Duration(hours: 1));
    final remainingToday = today.add(const Duration(minutes: 1));
    final anotherRemainingToday = today.add(const Duration(hours: 2));
    final tomorrow = today.add(const Duration(days: 1, hours: 9));

    return [
      GroupPlanSummary(
        id: 71,
        title: '종료된 약속',
        dateLabel: '오늘 오전 1:00',
        startsAt: alreadyEnded,
        endsAt: now.subtract(const Duration(seconds: 1)),
        placeName: '성수',
        statusLabel: '예정',
        statusType: '예정',
        memberCount: 1,
        extraMemberCount: 0,
        iconKind: 'coffee',
        isPast: false,
      ),
      GroupPlanSummary(
        id: 72,
        title: '오늘 남은 약속',
        dateLabel: '오늘 하루 중',
        startsAt: remainingToday,
        endsAt: today.add(const Duration(days: 1)),
        placeName: '한남',
        statusLabel: '예정',
        statusType: '예정',
        memberCount: 1,
        extraMemberCount: 0,
        iconKind: 'food',
        isPast: false,
      ),
      GroupPlanSummary(
        id: 74,
        title: '오늘 두 번째 약속',
        dateLabel: '오늘 낮',
        startsAt: anotherRemainingToday,
        endsAt: today.add(const Duration(days: 1)),
        placeName: '성수',
        statusLabel: '예정',
        statusType: '예정',
        memberCount: 1,
        extraMemberCount: 0,
        iconKind: 'coffee',
        isPast: false,
      ),
      GroupPlanSummary(
        id: 73,
        title: '내일 약속',
        dateLabel: '내일 오전 9:00',
        startsAt: tomorrow,
        placeName: '홍대',
        statusLabel: '예정',
        statusType: '예정',
        memberCount: 1,
        extraMemberCount: 0,
        iconKind: 'gallery',
        isPast: false,
      ),
    ];
  }
}

class _TodayPlansPlanRepository implements PlanRepository {
  @override
  Future<Plan> fetchPlan({
    required Object groupId,
    required Object planId,
  }) async {
    return Plan(
      id: int.parse(planId.toString()),
      title: '아침 약속',
      dateTime: '오늘 오전 9:00',
      location: '성수',
      status: '예정',
      memo: '',
      members: const [],
      timeCandidates: const [],
      visitPlan: const [],
    );
  }

  @override
  Future<Plan> createPlan(PlanCreateInput input) {
    throw UnimplementedError();
  }

  @override
  Future<Plan> updatePlan({
    required Object planId,
    required PlanCreateInput input,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<List<VisitPlan>>> fetchVisitPlansByDate({
    required Object groupId,
    required Object planId,
  }) {
    throw UnimplementedError();
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
  }) {
    throw UnimplementedError();
  }

  @override
  Future<PlanParticipantArrival> addParticipant({
    required Object groupId,
    required Object planId,
    required String userId,
  }) {
    throw UnimplementedError();
  }
}

class _UpcomingOrderRepository extends _EmptyGroupRepository {
  static final _now = DateTime.now();
  static final _today = DateTime(_now.year, _now.month, _now.day);
  static const _group = GroupSummary(
    id: 8,
    name: '정렬 테스트 모임',
    description: '',
    members: [],
    lastMessage: '',
    unreadCount: 0,
    pinnedPlanTitle: '',
  );

  @override
  Future<List<GroupSummary>> fetchGroups() async => const [_group];

  @override
  Future<GroupSummary> fetchGroup(Object groupId) async => _group;

  @override
  Future<List<GroupPlanSummary>> fetchPlans(Object groupId) async => [
    GroupPlanSummary(
      id: 82,
      title: '다음 주 약속',
      dateLabel: '다음 주 오후 7:00',
      startsAt: _today.add(const Duration(days: 7, hours: 19)),
      placeName: '성수',
      statusLabel: 'scheduled',
      statusType: 'scheduled',
      memberCount: 1,
      extraMemberCount: 0,
      iconKind: 'coffee',
      isPast: false,
    ),
    GroupPlanSummary(
      id: 81,
      title: '내일 약속',
      dateLabel: '내일 오후 2:00',
      startsAt: _today.add(const Duration(days: 1, hours: 14)),
      placeName: '한남',
      statusLabel: 'scheduled',
      statusType: 'scheduled',
      memberCount: 1,
      extraMemberCount: 0,
      iconKind: 'food',
      isPast: false,
    ),
    GroupPlanSummary(
      id: 80,
      title: '지난 약속',
      dateLabel: '어제 오후 2:00',
      startsAt: _today
          .subtract(const Duration(days: 1))
          .add(const Duration(hours: 14)),
      placeName: '홍대',
      statusLabel: 'completed',
      statusType: 'completed',
      memberCount: 1,
      extraMemberCount: 0,
      iconKind: 'gallery',
      isPast: false,
    ),
    const GroupPlanSummary(
      id: 83,
      title: '시간 미정 약속',
      dateLabel: '일정 미정',
      startsAt: null,
      placeName: '장소 미정',
      statusLabel: 'scheduled',
      statusType: 'scheduled',
      memberCount: 1,
      extraMemberCount: 0,
      iconKind: 'coffee',
      isPast: false,
    ),
  ];
}

class _UpcomingOrderPlanRepository extends _TodayPlansPlanRepository {
  @override
  Future<Plan> fetchPlan({
    required Object groupId,
    required Object planId,
  }) async {
    return Plan(
      id: int.parse(planId.toString()),
      title: '내일 약속',
      dateTime: '내일 오후 2:00',
      location: '한남',
      status: 'scheduled',
      memo: '',
      members: const [],
      timeCandidates: const [],
      visitPlan: const [],
    );
  }
}

class _NoActivePlanRepository extends _EmptyGroupRepository {
  static final _now = DateTime.now();
  static final _today = DateTime(_now.year, _now.month, _now.day);
  static const _group = GroupSummary(
    id: 9,
    name: '진행 중 없음 모임',
    description: '',
    members: [],
    lastMessage: '',
    unreadCount: 0,
    pinnedPlanTitle: '',
  );

  @override
  Future<List<GroupSummary>> fetchGroups() async => const [_group];

  @override
  Future<GroupSummary> fetchGroup(Object groupId) async => _group;

  @override
  Future<GroupPinnedPlan?> fetchPinnedPlan(Object groupId) async =>
      const GroupPinnedPlan(
        id: 90,
        title: '완료된 약속',
        dateLabel: '어제 오후 2:00',
        placeName: '성수',
        statusLabel: 'completed',
        voteSummary: '',
      );

  @override
  Future<List<GroupPlanSummary>> fetchPlans(Object groupId) async => [
    GroupPlanSummary(
      id: 90,
      title: '완료된 약속',
      dateLabel: '어제 오후 2:00',
      startsAt: _today.subtract(const Duration(days: 1, hours: -14)),
      placeName: '성수',
      statusLabel: 'completed',
      statusType: 'completed',
      memberCount: 1,
      extraMemberCount: 0,
      iconKind: 'coffee',
      isPast: true,
    ),
    GroupPlanSummary(
      id: 91,
      title: '내일 약속',
      dateLabel: '내일 오후 2:00',
      startsAt: _today.add(const Duration(days: 1, hours: 14)),
      placeName: '한남',
      statusLabel: 'scheduled',
      statusType: 'scheduled',
      memberCount: 1,
      extraMemberCount: 0,
      iconKind: 'food',
      isPast: false,
    ),
  ];
}

class _UnusedPlanRepository implements PlanRepository {
  @override
  Future<Plan> fetchPlan({required Object groupId, required Object planId}) {
    throw StateError('빈 홈 상태에서는 약속 상세를 조회하지 않아야 합니다.');
  }

  @override
  Future<Plan> createPlan(PlanCreateInput input) {
    throw UnimplementedError();
  }

  @override
  Future<Plan> updatePlan({
    required Object planId,
    required PlanCreateInput input,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<List<VisitPlan>>> fetchVisitPlansByDate({
    required Object groupId,
    required Object planId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<PlanParticipantArrival>> fetchPlanParticipants({
    required Object groupId,
    required Object planId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<PlanParticipantArrival> updateMyArrivalStatus({
    required Object groupId,
    required Object planId,
    required PlanArrivalStatus status,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<PlanParticipantArrival> leaveAsCurrentUser({
    required Object groupId,
    required Object planId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<PlanParticipantArrival> addParticipant({
    required Object groupId,
    required Object planId,
    required String userId,
  }) {
    throw UnimplementedError();
  }
}

class _RecordingPlanCreateRepository extends _UnusedPlanRepository {
  final createdInputs = <PlanCreateInput>[];

  @override
  Future<Plan> createPlan(PlanCreateInput input) async {
    createdInputs.add(input);
    return Plan(
      id: 3301,
      title: input.title,
      dateTime: input.dateTime,
      location: input.location,
      status: 'scheduled',
      memo: input.memo,
      members: input.members,
      timeCandidates: const [],
      visitPlan: const [],
    );
  }
}

class _RecordingRecordRepository implements RecordRepository {
  final createdRecords = <OotdRecord>[];
  final deletedIds = <String>[];
  final uploadedFiles = <String>[];

  @override
  Future<List<OotdRecord>> fetchMyRecords() async => const [];

  @override
  Future<OotdRecord> createRecord(OotdRecord record) async {
    createdRecords.add(record);
    return record.copyWith(id: 'record-created');
  }

  @override
  Future<OotdRecord> fetchRecord(String id) {
    throw UnimplementedError();
  }

  @override
  Future<OotdRecord> updateRecord(String id, OotdRecord record) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteRecord(String id) async {
    deletedIds.add(id);
  }

  @override
  Future<String> uploadMedia(Uint8List bytes, String fileName) async {
    uploadedFiles.add(fileName);
    return 'https://cdn.onmu.test/$fileName';
  }
}

class _UnusedSettlementRepository implements SettlementRepository {
  @override
  Future<SettlementSummary> fetchSettlement({
    required Object groupId,
    required Object planId,
  }) {
    throw StateError('빈 홈 상태에서는 정산 정보를 조회하지 않아야 합니다.');
  }

  @override
  Future<SettlementSummary> fetchSettlementById({
    required Object groupId,
    required Object planId,
    required Object settlementId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<SettlementSummary> fetchSettlementDraft({
    required Object groupId,
    required Object planId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<SettlementSummary> updateSettlementDraft({
    required Object groupId,
    required Object planId,
    required List<SettlementDraftItemInput> items,
    String? memo,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<SettlementSummary> updateSettlementDraftItemTargets({
    required Object groupId,
    required Object planId,
    required Object itemId,
    required List<String> targetUserIds,
    required List<String> targetNames,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<SettlementSummary> previewSettlement({
    required Object groupId,
    required Object planId,
    required List<SettlementDraftItemInput> items,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<SettlementSummary> createSettlement({
    required Object groupId,
    required Object planId,
    required List<SettlementDraftItemInput> items,
  }) {
    throw UnimplementedError();
  }
}

class _MutableGroupMemberRepository extends _FakeGroupRepository {
  final _members = <GroupMemberProfile>[];

  @override
  Future<List<GroupMemberProfile>> fetchMembers(Object groupId) async {
    return List.unmodifiable(_members);
  }

  @override
  Future<GroupMemberProfile> addMember({
    required Object groupId,
    required String userId,
  }) async {
    final member = GroupMemberProfile(
      userId: userId,
      name: '새 멤버',
      note: '멤버',
      statusLabel: '참여 중',
    );
    _members.add(member);
    return member;
  }
}

class _PlanMemberOptionStatusRepository extends _FakeGroupRepository {
  @override
  Future<List<GroupMemberProfile>> fetchMembers(Object groupId) async {
    return const [
      GroupMemberProfile(
        userId: 'user-chando',
        name: '찬도치',
        note: '참여 풀',
        statusLabel: '참여 중',
        profileImageUrl: 'https://example.test/chando.png',
      ),
    ];
  }
}

class _PlanMemberPreferenceRepository extends _FakeGroupRepository {
  final requestedUserIds = <String>[];

  @override
  Future<List<GroupMemberProfile>> fetchPlanParticipantCandidates({
    required Object groupId,
    required List<String> userIds,
  }) async {
    requestedUserIds.addAll(userIds);
    return [
      GroupMemberProfile(
        userId: 'user-chando',
        name: '찬도치',
        note: '참여 풀',
        statusLabel: '참여 중',
        preferenceProfile: PreferenceProfile.empty().copyWith(
          preferredWeekdays: ['SATURDAY'],
          preferredTimes: ['afternoon'],
        ),
      ),
    ];
  }
}

class _ChatSettlementRepository implements SettlementRepository {
  const _ChatSettlementRepository();

  static const _summary = SettlementSummary(
    id: '301',
    planTitle: '테스트 약속',
    totalAmountLabel: '0원',
    createdDateLabel: '',
    itemCountLabel: '0개',
    finalSummaryLabel: '정산 없음',
    mySummaryLabel: '정산 없음',
    paymentItems: [],
    memberResults: [],
    transfers: [],
    shareMessage: '',
  );

  @override
  Future<SettlementSummary> fetchSettlement({
    required Object groupId,
    required Object planId,
  }) async => _summary;

  @override
  Future<SettlementSummary> fetchSettlementById({
    required Object groupId,
    required Object planId,
    required Object settlementId,
  }) async => _summary;

  @override
  Future<SettlementSummary> fetchSettlementDraft({
    required Object groupId,
    required Object planId,
  }) async => _summary;

  @override
  Future<SettlementSummary> updateSettlementDraft({
    required Object groupId,
    required Object planId,
    required List<SettlementDraftItemInput> items,
    String? memo,
  }) async => _summary;

  @override
  Future<SettlementSummary> updateSettlementDraftItemTargets({
    required Object groupId,
    required Object planId,
    required Object itemId,
    required List<String> targetUserIds,
    required List<String> targetNames,
  }) async => _summary;

  @override
  Future<SettlementSummary> previewSettlement({
    required Object groupId,
    required Object planId,
    required List<SettlementDraftItemInput> items,
  }) async => _summary;

  @override
  Future<SettlementSummary> createSettlement({
    required Object groupId,
    required Object planId,
    required List<SettlementDraftItemInput> items,
  }) async => _summary;
}

class _DraftChatSettlementRepository extends _ChatSettlementRepository {
  const _DraftChatSettlementRepository();

  static const _draftSummary = SettlementSummary(
    id: 'draft',
    planTitle: '테스트 약속',
    totalAmountLabel: '0원',
    createdDateLabel: '미리보기',
    itemCountLabel: '0개',
    finalSummaryLabel: '정산 없음',
    mySummaryLabel: '정산 없음',
    paymentItems: [],
    memberResults: [],
    transfers: [],
    shareMessage: '',
    preview: true,
  );

  @override
  Future<SettlementSummary> fetchSettlement({
    required Object groupId,
    required Object planId,
  }) async => _draftSummary;
}

class _TrackingSettlementRepository extends _ChatSettlementRepository {
  final fetchByIdCalls = <String>[];
  var fetchLatestCalls = 0;

  @override
  Future<SettlementSummary> fetchSettlement({
    required Object groupId,
    required Object planId,
  }) async {
    fetchLatestCalls += 1;
    return _ChatSettlementRepository._summary;
  }

  @override
  Future<SettlementSummary> fetchSettlementById({
    required Object groupId,
    required Object planId,
    required Object settlementId,
  }) async {
    fetchByIdCalls.add('$groupId/$planId/$settlementId');
    return _ChatSettlementRepository._summary;
  }
}

class _VoteCountOnlyGroupRepository extends _EmptyGroupRepository {
  @override
  Future<VoteCard> fetchVoteCard({
    required Object groupId,
    required Object voteId,
  }) async {
    return VoteCard(
      title: '응답 수만 있는 투표',
      summary: '목업 카페',
      statusLabel: 'open',
      actionLabel: '투표 보기',
      participantCount: 3,
      targetType: 'PLAN',
      targetId: '101',
      options: [
        VoteOptionSummary(
          id: 'vopt-501-1',
          label: '목업 카페',
          countLabel: '3표',
          progress: 1,
          candidateId: '9901',
          responseCount: 3,
        ),
      ],
    );
  }

  @override
  Future<Map<int, List<String>>> fetchVoteVoters({
    required Object groupId,
    required Object voteId,
  }) async {
    return const {};
  }
}

class _PlanBoardGroupRepository extends _EmptyGroupRepository {
  final fetchedVoteTargetTypes = <String?>[];
  final fetchedVoteTargetIds = <String?>[];

  @override
  Future<GroupSummary> fetchGroup(Object groupId) async {
    return const GroupSummary(
      id: 1,
      name: '온모임',
      description: '',
      members: [],
      lastMessage: '',
      unreadCount: 0,
      pinnedPlanTitle: '제주도 여행',
    );
  }

  @override
  Future<GroupPinnedPlan?> fetchPinnedPlan(Object groupId) async {
    return const GroupPinnedPlan(
      id: 101,
      title: '제주도 여행',
      dateLabel: '6월 7일',
      placeName: '제주',
      statusLabel: 'scheduled',
      voteSummary: '',
    );
  }

  @override
  Future<List<GroupPlanSummary>> fetchPlans(Object groupId) async {
    return const [
      GroupPlanSummary(
        id: 101,
        title: '제주도 여행',
        dateLabel: '6월 7일',
        placeName: '제주',
        statusLabel: 'scheduled',
        statusType: 'scheduled',
        memberCount: 4,
        extraMemberCount: 0,
        iconKind: 'travel',
        isPast: false,
      ),
      GroupPlanSummary(
        id: 103,
        title: '한강 피크닉',
        dateLabel: '6월 10일',
        placeName: '여의도 한강공원',
        statusLabel: 'scheduled',
        statusType: 'scheduled',
        memberCount: 4,
        extraMemberCount: 0,
        iconKind: 'park',
        isPast: false,
      ),
    ];
  }

  @override
  Future<List<VoteSummary>> fetchVotes(
    Object groupId, {
    String? targetType,
    Object? targetId,
  }) async {
    fetchedVoteTargetTypes.add(targetType);
    fetchedVoteTargetIds.add(targetId?.toString());
    if (targetType != 'PLAN' || targetId?.toString() != '103') {
      return const [];
    }
    return [
      VoteSummary(
        id: 703,
        title: '한강 피크닉 장소 투표',
        statusLabel: '진행 중',
        description: '장소 후보 투표',
        planLabel: '한강 피크닉',
        planMeta: '6월 10일 · 여의도 한강공원',
        participants: const ['민서', '지훈', '하린', '현우'],
        participantCount: 4,
        options: [
          VoteOptionSummary(
            label: '투표에 없는 식당',
            countLabel: '4표',
            progress: 0.8,
            candidateId: '9902',
            responseCount: 4,
          ),
          VoteOptionSummary(
            label: '목업 카페',
            countLabel: '1표',
            progress: 0.2,
            candidateId: '9901',
            responseCount: 1,
          ),
        ],
        closed: false,
        joinedByMe: true,
        actionLabel: '투표 확인하기',
        targetType: 'PLAN',
        targetId: '103',
      ),
    ];
  }
}

class _PlanBoardMismatchedVoteRepository extends _PlanBoardGroupRepository {
  @override
  Future<List<VoteSummary>> fetchVotes(
    Object groupId, {
    String? targetType,
    Object? targetId,
  }) async {
    fetchedVoteTargetTypes.add(targetType);
    fetchedVoteTargetIds.add(targetId?.toString());
    return [
      VoteSummary(
        id: 501,
        title: '제주도 여행 장소 투표',
        statusLabel: '진행 중',
        description: '다른 약속 투표',
        planLabel: '제주도 여행',
        planMeta: '6월 7일 · 제주',
        participants: const ['민서'],
        participantCount: 1,
        options: [
          VoteOptionSummary(
            label: '목업 카페',
            countLabel: '1표',
            progress: 1,
            candidateId: '9901',
            responseCount: 1,
          ),
        ],
        closed: false,
        joinedByMe: true,
        actionLabel: '투표 확인하기',
        targetType: 'PLAN',
        targetId: '101',
      ),
    ];
  }
}

class _MismatchedVoteGroupRepository extends _EmptyGroupRepository {
  @override
  Future<VoteCard> fetchVoteCard({
    required Object groupId,
    required Object voteId,
  }) async {
    return VoteCard(
      title: '제주도 여행 장소 투표',
      summary: '목업 카페 후보를 비교 중이에요.',
      statusLabel: 'open',
      actionLabel: '투표 보기',
      participantCount: 1,
      targetType: 'PLAN',
      targetId: '101',
      options: [
        VoteOptionSummary(
          label: '목업 카페',
          countLabel: '1표',
          progress: 1,
          candidateId: '9901',
          responseCount: 1,
        ),
      ],
    );
  }

  @override
  Future<Map<int, List<String>>> fetchVoteVoters({
    required Object groupId,
    required Object voteId,
  }) async {
    return const {};
  }
}

class _FakePlaceRepository implements PlaceRepository {
  static final _candidate = PlaceCandidate(
    id: 9901,
    name: '목업 카페',
    category: '카페',
    summary: 'repository 테스트 후보',
    score: 90,
    matchPercent: 86,
    distanceLabel: '도보 3분',
    travelTimeLabel: '도보 3분',
    priceLabel: '1인 10,000원대',
    isOpen: true,
    address: '서울시 테스트구',
    openingLabel: '오늘 10:00-20:00',
    sourceLabel: 'Test API',
    riskLabel: '안정',
    riskTone: 'none',
    memberFits: [],
    tags: ['조용한'],
    reasons: ['테스트하기 좋아요.'],
    risks: ['운영 리스크 없음'],
  );

  @override
  Future<List<PlaceCandidate>> fetchCandidates({
    required Object groupId,
    required Object planId,
  }) async => [_candidate];

  @override
  Future<PlaceCandidate> fetchCandidate({
    required Object groupId,
    required Object planId,
    required Object candidateId,
  }) async => _candidate;

  @override
  Future<PlaceCandidate> createCandidate({
    required Object groupId,
    required Object planId,
    required PlaceCandidate candidate,
  }) async => candidate;

  @override
  Future<SchedulePlace> createSchedulePlace({
    required Object groupId,
    required Object planId,
    required Object candidateId,
    required String name,
    DateTime? startsAt,
    DateTime? endsAt,
    String note = '',
  }) async => SchedulePlace(
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

  @override
  Future<SchedulePlace> updateSchedulePlace({
    required Object groupId,
    required Object planId,
    required Object schedulePlaceId,
    DateTime? startsAt,
    DateTime? endsAt,
    String note = '',
  }) async => SchedulePlace(
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

  @override
  Future<PlaceCandidate> setCandidateHeart({
    required Object groupId,
    required Object planId,
    required Object candidateId,
    required bool hearted,
  }) async =>
      _candidate.copyWith(heartedByMe: hearted, heartCount: hearted ? 1 : 0);

  @override
  Future<void> deleteSchedulePlace({
    required Object groupId,
    required Object planId,
    required Object schedulePlaceId,
  }) async {}

  @override
  Future<List<PlaceCandidate>> searchPlaces({
    required Object groupId,
    required Object planId,
    required String query,
    String? category,
    double? lat,
    double? lng,
    int? radius,
  }) async => [_candidate];

  @override
  Future<List<PlaceRisk>> fetchRisks({
    required Object groupId,
    required Object planId,
  }) async => [];

  @override
  Future<PlaceVoteResult> fetchVoteResult({
    required Object groupId,
    required Object planId,
  }) async => PlaceVoteResult(
    title: '테스트 투표',
    selectedPlaceName: '목업 카페',
    voters: ['지우'],
    note: '테스트 결과',
  );
}

class _MultiCandidatePlaceRepository extends _FakePlaceRepository {
  static final _otherCandidate = PlaceCandidate(
    id: 9902,
    name: '투표에 없는 식당',
    category: '한식',
    summary: '투표 옵션에 포함되지 않은 후보',
    score: 72,
    matchPercent: 61,
    distanceLabel: '도보 8분',
    travelTimeLabel: '도보 8분',
    priceLabel: '1인 12,000원대',
    isOpen: true,
    address: '서울시 테스트구',
    openingLabel: '오늘 11:00-21:00',
    sourceLabel: 'Test API',
    riskLabel: '안정',
    riskTone: 'none',
    memberFits: [],
    tags: ['식사'],
    reasons: ['근처에 있어요.'],
    risks: ['운영 리스크 없음'],
  );

  @override
  Future<List<PlaceCandidate>> fetchCandidates({
    required Object groupId,
    required Object planId,
  }) async => [_FakePlaceRepository._candidate, _otherCandidate];
}

class _NoPlaceCandidatesRepository extends _FakePlaceRepository {
  @override
  Future<List<PlaceCandidate>> fetchCandidates({
    required Object groupId,
    required Object planId,
  }) async => const [];
}

class _PlanBoardPlaceRepository extends _FakePlaceRepository {
  @override
  Future<List<PlaceCandidate>> fetchCandidates({
    required Object groupId,
    required Object planId,
  }) async {
    return [
      _MultiCandidatePlaceRepository._otherCandidate,
      _FakePlaceRepository._candidate,
    ];
  }
}

class _PlanScopedPlaceRepository extends _FakePlaceRepository {
  final fetchedPlanIds = <String>[];

  @override
  Future<List<PlaceCandidate>> fetchCandidates({
    required Object groupId,
    required Object planId,
  }) async {
    fetchedPlanIds.add(planId.toString());
    if (planId.toString() == '101') {
      return [_FakePlaceRepository._candidate];
    }
    return [_MultiCandidatePlaceRepository._otherCandidate];
  }
}

class _FakePlanRepository implements PlanRepository {
  static const _plan = Plan(
    id: 101,
    title: '테스트 약속',
    dateTime: '일정 미정',
    location: '서울시 테스트구',
    status: 'scheduled',
    memo: '',
    members: [],
    timeCandidates: [],
    visitPlan: [],
  );

  @override
  Future<Plan> fetchPlan({
    required Object groupId,
    required Object planId,
  }) async {
    return _plan;
  }

  @override
  Future<Plan> createPlan(PlanCreateInput input) {
    throw UnimplementedError();
  }

  @override
  Future<Plan> updatePlan({
    required Object planId,
    required PlanCreateInput input,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<List<VisitPlan>>> fetchVisitPlansByDate({
    required Object groupId,
    required Object planId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<PlanParticipantArrival>> fetchPlanParticipants({
    required Object groupId,
    required Object planId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<PlanParticipantArrival> updateMyArrivalStatus({
    required Object groupId,
    required Object planId,
    required PlanArrivalStatus status,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<PlanParticipantArrival> leaveAsCurrentUser({
    required Object groupId,
    required Object planId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<PlanParticipantArrival> addParticipant({
    required Object groupId,
    required Object planId,
    required String userId,
  }) {
    throw UnimplementedError();
  }
}

class _PlanMemberProfileImageMergeRepository implements PlanRepository {
  @override
  Future<Plan> fetchPlan({
    required Object groupId,
    required Object planId,
  }) async {
    return const Plan(
      id: 101,
      title: '프로필 이미지 보강 약속',
      dateTime: '일정 미정',
      location: '수원',
      status: 'scheduled',
      memo: '',
      members: [PlanMember(userId: 'user-jinhee', name: '박진희', selected: true)],
      timeCandidates: [],
      visitPlan: [],
    );
  }

  @override
  Future<List<PlanParticipantArrival>> fetchPlanParticipants({
    required Object groupId,
    required Object planId,
  }) async {
    return const [
      PlanParticipantArrival(
        id: 'participant-jinhee',
        userId: 'user-jinhee',
        nickname: '박진희',
        participantStatus: 'joined',
        arrivalStatus: PlanArrivalStatus.none,
        isFallback: false,
        profileImageUrl: 'https://cdn.onmu.test/jinhee.png',
      ),
    ];
  }

  @override
  Future<List<List<VisitPlan>>> fetchVisitPlansByDate({
    required Object groupId,
    required Object planId,
  }) async {
    return const [];
  }

  @override
  Future<Plan> createPlan(PlanCreateInput input) {
    throw UnimplementedError();
  }

  @override
  Future<Plan> updatePlan({
    required Object planId,
    required PlanCreateInput input,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<PlanParticipantArrival> updateMyArrivalStatus({
    required Object groupId,
    required Object planId,
    required PlanArrivalStatus status,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<PlanParticipantArrival> leaveAsCurrentUser({
    required Object groupId,
    required Object planId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<PlanParticipantArrival> addParticipant({
    required Object groupId,
    required Object planId,
    required String userId,
  }) {
    throw UnimplementedError();
  }
}

class _LongRangePlanRepository implements PlanRepository {
  @override
  Future<Plan> fetchPlan({
    required Object groupId,
    required Object planId,
  }) async {
    return Plan(
      id: int.parse(planId.toString()),
      title: '샘플약속-진희',
      dateTime: '6/19 금',
      location: '수원',
      status: 'scheduled',
      memo: '',
      members: const [],
      timeCandidates: const [],
      visitPlan: const [],
      startsAt: DateTime.parse('2026-06-19T14:00:00+09:00'),
      endsAt: DateTime.parse('2026-06-24T16:00:00+09:00'),
    );
  }

  @override
  Future<List<List<VisitPlan>>> fetchVisitPlansByDate({
    required Object groupId,
    required Object planId,
  }) async => [
    const [
      VisitPlan(
        time: '14:00',
        endTime: '',
        place: '퍼스트커피랩행궁',
        kind: '일정 장소',
        duration: '',
      ),
    ],
  ];

  @override
  Future<List<PlanParticipantArrival>> fetchPlanParticipants({
    required Object groupId,
    required Object planId,
  }) async => const [];

  @override
  Future<Plan> createPlan(PlanCreateInput input) {
    throw UnimplementedError();
  }

  @override
  Future<Plan> updatePlan({
    required Object planId,
    required PlanCreateInput input,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<PlanParticipantArrival> updateMyArrivalStatus({
    required Object groupId,
    required Object planId,
    required PlanArrivalStatus status,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<PlanParticipantArrival> leaveAsCurrentUser({
    required Object groupId,
    required Object planId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<PlanParticipantArrival> addParticipant({
    required Object groupId,
    required Object planId,
    required String userId,
  }) {
    throw UnimplementedError();
  }
}

class _PlanBoardPlanRepository extends _FakePlanRepository {
  @override
  Future<List<PlanParticipantArrival>> fetchPlanParticipants({
    required Object groupId,
    required Object planId,
  }) async {
    return const [
      PlanParticipantArrival(
        id: 'participant-1',
        nickname: '민서',
        participantStatus: 'joined',
        arrivalStatus: PlanArrivalStatus.none,
        isFallback: false,
      ),
      PlanParticipantArrival(
        id: 'participant-2',
        nickname: '지훈',
        participantStatus: 'joined',
        arrivalStatus: PlanArrivalStatus.none,
        isFallback: false,
      ),
      PlanParticipantArrival(
        id: 'participant-3',
        nickname: '하린',
        participantStatus: 'invited',
        arrivalStatus: PlanArrivalStatus.none,
        isFallback: false,
      ),
      PlanParticipantArrival(
        id: 'participant-4',
        nickname: '현우',
        participantStatus: 'left',
        arrivalStatus: PlanArrivalStatus.none,
        isFallback: false,
      ),
    ];
  }
}

class _FallbackParticipantRepository implements PlanRepository {
  static const _plan = Plan(
    id: 101,
    title: '참여자 없는 약속',
    dateTime: '일정 미정',
    location: '서울',
    status: 'scheduled',
    memo: '',
    members: [],
    timeCandidates: [],
    visitPlan: [],
  );

  @override
  Future<Plan> fetchPlan({
    required Object groupId,
    required Object planId,
  }) async {
    return _plan;
  }

  @override
  Future<Plan> createPlan(PlanCreateInput input) {
    throw UnimplementedError();
  }

  @override
  Future<Plan> updatePlan({
    required Object planId,
    required PlanCreateInput input,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<List<VisitPlan>>> fetchVisitPlansByDate({
    required Object groupId,
    required Object planId,
  }) async => const [];

  @override
  Future<List<PlanParticipantArrival>> fetchPlanParticipants({
    required Object groupId,
    required Object planId,
  }) async => const [
    PlanParticipantArrival(
      id: 'current-user',
      nickname: '나',
      participantStatus: 'joined',
      arrivalStatus: PlanArrivalStatus.none,
      isFallback: true,
    ),
  ];

  @override
  Future<PlanParticipantArrival> updateMyArrivalStatus({
    required Object groupId,
    required Object planId,
    required PlanArrivalStatus status,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<PlanParticipantArrival> leaveAsCurrentUser({
    required Object groupId,
    required Object planId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<PlanParticipantArrival> addParticipant({
    required Object groupId,
    required Object planId,
    required String userId,
  }) {
    throw UnimplementedError();
  }
}
