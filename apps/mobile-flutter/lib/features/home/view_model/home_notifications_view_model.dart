import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/notification_models.dart';
import '../repository/notification_repository.dart';

final homeNotificationsViewModelProvider =
    AsyncNotifierProvider<HomeNotificationsViewModel, List<NotificationItem>>(
      HomeNotificationsViewModel.new,
    );

class HomeNotificationsViewModel extends AsyncNotifier<List<NotificationItem>> {
  @override
  Future<List<NotificationItem>> build() async {
    final repository = ref.watch(notificationRepositoryProvider);
    return repository.fetchNotifications(limit: 50);
  }
}
