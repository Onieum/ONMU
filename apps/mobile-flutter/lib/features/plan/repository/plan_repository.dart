import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/plan_models.dart';

final planRepositoryProvider = Provider<PlanRepository>(
  (ref) => const MockPlanRepository(),
);

abstract interface class PlanRepository {
  Future<Plan> fetchPlan({required Object groupId, required Object planId});

  Future<List<List<VisitPlan>>> fetchVisitPlansByDate({
    required Object groupId,
    required Object planId,
  });
}

class MockPlanRepository implements PlanRepository {
  const MockPlanRepository();

  @override
  Future<Plan> fetchPlan({
    required Object groupId,
    required Object planId,
  }) async {
    final parsedPlanId = int.tryParse(planId.toString()) ?? mockPlanDetail.id;

    return Plan(
      id: parsedPlanId,
      title: '제주도 여행',
      dateTime: '6.7(토) - 6.9(월)',
      location: '제주도 일대',
      status: '이행 전',
      memo: mockPlanDetail.memo,
      members: mockPlanMembers,
      timeCandidates: mockPlanTimeCandidates,
      visitPlan: mockPlanDetail.visitPlan,
    );
  }

  @override
  Future<List<List<VisitPlan>>> fetchVisitPlansByDate({
    required Object groupId,
    required Object planId,
  }) async {
    return [
      List.unmodifiable(mockPlanDetail.visitPlan),
      const [
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
      ],
      const [
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
      ],
    ].map(List<VisitPlan>.unmodifiable).toList(growable: false);
  }
}
