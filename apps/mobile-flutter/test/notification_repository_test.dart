import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/core/api/onmu_api_client.dart';
import 'package:onmu_mobile/core/theme/app_theme.dart';
import 'package:onmu_mobile/features/home/presentation/pages/home_notifications_page.dart';
import 'package:onmu_mobile/features/home/repository/notification_repository.dart';
import 'package:onmu_mobile/features/home/view_model/home_notifications_view_model.dart';
import 'package:onmu_mobile/shared/models/notification_models.dart';

void main() {
  test('API notification JSON을 NotificationItem으로 매핑한다', () async {
    final requestedPaths = <String>[];
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requestedPaths.add(options.path);
          handler.resolve(
            Response<Object?>(
              requestOptions: options,
              data: [
                {
                  'id': 'notification-1',
                  'type': 'settlement_created',
                  'notificationType': 'settlement_created',
                  'title': '정산이 생성됐어요',
                  'body': '한강 피크닉 정산을 확인해 주세요.',
                  'status': 'queued',
                  'readAt': null,
                  'createdAt': '2026-06-09T05:12:00Z',
                  'timeLabel': '14:12',
                  'groupId': '1',
                  'planId': '103',
                  'payload': {
                    'groupId': '1',
                    'planId': '103',
                    'settlementId': '301',
                  },
                  'isRead': false,
                },
              ],
            ),
          );
        },
      ),
    );

    final notifications = await ApiNotificationRepository(
      OnmuApiClient(dio),
    ).fetchNotifications(limit: 25);

    expect(requestedPaths.single, '/api/v1/notifications?limit=25');
    expect(notifications, hasLength(1));
    expect(notifications.single.id, 'notification-1');
    expect(notifications.single.notificationType, 'settlement_created');
    expect(notifications.single.title, '정산이 생성됐어요');
    expect(notifications.single.groupId, '1');
    expect(notifications.single.planId, '103');
    expect(notifications.single.payloadString('settlementId'), '301');
    expect(notifications.single.isRead, isFalse);
    expect(notifications.single.timeLabel, '14:12');
  });

  test('payload groupId와 planId를 fallback으로 사용한다', () {
    final notification = NotificationItem.fromJson({
      'id': 'notification-2',
      'notificationType': 'vote_created',
      'title': '투표가 열렸어요',
      'payload': {'groupId': '1', 'planId': '101', 'voteId': '501'},
    });

    expect(notification.groupId, '1');
    expect(notification.planId, '101');
    expect(notification.payloadString('voteId'), '501');
  });

  testWidgets('API 실패 시 알림 화면에 에러 상태가 보인다', (tester) async {
    final repository = _FailingNotificationRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HomeNotificationsPage(),
        ),
      ),
    );
    await tester.pump();
    await repository.called.future;
    await tester.pump();

    expect(find.text('알림을 불러오지 못했어요.'), findsOneWidget);
    expect(find.text('다시 불러오기'), findsOneWidget);
  });

  test('ViewModel이 repository 알림 목록을 노출한다', () async {
    final container = ProviderContainer(
      overrides: [
        notificationRepositoryProvider.overrideWithValue(
          const _StaticNotificationRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final notifications = await container.read(
      homeNotificationsViewModelProvider.future,
    );

    expect(notifications.single.title, '장소 후보가 추가됐어요');
  });
}

class _FailingNotificationRepository implements NotificationRepository {
  final called = Completer<void>();

  @override
  Future<List<NotificationItem>> fetchNotifications({int? limit}) async {
    if (!called.isCompleted) {
      called.complete();
    }
    throw Exception('network failed');
  }
}

class _StaticNotificationRepository implements NotificationRepository {
  const _StaticNotificationRepository();

  @override
  Future<List<NotificationItem>> fetchNotifications({int? limit}) async {
    return [
      NotificationItem(
        id: 'notification-1',
        notificationType: 'place_candidate_created',
        title: '장소 후보가 추가됐어요',
        body: '카페 오션뷰 후보가 제주도 여행에 추가됐습니다.',
        status: 'queued',
        createdAt: DateTime.parse('2026-06-09T14:10:00+09:00'),
        timeLabel: '14:10',
        groupId: '1',
        planId: '101',
        payload: const {'candidateId': '204'},
        isRead: false,
      ),
    ];
  }
}
