import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/core/api/onmu_api_client.dart';
import 'package:onmu_mobile/features/plan/repository/plan_repository.dart';
import 'package:onmu_mobile/shared/models/plan_models.dart';

void main() {
  test('maps schedule places into itinerary visit plans', () async {
    final requests = <RequestOptions>[];
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          handler.resolve(
            Response<Object?>(
              requestOptions: options,
              data: [
                {
                  'id': '701',
                  'name': '성수 테스트 카페',
                  'startsAt': '2026-06-12T02:00:00Z',
                  'endsAt': '2026-06-12T03:00:00Z',
                  'note': '점심',
                  'sortOrder': 1,
                },
              ],
            ),
          );
        },
      ),
    );
    final repository = ApiPlanRepository(OnmuApiClient(dio));

    final visitPlansByDate = await repository.fetchVisitPlansByDate(
      groupId: 1,
      planId: 101,
    );

    expect(requests.single.path, '/api/v1/groups/1/plans/101/schedule-places');
    expect(visitPlansByDate, hasLength(1));
    expect(visitPlansByDate.single.single.place, '성수 테스트 카페');
    expect(visitPlansByDate.single.single.kind, '일정 장소');
    expect(visitPlansByDate.single.single.duration, '점심');
  });

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

  test(
    'removes only my plan participation through participant me endpoint',
    () async {
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
                  'userId': 'user-me',
                  'displayName': '나',
                  'status': 'left',
                  'response': 'accepted',
                },
              ),
            );
          },
        ),
      );
      final repository = ApiPlanRepository(OnmuApiClient(dio));

      final participant = await repository.leaveAsCurrentUser(
        groupId: 1,
        planId: 101,
      );

      expect(
        requests.single.path,
        '/api/v1/groups/1/plans/101/participants/me',
      );
      expect(requests.single.method, 'PATCH');
      expect(requests.single.data, {'status': 'left'});
      expect(participant.userId, 'user-me');
      expect(participant.participantStatus, 'left');
    },
  );

  test('maps participant arrival responses from API', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response<Object?>(
              requestOptions: options,
              data: [
                {
                  'userId': 'user-jiwoo',
                  'displayName': '지우',
                  'response': 'arrived',
                },
                {
                  'userId': 'user-minsu',
                  'displayName': '민수',
                  'response': 'late',
                },
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
    expect(participants.map((item) => item.userId), [
      'user-jiwoo',
      'user-minsu',
    ]);
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
                'memo': '메모',
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
        endsAt: '2026-06-12T12:00:00Z',
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
      'endsAt': '2026-06-12T12:00:00.000Z',
      'placeName': '성수동',
      'memo': '메모',
      'status': 'draft',
    });
    expect(plan.title, '수정된 약속');
    expect(plan.location, '성수동');
    expect(plan.memo, '메모');
  });

  test(
    'createPlan sends selected participant user ids through Spring API',
    () async {
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
                  'title': '참여자 포함 약속',
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

      await repository.createPlan(
        PlanCreateInput(
          groupId: 1,
          title: '참여자 포함 약속',
          dateTime: '2026-06-12T10:00:00Z',
          endsAt: '2026-06-12T12:00:00Z',
          location: '성수동',
          memo: '',
          members: const [
            PlanMember(name: '나', userId: 'user-me'),
            PlanMember(name: '지민', userId: 'user-jimin'),
            PlanMember(name: '이름만 있는 멤버'),
          ],
        ),
      );

      expect(requests.single.path, '/api/v1/groups/1/plans');
      expect(requests.single.method, 'POST');
      expect(requests.single.data['participantUserIds'], [
        'user-me',
        'user-jimin',
      ]);
    },
  );

  test('adds a group member to plan through participant endpoint', () async {
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
                'id': 'participant-jimin',
                'userId': 'user-jimin',
                'displayName': '지민',
                'status': 'joined',
                'response': 'accepted',
                'profileImageUrl': 'dev/avatars/jimin.png',
              },
            ),
          );
        },
      ),
    );
    final repository = ApiPlanRepository(OnmuApiClient(dio));

    final participant = await repository.addParticipant(
      groupId: 1,
      planId: 101,
      userId: 'user-jimin',
    );

    expect(requests.single.path, '/api/v1/groups/1/plans/101/participants');
    expect(requests.single.method, 'POST');
    expect(requests.single.data, {'userId': 'user-jimin'});
    expect(participant.userId, 'user-jimin');
    expect(participant.displayName, '지민');
    expect(participant.participantStatus, 'joined');
    expect(participant.profileImageUrl, 'dev/avatars/jimin.png');
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
