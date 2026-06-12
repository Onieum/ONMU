import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/onmu_api_client.dart';
import '../../../shared/models/notification_models.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return ApiNotificationRepository(ref.watch(onmuApiClientProvider));
});

abstract interface class NotificationRepository {
  Future<List<NotificationItem>> fetchNotifications({int? limit});
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
}
