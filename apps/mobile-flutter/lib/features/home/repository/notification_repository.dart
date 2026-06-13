import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/onmu_api_client.dart';
import '../../../shared/models/notification_models.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return ApiNotificationRepository(ref.watch(onmuApiClientProvider));
});

abstract interface class NotificationRepository {
  Future<List<NotificationItem>> fetchNotifications({int? limit});

  Future<int> fetchUnreadCount();

  Future<NotificationItem> markNotificationRead(String notificationId);

  Future<int> markAllNotificationsRead();
}

class ApiNotificationRepository implements NotificationRepository {
  ApiNotificationRepository(this._client);

  final OnmuApiClient _client;

  @override
  Future<List<NotificationItem>> fetchNotifications({int? limit}) async {
    final queryParameters = <String, String>{};
    if (limit != null) {
      queryParameters['limit'] = limit.toString();
    }
    final path = Uri(
      path: '/api/v1/notifications',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    ).toString();
    final notifications = await _client.getList(path);
    return notifications.map(NotificationItem.fromJson).toList(growable: false);
  }

  @override
  Future<int> fetchUnreadCount() async {
    final response = await _client.getObject(
      '/api/v1/notifications/unread-count',
    );
    return OnmuJson.readInt(response, 'unreadCount');
  }

  @override
  Future<NotificationItem> markNotificationRead(String notificationId) async {
    final id = Uri.encodeComponent(notificationId.trim());
    final response = await _client.putObject('/api/v1/notifications/$id/read');
    return NotificationItem.fromJson(response);
  }

  @override
  Future<int> markAllNotificationsRead() async {
    final response = await _client.putObject('/api/v1/notifications/read-all');
    return OnmuJson.readInt(response, 'updatedCount');
  }
}
