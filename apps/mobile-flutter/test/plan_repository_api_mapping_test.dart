import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/core/api/onmu_api_client.dart';
import 'package:onmu_mobile/features/plan/repository/plan_repository.dart';
import 'package:onmu_mobile/shared/models/plan_models.dart';

void main() {
  test('updates my plan arrival status through participant response', () async {
    final requests = <RequestOptions>[];
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          handler.resolve(
            Response<Object?>(
              requestOptions: options,
              data: {
                'id': 'participant-1',
                'displayName': '지우',
                'status': 'joined',
                'response': 'departed',
              },
            ),
          );
        },
      ),
    );
    final repository = ApiPlanRepository(OnmuApiClient(dio));

    final participant = await repository.updateMyArrivalStatus(
      groupId: 1,
      planId: 101,
      status: PlanArrivalStatus.departed,
    );

    expect(requests.single.path, '/api/v1/groups/1/plans/101/participants/me');
    expect(requests.single.method, 'PATCH');
    expect(requests.single.data, {'status': 'joined', 'response': 'departed'});
    expect(participant.arrivalStatus, PlanArrivalStatus.departed);
    expect(participant.arrivalStatus.label, '출발');
  });

  test('maps participant arrival responses from API', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response<Object?>(
              requestOptions: options,
              data: [
                {'displayName': '지우', 'response': 'arrived'},
                {'displayName': '민수', 'response': 'late'},
              ],
            ),
          );
        },
      ),
    );
    final repository = ApiPlanRepository(OnmuApiClient(dio));

    final participants = await repository.fetchPlanParticipants(
      groupId: 1,
      planId: 101,
    );

    expect(participants.map((item) => item.arrivalStatus.label), ['도착', '지각']);
  });

  test('updates plan through Spring API', () async {
    final requests = <RequestOptions>[];
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          handler.resolve(
            Response<Object?>(
              requestOptions: options,
              data: {
                'id': 101,
                'title': '수정된 약속',
                'dateLabel': '2026-06-12T10:00:00Z',
                'placeName': '성수동',
                'status': 'draft',
              },
            ),
          );
        },
      ),
    );
    final repository = ApiPlanRepository(OnmuApiClient(dio));

    final plan = await repository.updatePlan(
      planId: 101,
      input: PlanCreateInput(
        groupId: 1,
        title: '수정된 약속',
        dateTime: '2026-06-12T10:00:00Z',
        location: '성수동',
        memo: '메모',
        members: const [],
      ),
    );

    expect(requests.single.path, '/api/v1/groups/1/plans/101');
    expect(requests.single.method, 'PATCH');
    expect(requests.single.data, {
      'title': '수정된 약속',
      'startsAt': '2026-06-12T10:00:00.000Z',
      'status': 'draft',
    });
    expect(plan.title, '수정된 약속');
    expect(plan.location, '성수동');
  });

  test(
    'maps plan start and end time for active arrival status window',
    () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response<Object?>(
                requestOptions: options,
                data: {
                  'id': 101,
                  'title': '진행 중인 약속',
                  'dateLabel': '오늘 10:00',
                  'placeName': '성수동',
                  'status': 'in_progress',
                  'startsAt': '2026-06-10T10:00:00+09:00',
                  'endsAt': '2026-06-10T12:00:00+09:00',
                },
              ),
            );
          },
        ),
      );
      final repository = ApiPlanRepository(OnmuApiClient(dio));

      final plan = await repository.fetchPlan(groupId: 1, planId: 101);

      expect(plan.startsAt, DateTime.parse('2026-06-10T10:00:00+09:00'));
      expect(plan.endsAt, DateTime.parse('2026-06-10T12:00:00+09:00'));
      expect(
        plan.isInProgressAt(DateTime.parse('2026-06-10T11:00:00+09:00')),
        isTrue,
      );
      expect(
        plan.isInProgressAt(DateTime.parse('2026-06-10T12:00:00+09:00')),
        isFalse,
      );
    },
  );
}
