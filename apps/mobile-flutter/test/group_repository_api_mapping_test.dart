import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/core/api/onmu_api_client.dart';
import 'package:onmu_mobile/features/group/repository/group_repository.dart';
import 'package:onmu_mobile/shared/models/group_models.dart';

void main() {
  test(
    'does not synthesize Spring API copy for missing group fields',
    () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response<Object?>(
                requestOptions: options,
                data: [
                  {'id': 4, 'name': '대학 동기 여행단'},
                ],
              ),
            );
          },
        ),
      );
      final repository = ApiGroupRepository(OnmuApiClient(dio));

      final groups = await repository.fetchGroups();

      expect(groups.single.description, isEmpty);
      expect(groups.single.lastMessage, isEmpty);
      expect(groups.single.members, isEmpty);
    },
  );

  test('plan status API enum values are displayed in Korean', () {
    expect(PlanProgressStatus.fromApi('completed').label, '완료');
    expect(PlanProgressStatus.fromApi('draft').label, '초안');
    expect(PlanProgressStatus.fromApi('active').label, '진행 중');
    expect(PlanProgressStatus.fromApi('scheduled').label, '예정');
    expect(PlanProgressStatus.fromApi('진행중').label, '진행 중');
  });

  test('group plan summary exposes centralized Korean display status', () {
    final plan = GroupPlanSummary(
      id: 1,
      title: '한강 피크닉',
      dateLabel: '6월 12일',
      placeName: '한강',
      statusLabel: 'completed',
      statusType: 'completed',
      memberCount: 2,
      extraMemberCount: 0,
      iconKind: 'default',
      isPast: true,
    );

    expect(plan.progressStatus, PlanProgressStatus.completed);
    expect(plan.displayStatusLabel, '완료');
  });

  test('group plan summary display date includes time from startsAt', () {
    final plan = GroupPlanSummary(
      id: 1,
      title: '한강 피크닉',
      dateLabel: '5월 10일',
      startsAt: DateTime(2026, 5, 10, 13, 30),
      placeName: '한강',
      statusLabel: 'completed',
      statusType: 'completed',
      memberCount: 2,
      extraMemberCount: 0,
      iconKind: 'default',
      isPast: true,
    );

    expect(plan.displayDateTimeLabel, '5월 10일 13:30');
  });
}
