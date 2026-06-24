import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/core/theme/app_theme.dart';
import 'package:onmu_mobile/features/place/presentation/pages/place_search_filter_page.dart';
import 'package:onmu_mobile/features/place/repository/place_repository.dart';
import 'package:onmu_mobile/shared/models/place_models.dart';
import 'package:onmu_mobile/shared/models/plan_models.dart';

void main() {
  testWidgets('장소 후보 찾기는 입력과 카테고리로 검색하고 후보에 담는다', (tester) async {
    final repository = _SearchPlaceRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [placeRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const PlaceSearchFilterPage(groupId: '1', planId: '101'),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '강남 맛집');
    await tester.pumpAndSettle();

    expect(repository.lastQuery, '강남 맛집');
    expect(find.text('강남 테스트 카페'), findsOneWidget);

    await tester.tap(find.text('카페').first);
    await tester.pumpAndSettle();

    expect(repository.lastCategory, '카페');

    await tester.tap(find.text('후보에 추가하기').first);
    await tester.pumpAndSettle();

    expect(repository.createdCandidateNames, ['강남 테스트 카페']);
    expect(find.text('장소 후보에 담았어요.'), findsOneWidget);
  });
}

class _SearchPlaceRepository implements PlaceRepository {
  String lastQuery = '';
  String? lastCategory;
  final createdCandidateNames = <String>[];

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
    lastQuery = query;
    lastCategory = category;
    return [_candidate.copyWith(category: category ?? '카페')];
  }

  @override
  Future<PlaceCandidate> createCandidate({
    required Object groupId,
    required Object planId,
    required PlaceCandidate candidate,
  }) async {
    createdCandidateNames.add(candidate.name);
    return candidate;
  }

  @override
  Future<List<PlaceCandidate>> fetchCandidates({
    required Object groupId,
    required Object planId,
  }) async => const [];

  @override
  Future<PlaceCandidate> fetchCandidate({
    required Object groupId,
    required Object planId,
    required Object candidateId,
  }) async => _candidate;

  @override
  Future<PlaceCandidate> setCandidateHeart({
    required Object groupId,
    required Object planId,
    required Object candidateId,
    required bool hearted,
  }) async => _candidate.copyWith(heartedByMe: hearted);

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
  Future<void> deleteSchedulePlace({
    required Object groupId,
    required Object planId,
    required Object schedulePlaceId,
  }) async {}

  @override
  Future<List<PlaceRisk>> fetchRisks({
    required Object groupId,
    required Object planId,
  }) async => const [];

  @override
  Future<PlaceVoteResult> fetchVoteResult({
    required Object groupId,
    required Object planId,
  }) async => const PlaceVoteResult(
    title: '투표',
    selectedPlaceName: '',
    voters: [],
    note: '',
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
    candidateId: '201',
    name: '수정 장소',
    startsAt: startsAt,
    endsAt: endsAt,
    note: note,
    sortOrder: 1,
  );
}

const _candidate = PlaceCandidate(
  id: 201,
  name: '강남 테스트 카페',
  category: '카페',
  summary: '모임 전 대화하기 좋은 곳',
  score: 0,
  matchPercent: 0,
  distanceLabel: '약 300m',
  travelTimeLabel: '도보 5분',
  priceLabel: '',
  isOpen: true,
  address: '서울 강남구 테스트로 1',
  openingLabel: '',
  sourceLabel: '',
  riskLabel: '',
  riskTone: 'none',
  memberFits: [],
  tags: ['카페'],
  reasons: ['대화하기 좋아요'],
  risks: [],
);
