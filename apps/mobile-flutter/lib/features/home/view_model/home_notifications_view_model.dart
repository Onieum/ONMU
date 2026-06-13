import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/notification_models.dart';
import '../repository/notification_repository.dart';

final homeNotificationsViewModelProvider =
    AsyncNotifierProvider<HomeNotificationsViewModel, List<NotificationItem>>(
      HomeNotificationsViewModel.new,
    );

final notificationUnreadCountProvider =
    AsyncNotifierProvider<NotificationUnreadCountViewModel, int>(
      NotificationUnreadCountViewModel.new,
    );

class NotificationUnreadCountViewModel extends AsyncNotifier<int> {
  @override
  Future<int> build() async {
    final repository = ref.watch(notificationRepositoryProvider);
    return repository.fetchUnreadCount();
  }

  Future<void> refresh() async {
    final repository = ref.read(notificationRepositoryProvider);
    state = await AsyncValue.guard(repository.fetchUnreadCount);
  }
}

class HomeNotificationsViewModel extends AsyncNotifier<List<NotificationItem>> {
  @override
  Future<List<NotificationItem>> build() async {
    final repository = ref.watch(notificationRepositoryProvider);
    return repository.fetchNotifications(limit: 50);
  }

  Future<void> markRead(NotificationItem item) async {
    if (item.id.trim().isEmpty || item.isRead) {
      return;
    }
    final previous = state.value;
    if (previous == null) {
      return;
    }

    state = AsyncValue.data(_replaceItem(previous, item.id, item.markRead()));
    try {
      final repository = ref.read(notificationRepositoryProvider);
      final updated = await repository.markNotificationRead(item.id);
      state = AsyncValue.data(
        _replaceItem(state.value ?? previous, updated.id, updated),
      );
      ref.invalidate(notificationUnreadCountProvider);
    } catch (_) {
      state = AsyncValue.data(previous);
    }
  }

  Future<void> markAllRead() async {
    final previous = state.value;
    if (previous == null || previous.every((item) => item.isRead)) {
      return;
    }

    state = AsyncValue.data([
      for (final item in previous) item.isRead ? item : item.markRead(),
    ]);
    try {
      final repository = ref.read(notificationRepositoryProvider);
      await repository.markAllNotificationsRead();
      ref.invalidate(notificationUnreadCountProvider);
    } catch (_) {
      state = AsyncValue.data(previous);
    }
  }

  List<NotificationItem> _replaceItem(
    List<NotificationItem> items,
    String id,
    NotificationItem replacement,
  ) {
    return [for (final item in items) item.id == id ? replacement : item];
  }
}
