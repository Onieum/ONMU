import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/notification_models.dart';
import '../repository/notification_repository.dart';

final notificationPreferencesViewModelProvider =
    AsyncNotifierProvider<
      NotificationPreferencesViewModel,
      NotificationPreferences
    >(NotificationPreferencesViewModel.new);

class NotificationPreferencesViewModel
    extends AsyncNotifier<NotificationPreferences> {
  @override
  Future<NotificationPreferences> build() async {
    final repository = ref.watch(notificationRepositoryProvider);
    return repository.fetchPreferences();
  }

  Future<void> setEnabled({
    required String notificationType,
    required String channel,
    required bool enabled,
  }) async {
    final previous = state.value;
    if (previous == null) {
      return;
    }

    final optimistic = previous.replace(
      notificationType: notificationType,
      channel: channel,
      enabled: enabled,
    );
    state = AsyncValue.data(optimistic);
    try {
      final repository = ref.read(notificationRepositoryProvider);
      final saved = await repository.updatePreferences(optimistic.items);
      state = AsyncValue.data(saved);
    } catch (_) {
      state = AsyncValue.data(previous);
      rethrow;
    }
  }
}
