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
    expect(
      notifications.single.timeLabel,
      _localTimeLabel('2026-06-09T05:12:00Z'),
    );
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

  test('API notification 읽음 처리 endpoint를 호출한다', () async {
    final requested = <String>[];
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requested.add('${options.method} ${options.path}');
          final data = switch ('${options.method} ${options.path}') {
            'GET /api/v1/notifications/unread-count' => {'unreadCount': 2},
            'PUT /api/v1/notifications/notification-1/read' => {
              'id': 'notification-1',
              'notificationType': 'chat_message',
              'title': '새 메시지가 있어요',
              'body': '채팅을 확인해 주세요.',
              'status': 'read',
              'readAt': '2026-06-09T05:14:00Z',
              'createdAt': '2026-06-09T05:12:00Z',
              'timeLabel': '14:12',
              'groupId': '1',
              'payload': {'groupId': '1', 'messageId': 'message-1'},
              'isRead': true,
            },
            'PUT /api/v1/notifications/read-all' => {'updatedCount': 2},
            _ => <String, Object?>{},
          };
          handler.resolve(
            Response<Object?>(requestOptions: options, data: data),
          );
        },
      ),
    );
    final repository = ApiNotificationRepository(OnmuApiClient(dio));

    final unreadCount = await repository.fetchUnreadCount();
    final updated = await repository.markNotificationRead('notification-1');
    final readAllCount = await repository.markAllNotificationsRead();

    expect(unreadCount, 2);
    expect(updated.isRead, isTrue);
    expect(updated.status, 'read');
    expect(readAllCount, 2);
    expect(requested, [
      'GET /api/v1/notifications/unread-count',
      'PUT /api/v1/notifications/notification-1/read',
      'PUT /api/v1/notifications/read-all',
    ]);
  });

  test('API notification preferences endpoint를 호출한다', () async {
    final requested = <String>[];
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requested.add('${options.method} ${options.path}');
          handler.resolve(
            Response<Object?>(
              requestOptions: options,
              data: {
                'preferences': [
                  {
                    'notificationType': 'chat_message',
                    'channel': 'in_app',
                    'enabled': false,
                    'quietHours': {'start': '22:00'},
                  },
                ],
              },
            ),
          );
        },
      ),
    );
    final repository = ApiNotificationRepository(OnmuApiClient(dio));

    final fetched = await repository.fetchPreferences();
    final saved = await repository.updatePreferences(fetched.items);

    expect(fetched.enabledFor('chat_message', 'in_app'), isFalse);
    expect(saved.items.single.quietHours, containsPair('start', '22:00'));
    expect(requested, [
      'GET /api/v1/notification-preferences',
      'PUT /api/v1/notification-preferences',
    ]);
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

  test('ViewModel이 단건 알림 읽음 상태를 갱신한다', () async {
    final repository = _MutableNotificationRepository();
    final container = ProviderContainer(
      overrides: [notificationRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final notifications = await container.read(
      homeNotificationsViewModelProvider.future,
    );

    await container
        .read(homeNotificationsViewModelProvider.notifier)
        .markRead(notifications.single);

    final state = container.read(homeNotificationsViewModelProvider);
    expect(repository.markedNotificationId, 'notification-1');
    expect(state.value?.single.isRead, isTrue);
    expect(state.value?.single.status, 'read');
  });

  test('ViewModel이 전체 알림 읽음 상태를 갱신한다', () async {
    final repository = _MutableNotificationRepository();
    final container = ProviderContainer(
      overrides: [notificationRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    await container.read(homeNotificationsViewModelProvider.future);

    await container
        .read(homeNotificationsViewModelProvider.notifier)
        .markAllRead();

    final state = container.read(homeNotificationsViewModelProvider);
    expect(repository.markAllCalled, isTrue);
    expect(state.value?.every((notification) => notification.isRead), isTrue);
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

  @override
  Future<int> fetchUnreadCount() async => 0;

  @override
  Future<int> markAllNotificationsRead() async => 0;

  @override
  Future<NotificationItem> markNotificationRead(String notificationId) async {
    throw Exception('network failed');
  }

  @override
  Future<NotificationPreferences> fetchPreferences() async {
    throw Exception('network failed');
  }

  @override
  Future<NotificationPreferences> updatePreferences(
    List<NotificationPreferenceItem> preferences,
  ) async {
    throw Exception('network failed');
  }
}

String _localTimeLabel(String value) {
  final local = DateTime.parse(value).toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
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

  @override
  Future<int> fetchUnreadCount() async => 1;

  @override
  Future<int> markAllNotificationsRead() async => 1;

  @override
  Future<NotificationItem> markNotificationRead(String notificationId) async {
    return (await fetchNotifications()).single.markRead();
  }

  @override
  Future<NotificationPreferences> fetchPreferences() async {
    return const NotificationPreferences(
      items: [
        NotificationPreferenceItem(
          notificationType: 'chat_message',
          channel: 'in_app',
          enabled: true,
        ),
      ],
    );
  }

  @override
  Future<NotificationPreferences> updatePreferences(
    List<NotificationPreferenceItem> preferences,
  ) async {
    return NotificationPreferences(items: preferences);
  }
}

class _MutableNotificationRepository implements NotificationRepository {
  String? markedNotificationId;
  bool markAllCalled = false;

  var _notifications = [
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

  @override
  Future<List<NotificationItem>> fetchNotifications({int? limit}) async {
    return List.unmodifiable(
      _notifications.take(limit ?? _notifications.length),
    );
  }

  @override
  Future<int> fetchUnreadCount() async {
    return _notifications.where((notification) => !notification.isRead).length;
  }

  @override
  Future<int> markAllNotificationsRead() async {
    markAllCalled = true;
    _notifications = [
      for (final notification in _notifications) notification.markRead(),
    ];
    return _notifications.length;
  }

  @override
  Future<NotificationItem> markNotificationRead(String notificationId) async {
    markedNotificationId = notificationId;
    final index = _notifications.indexWhere(
      (notification) => notification.id == notificationId,
    );
    final updated = _notifications[index].markRead();
    _notifications[index] = updated;
    return updated;
  }

  @override
  Future<NotificationPreferences> fetchPreferences() async {
    return const NotificationPreferences(
      items: [
        NotificationPreferenceItem(
          notificationType: 'chat_message',
          channel: 'in_app',
          enabled: true,
        ),
      ],
    );
  }

  @override
  Future<NotificationPreferences> updatePreferences(
    List<NotificationPreferenceItem> preferences,
  ) async {
    return NotificationPreferences(items: preferences);
  }
}
